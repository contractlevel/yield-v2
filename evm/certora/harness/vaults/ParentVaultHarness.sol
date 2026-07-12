// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVault} from "../../../src/vaults/ParentVault.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {BaseVaultStrategyLib} from "../../../src/libraries/vaults/BaseVaultStrategyLib.sol";
import {Types} from "../../../src/libraries/Types.sol";
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
        _storeRebalanceDepositRecovery(rebalanceNonce, amount);
    }

    function clearRebalanceDepositRecovery() external {
        _clearRebalanceDepositRecovery();
    }

    function requireRebalanceDepositRecovery()
        external
        view
        returns (Types.RebalanceDepositRecovery memory recovery)
    {
        recovery = _requireRebalanceDepositRecovery();
    }

    function recoverFailedRebalanceDepositInternal() external returns (uint256 rebalanceNonce, uint256 amount) {
        (rebalanceNonce, amount) = _recoverFailedRebalanceDeposit();
    }

    function executeDeposit(uint256 amount, bool revertOnFailure) external returns (bool success) {
        success = _executeDeposit(amount, revertOnFailure);
    }

    function executeWithdraw(uint256 amount, bool revertOnFailure) external returns (bool success, uint256 amountOut) {
        (success, amountOut) = _executeWithdraw(amount, revertOnFailure);
    }

    function handleCCIPRebalance(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        external
        returns (bool success)
    {
        /// @dev Certora cannot link external libraries, so model only the active-adapter boundary here.
        BaseVaultStrategyLib._setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
        success = _handleCCIPRebalanceDeposit(rebalanceNonce, amount);
    }

    /// @dev Certora cannot link external libraries, so model only the active-adapter boundary here.
    ///      Production ParentVault.sol must go through the public library call (delegatecall) because
    ///      Parent is near the contract size limit and can't inline this like ChildVault does.
    function _setActiveAdapter(bytes32 protocolId) internal override returns (address adapter) {
        adapter = BaseVaultStrategyLib._setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    function requireNoRecovery() external view {
        _requireNoRecovery();
    }

    function requireRecoveryMode(Types.RecoveryMode expected) external view {
        _requireRecoveryMode(expected);
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

    function getRecoveryCreatedAt() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.createdAt;
    }

    function policyProtectedInterfaceId() external pure returns (bytes4) {
        return type(IPolicyProtected).interfaceId;
    }
}
