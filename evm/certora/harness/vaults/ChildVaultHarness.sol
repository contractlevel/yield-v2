// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

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

    function setActiveAdapter(bytes32 protocolId) external returns (address) {
        return _setActiveAdapter(protocolId);
    }

    function clearActiveAdapter() external {
        _clearActiveAdapter();
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

    function executeCcipSend(
        uint256 bridgeAmount,
        uint64 destSelector,
        Types.CcipTx ccipTxType,
        bytes calldata txData
    ) external {
        _executeCcipSend(bridgeAmount, destSelector, ccipTxType, txData);
    }

    function validateCcipSend(uint256 bridgeAmount, uint64 destSelector) external view returns (address vault) {
        vault = _validateCcipSend(bridgeAmount, destSelector);
    }

    function ccipSend(
        uint256 bridgeAmount,
        uint64 destSelector,
        Types.CcipTx ccipTxType,
        bytes calldata txData
    ) external {
        _ccipSend(bridgeAmount, destSelector, ccipTxType, txData);
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

    function getCcipSendRecoveryCreatedAt() external view returns (uint256 createdAt) {
        createdAt = _childVaultStorage().s_ccipSendRecovery.createdAt;
    }

    function getCcipSendRecoveryTxData() external view returns (bytes memory txData) {
        txData = _childVaultStorage().s_ccipSendRecovery.txData;
    }

    function getCcipSendRecoveryTxDataStorageSlot() external view returns (bytes32 value) {
        bytes storage txData = _childVaultStorage().s_ccipSendRecovery.txData;
        assembly {
            value := sload(txData.slot)
        }
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
        success = _handleCCIPRebalance(rebalanceNonce, protocolId, amount);
    }

    function validateReceivedTokenAndGetAmount(Client.Any2EVMMessage calldata message)
        external
        view
        returns (uint256 amount)
    {
        amount = _validateReceivedTokenAndGetAmount(message);
    }

    function exposedOnlyAllowedSender(address sender, uint64 srcChainSelector) external view {
        _onlyAllowedSender(sender, srcChainSelector);
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
}
