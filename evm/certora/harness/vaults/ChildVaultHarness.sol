// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ChildVaultHarness is ChildVault, HelperHarness {
    bytes32 private constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector)
        ChildVault(params, parentChainSelector)
    {}

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

    function clearCcipSendRecovery() external returns (Types.CcipSendRecovery memory recovery) {
        recovery = _clearCcipSendRecovery(_childVaultStorage(), _baseVaultStorage());
    }

    function ccipSend(
        uint256 bridgeAmount,
        uint64 destSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) external {
        _ccipSend(bridgeAmount, destSelector, ccipTxType, nonce, protocolId);
    }

    function getCcipSendRecoveryTxType() external view returns (Types.CcipTx ccipTxType) {
        ccipTxType = _childVaultStorage().s_ccipSendRecovery.ccipTxType;
    }

    function getCcipSendRecoveryAmount() external view returns (uint256 amount) {
        amount = _childVaultStorage().s_ccipSendRecovery.amount;
    }

    function getCcipSendRecoveryDestinationChainSelector() external view returns (uint64 destinationChainSelector) {
        destinationChainSelector = _childVaultStorage().s_ccipSendRecovery.destinationChainSelector;
    }

    function getCcipSendRecoveryNonce() external view returns (uint256 nonce) {
        nonce = _childVaultStorage().s_ccipSendRecovery.nonce;
    }

    function getCcipSendRecoveryProtocolId() external view returns (bytes32 protocolId) {
        protocolId = _childVaultStorage().s_ccipSendRecovery.protocolId;
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

    function handleCCIPRebalance(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        external
        returns (bool success)
    {
        /// @dev ChildVault's _setActiveAdapter override already calls BaseVaultStrategyLib's internal
        ///      form, avoiding the unresolved external library call Certora cannot link.
        success = _handleCCIPRebalance(rebalanceNonce, protocolId, amount);
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
}
