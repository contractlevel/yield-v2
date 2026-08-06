// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVault} from "../../../src/vaults/ParentVault.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {BaseVaultStrategyLib} from "../../../src/libraries/vaults/BaseVaultStrategyLib.sol";
import {BaseVaultCcipLib} from "../../../src/libraries/vaults/BaseVaultCcipLib.sol";
import {ParentVaultRebalanceLib} from "../../../src/libraries/vaults/ParentVaultRebalanceLib.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {Roles} from "../../../src/libraries/Roles.sol";
import {IPolicyProtected} from "@chainlink/policy-management/interfaces/IPolicyProtected.sol";

contract ParentVaultHarness is ParentVault, HelperHarness {
    bytes32 private constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    constructor(BaseVault.ConstructorParams memory params, address share) ParentVault(params, share) {}

    /// @dev Override _runPolicyBefore/_runPolicyAfter to avoid external policy engine calls.
    ///      PolicyProtected logic is verified separately in ParentVault-specific specs.
    function _runPolicyBefore() internal override {}
    function _runPolicyAfter() internal override {}

    function initializeBaseVault(BaseVault.InitParams memory params) external initializer {
        __BaseVault_init(params);
    }

    function isInitialized() external view returns (bool) {
        uint64 version;
        bytes32 slot = INITIALIZABLE_STORAGE;
        assembly {
            version := and(sload(slot), 0xFFFFFFFFFFFFFFFF)
        }
        return version > 0;
    }

    function isInitializing() external view returns (bool) {
        uint256 slotValue;
        bytes32 slot = INITIALIZABLE_STORAGE;
        assembly {
            slotValue := sload(slot)
        }
        return (slotValue >> 64) & 0xFF != 0;
    }

    function revertIfZeroAddress(address value) external pure {
        _revertIfZeroAddress(value);
    }

    function revertIfZeroAmount(uint256 value) external pure {
        _revertIfZeroAmount(value);
    }

    function revertIfZeroChainSelector(uint64 value) external pure {
        _revertIfZeroChainSelector(value);
    }

    function storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) external {
        _storeRebalanceDepositRecovery(_baseVaultStorage(), rebalanceNonce, amount);
    }

    function clearRebalanceDepositRecovery() external {
        uint256 rebalanceNonce = _baseVaultStorage().s_rebalanceDepositRecovery.rebalanceNonce;
        _clearRebalanceDepositRecovery(_baseVaultStorage(), rebalanceNonce);
    }

    function recoverFailedRebalanceDepositInternal() external returns (uint256 rebalanceNonce, uint256 amount) {
        (rebalanceNonce, amount) = _recoverFailedRebalanceDeposit(_baseVaultStorage());
    }

    function executeDeposit(uint256 amount, bool revertOnFailure) external returns (bool success) {
        success = _executeDeposit(amount, revertOnFailure, _baseVaultStorage().s_activeProtocolAdapter);
    }

    function executeWithdraw(uint256 amount, bool revertOnFailure) external returns (bool success, uint256 amountOut) {
        (success, amountOut) = _executeWithdraw(amount, revertOnFailure, _baseVaultStorage().s_activeProtocolAdapter);
    }

    function clearActiveAdapter(address adapter) external {
        _clearActiveAdapter(adapter);
    }

    function _clearActiveAdapter(address adapter) internal override {
        BaseVaultStrategyLib._clearActiveAdapter(_baseVaultStorage(), adapter);
    }

    /// @dev Certora cannot resolve the public library delegatecall from BaseVault._onlyAllowedSender.
    ///      Dispatch to the equivalent internal implementation without changing production behavior.
    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view override {
        BaseVaultCcipLib._onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    function handleCCIPRebalance(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        external
        returns (bool success)
    {
        /// @dev Dispatches through the _setActiveAdapter override below, which avoids the unresolved
        ///      external library call Certora cannot link.
        success = _handleCCIPRebalance(rebalanceNonce, protocolId, amount);
    }

    /// @dev Certora cannot link external libraries, so model only the active-adapter boundary here.
    ///      Production ParentVault.sol must go through the public library call (delegatecall) because
    ///      Parent is near the contract size limit and can't inline this like ChildVault does.
    function _setActiveAdapter(bytes32 protocolId) internal override returns (address adapter) {
        adapter = BaseVaultStrategyLib._setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    /// @dev Avoid unresolved public library calls while exercising the identical implementation.
    function _finalizeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal override {
        ParentVaultRebalanceLib._finalizeRebalance(
            _parentVaultStorage(), i_share, rebalanceNonce, newStrategy, false
        );
    }

    /// @dev Avoid unresolved public library calls while exercising the identical implementation.
    function _finalizeLocalToLocalRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        internal
        override
    {
        ParentVaultRebalanceLib._finalizeRebalance(
            _parentVaultStorage(), i_share, rebalanceNonce, newStrategy, true
        );
    }

    function requireNoRecovery() external view {
        _requireNoRecovery(_baseVaultStorage());
    }

    function authorizeUpgrade(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
    }

    function getRecoveryRebalanceNonce() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.rebalanceNonce;
    }

    function getRecoveryAmount() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.amount;
    }

    function policyProtectedInterfaceId() external pure returns (bytes4) {
        return type(IPolicyProtected).interfaceId;
    }

    function CANCEL_DEPOSIT_OPERATOR_ROLE() external pure returns (bytes32) {
        return Roles.CANCEL_DEPOSIT_OPERATOR_ROLE;
    }
}
