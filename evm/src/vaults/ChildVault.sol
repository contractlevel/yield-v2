// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVault} from "./BaseVault.sol";
import {ChildVaultStore} from "./ChildVaultStore.sol";

import {IBaseVault} from "../interfaces/vaults/IBaseVault.sol";
import {IChildVault} from "../interfaces/vaults/IChildVault.sol";
import {BaseVaultCcipLib} from "../libraries/vaults/BaseVaultCcipLib.sol";
import {BaseVaultConfigLib} from "../libraries/vaults/BaseVaultConfigLib.sol";
import {BaseVaultStrategyLib} from "../libraries/vaults/BaseVaultStrategyLib.sol";
import {Types} from "../libraries/Types.sol";
import {Roles} from "../libraries/Roles.sol";
import {IProtocolAdapter} from "../interfaces/adapters/IProtocolAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

/// @title Yieldcoin v2 ChildVault
/// @author @contractlevel
/// @notice Manages strategy positions and crosschain operations on a chain remote from the ParentVault
contract ChildVault is BaseVault, ChildVaultStore, IChildVault {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev CCIP selector for the parent chain
    uint64 internal immutable i_parentChainSelector;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes immutable ChildVault configuration and disables implementation initializers
    /// @param params BaseVault constructor parameters for values baked into the implementation bytecode
    /// @param parentChainSelector The CCIP selector for the parent chain
    /// @dev Reverts if BaseVault immutable configuration is invalid
    /// @dev Reverts if parentChainSelector is zero
    /// @dev Reverts if parentChainSelector identifies this chain
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector) BaseVault(params) {
        _revertIfZeroChainSelector(parentChainSelector);
        if (parentChainSelector == params.thisChainSelector) revert ChildVault__InvalidParentChainSelector();
        i_parentChainSelector = parentChainSelector;
        _disableInitializers();
    }

    /// @notice Initializes ChildVault mutable proxy state
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    /// @dev Reverts if any BaseVault initializer parameter is invalid
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the proxy has already been initialized
    function initialize(BaseVault.InitParams memory params) external nonReentrant initializer {
        __BaseVault_init(params);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Handles an inbound CCIP epoch deposit or rebalance message
    /// @param message The CCIP message received from the router
    /// @dev Reverts if the caller is not the configured CCIP router
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if no crosschain vault is registered for the source chain
    /// @dev Reverts if the decoded sender is not the registered crosschain vault
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if the message does not deliver exactly one token amount
    /// @dev Reverts if the delivered token is not the configured underlying asset
    /// @dev Reverts if the delivered amount is zero
    /// @dev Reverts if the transaction type is not EPOCH_NET_DEPOSIT or REBALANCE
    /// @dev Reverts if an EPOCH_NET_DEPOSIT message does not originate from the parent chain
    /// @dev Reverts if the decoded nonce is not greater than the last handled nonce of its type
    /// @dev Reverts if message data cannot be decoded for its transaction type
    /// @dev Reverts if a rebalance protocol has no registered adapter
    /// @dev Reverts if the registered rebalance adapter is bound to another vault
    /// @dev Stores epoch-deposit or rebalance-deposit recovery if the strategy deposit fails
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        nonReentrant
        whenNotPaused
        onlyAllowedSender(abi.decode(message.sender, (address)), message.sourceChainSelector)
    {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();
        _requireNoRecovery($_baseVault);
        uint256 receivedAmount = BaseVaultCcipLib._validateReceivedTokenAndGetAmount(message, i_asset);

        // data decodes to a uint256 epochNonce for epoch net deposits and a
        // (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));

        if (ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT) {
            if (message.sourceChainSelector != i_parentChainSelector) {
                revert BaseVault__InvalidSourceChainSelector(message.sourceChainSelector, i_parentChainSelector);
            }
            uint256 epochNonce = abi.decode(data, (uint256));
            _handleEpochNonce($, epochNonce);
            _handleCCIPDeposit($, $_baseVault, epochNonce, receivedAmount);
        }
        // See BaseVault._handleCCIPRebalance
        else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            _handleRebalanceNonce($, rebalanceNonce);
            _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
        } else {
            revert BaseVault__InvalidTxType(ccipTxType);
        }

        emit CCIPReceived(message.messageId, message.sourceChainSelector, ccipTxType);
    }

    /// @notice Validates that the CCIP message sender is the registered crosschain vault for the source chain
    /// @param sender The decoded address of the CCIP sender
    /// @param srcChainSelector The CCIP selector of the source chain
    /// @dev Reverts if no crosschain vault is registered for srcChainSelector
    /// @dev Reverts if sender is not the registered crosschain vault
    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view override {
        BaseVaultCcipLib._onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    /// @notice Deposits an inbound CCIP epoch amount into the active strategy or stores recovery on failure
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of underlying asset received for deposit
    /// @dev Stores epoch deposit recovery and returns normally if the adapter deposit fails
    function _handleCCIPDeposit(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 epochNonce,
        uint256 amount
    ) internal {
        bool success = _executeDeposit(amount, false, $_baseVault.s_activeProtocolAdapter);
        if (success) {
            emit EpochDepositToStrategySuccess(epochNonce, amount);
        } else {
            _storeEpochDepositRecovery($, $_baseVault, epochNonce, amount);
            emit EpochDepositToStrategyFailure(epochNonce, amount);
        }
    }

    /// @notice Sends a ChildVault CCIP message or stores recovery if a valid send attempt fails
    /// @param bridgeAmount The amount of underlying asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol ID; only meaningful when ccipTxType is REBALANCE
    /// @dev Overrides BaseVault._ccipSend to catch valid send-attempt failures and store them for recovery;
    ///      ParentVault CCIP send failures revert atomically
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if bridgeAmount is zero
    /// @dev Reverts if destinationChainSelector is zero
    /// @dev Reverts if destinationChainSelector identifies this chain
    /// @dev Reverts if no crosschain vault is registered for destinationChainSelector
    /// @dev Stores CCIP-send recovery if fee calculation, token approval, or the router call fails
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) internal override {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);
        // Validate outside try/catch so configuration errors revert instead of being stored as recovery
        //slither-disable-next-line unused-return
        BaseVaultCcipLib._validateCcipSend($_baseVault, bridgeAmount, destinationChainSelector, i_thisChainSelector);

        try this.tryCcipSend(bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId) {}
        catch {
            _storeCcipSendRecovery($_baseVault, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);
        }
    }

    /// @notice Executes a CCIP send through an external self-call boundary for ChildVault try/catch recovery
    /// @param bridgeAmount The amount of underlying asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol ID; only meaningful when ccipTxType is REBALANCE
    /// @dev Reverts if the caller is not this vault
    /// @dev Reverts if bridgeAmount is zero
    /// @dev Reverts if destinationChainSelector is zero
    /// @dev Reverts if destinationChainSelector identifies this chain
    /// @dev Reverts if no crosschain vault is registered for destinationChainSelector
    /// @dev Requires successful fee calculation, token approvals, and CCIP router execution
    /// @dev Requires the vault to hold enough underlying asset and LINK for the transfer and CCIP fee
    function tryCcipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) external {
        if (msg.sender != address(this)) revert ChildVault__OnlySelf();
        BaseVaultCcipLib._send(
            _baseVaultStorage(),
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            nonce,
            protocolId,
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }

    /*//////////////////////////////////////////////////////////////
                                  CRE
    //////////////////////////////////////////////////////////////*/
    /// @notice Attempts an epoch withdrawal from the active strategy and sends the underlying asset to the parent vault
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of underlying asset to withdraw from the active strategy
    /// @dev Called by the WorkflowRouter when net flow is negative
    /// @dev Reverts if the caller does not have EPOCH_OPERATOR_ROLE
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if amount is zero
    /// @dev Reverts if epochNonce is not greater than the last epoch nonce handled by this child vault
    /// @dev Reverts if a successful strategy withdrawal returns zero assets
    /// @dev Reverts if no parent vault is registered for the parent chain
    /// @dev Stores epoch-withdraw recovery if the strategy withdrawal fails
    /// @dev Stores CCIP-send recovery if a valid CCIP send attempt fails
    function executeEpochWithdraw(uint256 epochNonce, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        onlyRole(Roles.EPOCH_OPERATOR_ROLE)
    {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();
        _requireNoRecovery($_baseVault);
        _revertIfZeroAmount(amount);
        _handleEpochNonce($, epochNonce);

        (bool success, uint256 amountOut) = _executeWithdraw(amount, false, $_baseVault.s_activeProtocolAdapter);
        if (success) {
            _revertIfZeroAmount(amountOut);
            emit EpochWithdrawFromStrategySuccess(epochNonce, amountOut);
            _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, epochNonce, bytes32(0));
        } else {
            _storeEpochWithdrawRecovery($, $_baseVault, epochNonce, amount);
            emit EpochWithdrawFromStrategyFailure(epochNonce, amount);
        }
    }

    /// @notice Attempts to withdraw the active strategy's entire position and continue the rebalance
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @dev Reverts if the caller does not have REBALANCE_OPERATOR_ROLE
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if rebalanceNonce is not greater than the last rebalance nonce handled by this child vault
    /// @dev Reverts if a successful strategy withdrawal returns zero assets
    /// @dev Reverts if newStrategy.chainSelector is zero
    /// @dev If the initial strategy withdrawal succeeds, reverts if a local target protocol has no registered adapter
    /// @dev If the initial strategy withdrawal succeeds, reverts if the registered local adapter is bound to another vault
    /// @dev If the initial strategy withdrawal succeeds, reverts if no crosschain vault is registered for a remote target chain
    /// @dev Stores rebalance-withdraw recovery if the old-strategy withdrawal fails
    /// @dev Stores rebalance-deposit recovery if a local new-strategy deposit fails
    /// @dev Stores CCIP-send recovery if a valid CCIP send attempt fails
    function executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        external
        nonReentrant
        whenNotPaused
        onlyRole(Roles.REBALANCE_OPERATOR_ROLE)
    {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();
        _requireNoRecovery($_baseVault);
        _handleRebalanceNonce($, rebalanceNonce);

        (bool success,) = _executeRebalance(rebalanceNonce, newStrategy);
        if (!success) {
            _storeRebalanceWithdrawRecovery($, $_baseVault, rebalanceNonce, newStrategy);
        }
    }

    /// @notice Withdraws the active strategy position and continues the rebalance on success
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @return success Whether the withdrawal from the old strategy succeeded
    /// @return amountRebalanced The amount of underlying asset withdrawn for the rebalance
    /// @dev Reverts if a successful strategy withdrawal returns zero assets
    /// @dev Returns false and emits RebalanceWithdrawFailure if the adapter withdrawal fails
    function _executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        internal
        returns (bool success, uint256 amountRebalanced)
    {
        address activeAdapter = _baseVaultStorage().s_activeProtocolAdapter;
        (success, amountRebalanced) = _executeWithdraw(type(uint256).max, false, activeAdapter);
        if (success) {
            _revertIfZeroAmount(amountRebalanced);
            emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
            _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, newStrategy, activeAdapter);
        } else {
            emit RebalanceWithdrawFailure(rebalanceNonce);
        }
    }

    /// @notice Deposits locally or sends the withdrawn position to a remote strategy chain
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param tvlToRebalance The amount of underlying asset to rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @param oldAdapter The previously-active strategy adapter, already known by the caller
    /// @dev Reverts if a local target protocol has no registered adapter
    /// @dev Reverts if the registered local adapter is bound to another vault
    /// @dev Stores rebalance-deposit recovery if a local adapter deposit fails
    /// @dev Reverts if a remote target chain has no registered crosschain vault
    /// @dev Stores CCIP-send recovery if a valid remote send attempt fails
    function _rebalanceToNewStrategy(
        uint256 rebalanceNonce,
        uint256 tvlToRebalance,
        Types.Strategy memory newStrategy,
        address oldAdapter
    ) internal {
        //slither-disable-next-line incorrect-equality
        if (newStrategy.chainSelector == i_thisChainSelector) {
            address newAdapter = _setActiveAdapter(newStrategy.protocolId);

            bool success = _executeDeposit(tvlToRebalance, false, newAdapter);
            if (success) {
                emit RebalanceDepositSuccess(rebalanceNonce, tvlToRebalance);
            } else {
                _storeRebalanceDepositRecovery(_baseVaultStorage(), rebalanceNonce, tvlToRebalance);
                emit RebalanceDepositFailure(rebalanceNonce, tvlToRebalance);
            }
        } else {
            _clearActiveAdapter(oldAdapter);
            _ccipSend(
                tvlToRebalance,
                newStrategy.chainSelector,
                Types.CcipTx.REBALANCE,
                rebalanceNonce,
                newStrategy.protocolId
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev Permissionless because the operation and all inputs are fixed by stored recovery state
    /// @dev Reverts if no recovery mode is active
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the active recovery requires a strategy adapter that is not set
    /// @dev Reverts if the active recovery requires a local target adapter that is not registered
    /// @dev Reverts if the registered local target adapter is bound to another vault
    /// @dev Reverts if the active recovery requires an unregistered crosschain vault
    /// @dev Reverts if a strategy withdrawal used by the active recovery returns zero assets
    /// @dev Requires any strategy, token, and CCIP interactions used by the active recovery to succeed
    function executeRecovery() external override(BaseVault, IBaseVault) nonReentrant whenNotPaused {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        Types.RecoveryMode mode = $_baseVault.s_recoveryMode;
        if (mode == Types.RecoveryMode.NONE) revert BaseVault__NoPendingRecovery();

        if (mode == Types.RecoveryMode.REBALANCE_DEPOSIT) {
            _recoverFailedRebalanceDeposit($_baseVault);
        } else if (mode == Types.RecoveryMode.EPOCH_DEPOSIT) {
            _recoverFailedEpochDeposit(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.EPOCH_WITHDRAW) {
            _recoverFailedEpochWithdraw(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.REBALANCE_WITHDRAW) {
            _recoverFailedRebalanceWithdraw(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.CCIP_SEND) {
            _recoverFailedCcipSend($_baseVault);
        }
    }

    // --- EPOCH DEPOSIT RECOVERY --- //

    /// @notice Stores recovery state for a failed epoch deposit
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of underlying asset to retry depositing
    /// @dev The caller must ensure amount is nonzero and no other recovery mode is active
    function _storeEpochDepositRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 epochNonce,
        uint256 amount
    ) internal {
        $.s_epochDepositRecovery = Types.EpochRecovery({epochNonce: epochNonce, amount: amount});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.EPOCH_DEPOSIT;
        emit EpochDepositRecoveryStored(epochNonce, amount);
    }

    /// @notice Retries a failed epoch deposit into the active strategy
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @dev Reverts if the active strategy adapter is not set
    /// @dev Reverts if the strategy deposit fails
    /// @dev The caller must ensure epoch deposit recovery is active
    function _recoverFailedEpochDeposit(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        Types.EpochRecovery memory recovery = $.s_epochDepositRecovery;
        uint256 epochNonce = recovery.epochNonce;

        _executeDeposit(recovery.amount, true, $_baseVault.s_activeProtocolAdapter);
        _clearEpochDepositRecovery($, $_baseVault, epochNonce);

        emit EpochDepositToStrategySuccess(epochNonce, recovery.amount);
    }

    /// @notice Clears recovery state for a failed epoch deposit
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param epochNonce The epoch nonce of the recovery being cleared, already known by the caller
    function _clearEpochDepositRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 epochNonce
    ) internal {
        delete $.s_epochDepositRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochDepositRecoveryCleared(epochNonce);
    }

    // --- EPOCH WITHDRAW RECOVERY --- //

    /// @notice Stores recovery state for a failed epoch withdraw
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of underlying asset to retry withdrawing
    /// @dev The caller must ensure amount is nonzero and no other recovery mode is active
    function _storeEpochWithdrawRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 epochNonce,
        uint256 amount
    ) internal {
        $.s_epochWithdrawRecovery = Types.EpochRecovery({epochNonce: epochNonce, amount: amount});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.EPOCH_WITHDRAW;
        emit EpochWithdrawRecoveryStored(epochNonce, amount);
    }

    /// @notice Retries a failed epoch withdrawal and sends the withdrawn underlying asset to the parent vault
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @dev Reverts if the active strategy adapter is not set
    /// @dev Reverts if the strategy withdrawal fails
    /// @dev Reverts if the strategy withdrawal returns zero assets
    /// @dev Reverts if no parent vault is registered for the parent chain
    /// @dev Stores CCIP-send recovery if a valid send attempt fails
    /// @dev The caller must ensure epoch withdraw recovery is active
    function _recoverFailedEpochWithdraw(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        Types.EpochRecovery memory recovery = $.s_epochWithdrawRecovery;
        uint256 epochNonce = recovery.epochNonce;

        (, uint256 amountOut) = _executeWithdraw(recovery.amount, true, $_baseVault.s_activeProtocolAdapter);
        //slither-disable-next-line incorrect-equality
        if (amountOut == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearEpochWithdrawRecovery($, $_baseVault, epochNonce);
        emit EpochWithdrawFromStrategySuccess(epochNonce, amountOut);
        _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, epochNonce, bytes32(0));
    }

    /// @notice Clears recovery state for a failed epoch withdraw
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param epochNonce The epoch nonce of the recovery being cleared, already known by the caller
    function _clearEpochWithdrawRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 epochNonce
    ) internal {
        delete $.s_epochWithdrawRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochWithdrawRecoveryCleared(epochNonce);
    }

    // --- REBALANCE WITHDRAW RECOVERY --- //

    /// @notice Stores recovery state for a failed rebalance withdraw
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param rebalanceNonce The rebalance nonce of the failed withdraw
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @dev Reverts if strategy.chainSelector is zero
    /// @dev The caller must ensure no other recovery mode is active
    function _storeRebalanceWithdrawRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 rebalanceNonce,
        Types.Strategy memory strategy
    ) internal {
        //slither-disable-next-line incorrect-equality
        if (strategy.chainSelector == 0) revert ChildVault__InvalidRecoveryStrategy();
        $.s_rebalanceWithdrawRecovery =
            Types.RebalanceWithdrawRecovery({rebalanceNonce: rebalanceNonce, strategy: strategy});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.REBALANCE_WITHDRAW;
        emit RebalanceWithdrawRecoveryStored(rebalanceNonce, strategy.protocolId, strategy.chainSelector);
    }

    /// @notice Retries a failed rebalance withdrawal and continues the rebalance
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @dev Reverts if the active strategy adapter is not set
    /// @dev Reverts if the strategy withdrawal fails
    /// @dev Reverts if the strategy withdrawal returns zero assets
    /// @dev Reverts if a recovered local target protocol has no registered adapter
    /// @dev Reverts if the registered recovered local adapter is bound to another vault
    /// @dev Reverts if no crosschain vault is registered for a recovered remote target chain
    /// @dev Stores rebalance-deposit recovery if the recovered local strategy deposit fails
    /// @dev Stores CCIP-send recovery if a valid recovered remote send attempt fails
    /// @dev The caller must ensure rebalance withdraw recovery is active
    function _recoverFailedRebalanceWithdraw(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault)
        internal
    {
        Types.RebalanceWithdrawRecovery memory recovery = $.s_rebalanceWithdrawRecovery;
        uint256 rebalanceNonce = recovery.rebalanceNonce;

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        (, uint256 amountRebalanced) = _executeWithdraw(type(uint256).max, true, activeAdapter);
        //slither-disable-next-line incorrect-equality
        if (amountRebalanced == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearRebalanceWithdrawRecovery($, $_baseVault, rebalanceNonce);
        emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
        _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, recovery.strategy, activeAdapter);
    }

    /// @notice Clears recovery state for a failed rebalance withdraw
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @param rebalanceNonce The rebalance nonce of the recovery being cleared, already known by the caller
    function _clearRebalanceWithdrawRecovery(
        ChildVaultStorage storage $,
        BaseVaultStorage storage $_baseVault,
        uint256 rebalanceNonce
    ) internal {
        delete $.s_rebalanceWithdrawRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit RebalanceWithdrawRecoveryCleared(rebalanceNonce);
    }

    // --- CCIP SEND RECOVERY --- //

    /// @notice Stores recovery state for a failed CCIP send
    /// @param $_baseVault BaseVault namespaced storage
    /// @param bridgeAmount The amount of underlying asset that was being bridged
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol ID; only meaningful when ccipTxType is REBALANCE
    /// @dev The caller must ensure no other recovery mode is active
    function _storeCcipSendRecovery(
        BaseVaultStorage storage $_baseVault,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) internal {
        _childVaultStorage().s_ccipSendRecovery = Types.CcipSendRecovery({
            amount: bridgeAmount,
            nonce: nonce,
            protocolId: protocolId,
            destinationChainSelector: destinationChainSelector,
            ccipTxType: ccipTxType
        });
        $_baseVault.s_recoveryMode = Types.RecoveryMode.CCIP_SEND;
        emit CcipSendRecoveryStored(ccipTxType, destinationChainSelector, bridgeAmount);
    }

    /// @notice Recovers a failed CCIP send by retrying it
    /// @param $_baseVault BaseVault namespaced storage
    /// @dev Reverts if the stored bridge amount is zero
    /// @dev Reverts if the stored destination chain selector is zero
    /// @dev Reverts if the stored destination chain selector identifies this chain
    /// @dev Reverts if no crosschain vault is registered for the stored destination chain selector
    /// @dev Requires successful fee calculation, token approvals, and CCIP router execution
    /// @dev A failed retry restores the cleared recovery state through transaction rollback
    /// @dev The caller must ensure CCIP send recovery is active
    function _recoverFailedCcipSend(BaseVaultStorage storage $_baseVault) internal {
        // Clear before retry; if CCIP send reverts, EVM atomicity restores this recovery state.
        Types.CcipSendRecovery memory recovery = _clearCcipSendRecovery(_childVaultStorage(), $_baseVault);

        BaseVaultCcipLib._send(
            $_baseVault,
            recovery.amount,
            recovery.destinationChainSelector,
            recovery.ccipTxType,
            recovery.nonce,
            recovery.protocolId,
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }

    /// @notice Clears recovery state for a failed CCIP send
    /// @param $ ChildVault namespaced storage
    /// @param $_baseVault BaseVault namespaced storage
    /// @return recovery The cleared CCIP send recovery state
    function _clearCcipSendRecovery(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault)
        internal
        returns (Types.CcipSendRecovery memory recovery)
    {
        recovery = $.s_ccipSendRecovery;
        delete $.s_ccipSendRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit CcipSendRecoveryCleared(recovery.ccipTxType, recovery.destinationChainSelector, recovery.amount);
    }

    /*//////////////////////////////////////////////////////////////
                            NONCE HANDLING
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates and stores an epoch nonce as handled by this child vault
    /// @param $ ChildVault namespaced storage
    /// @param epochNonce The epoch nonce to handle
    /// @dev Reverts if epochNonce is not greater than the last handled epoch nonce
    function _handleEpochNonce(ChildVaultStorage storage $, uint256 epochNonce) internal {
        uint256 lastHandledNonce = $.s_lastHandledEpochNonce;
        if (epochNonce <= lastHandledNonce) {
            revert ChildVault__InvalidEpochNonce(epochNonce, lastHandledNonce);
        }
        $.s_lastHandledEpochNonce = epochNonce;
    }

    /// @notice Validates and stores a rebalance nonce as handled by this child vault
    /// @param $ ChildVault namespaced storage
    /// @param rebalanceNonce The rebalance nonce to handle
    /// @dev Reverts if rebalanceNonce is not greater than the last handled rebalance nonce
    function _handleRebalanceNonce(ChildVaultStorage storage $, uint256 rebalanceNonce) internal {
        uint256 lastHandledNonce = $.s_lastHandledRebalanceNonce;
        if (rebalanceNonce <= lastHandledNonce) {
            revert ChildVault__InvalidRebalanceNonce(rebalanceNonce, lastHandledNonce);
        }
        $.s_lastHandledRebalanceNonce = rebalanceNonce;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the CCIP selector for the parent chain
    /// @return parentChainSelector The CCIP selector for the parent chain
    function getParentChainSelector() external view returns (uint64 parentChainSelector) {
        parentChainSelector = i_parentChainSelector;
    }

    /// @notice Returns the highest epoch nonce handled by this child vault
    /// @return lastHandledEpochNonce The highest handled epoch nonce
    function getLastHandledEpochNonce() external view returns (uint256 lastHandledEpochNonce) {
        lastHandledEpochNonce = _childVaultStorage().s_lastHandledEpochNonce;
    }

    /// @notice Returns the highest rebalance nonce handled by this child vault
    /// @return lastHandledRebalanceNonce The highest handled rebalance nonce
    function getLastHandledRebalanceNonce() external view returns (uint256 lastHandledRebalanceNonce) {
        lastHandledRebalanceNonce = _childVaultStorage().s_lastHandledRebalanceNonce;
    }

    /// @notice Returns the state required to determine the next ChildVault operation
    /// @return state The current ChildVault operational state
    function getChildOperationalState() external view returns (Types.ChildOperationalState memory state) {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();

        state.paused = paused();
        state.recoveryMode = $_baseVault.s_recoveryMode;
        state.lastHandledEpochNonce = $.s_lastHandledEpochNonce;
        state.lastHandledRebalanceNonce = $.s_lastHandledRebalanceNonce;
    }

    /// @notice Returns the failed epoch deposit recovery state
    /// @return recovery Types.EpochRecovery struct includes:
    ///         uint256 epochNonce - the nonce of the failed epoch deposit
    ///         uint256 amount - the amount of underlying asset to retry depositing
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochDepositRecovery;
    }

    /// @notice Returns the failed epoch withdraw recovery state
    /// @return recovery Types.EpochRecovery struct includes:
    ///         uint256 epochNonce - the nonce of the failed epoch withdrawal
    ///         uint256 amount - the amount of underlying asset to retry withdrawing
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochWithdrawRecovery;
    }

    /// @notice Returns the failed rebalance withdraw recovery state
    /// @return recovery Types.RebalanceWithdrawRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         Types.Strategy strategy - the target strategy to continue the rebalance into after withdrawal succeeds
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery) {
        recovery = _childVaultStorage().s_rebalanceWithdrawRecovery;
    }

    /// @notice Returns the failed CCIP send recovery state
    /// @return recovery Types.CcipSendRecovery struct includes:
    ///         uint256 amount - the amount of underlying asset to bridge
    ///         uint256 nonce - the epoch or rebalance nonce of the failed operation
    ///         bytes32 protocolId - the target protocol ID for a rebalance, otherwise zero
    ///         uint64 destinationChainSelector - the CCIP selector of the destination chain
    ///         Types.CcipTx ccipTxType - the CCIP transaction type to retry
    function getCcipSendRecovery() external view returns (Types.CcipSendRecovery memory recovery) {
        recovery = _childVaultStorage().s_ccipSendRecovery;
    }

    /*//////////////////////////////////////////////////////////////
                             CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBaseVault
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults)
        external
        override(BaseVault, IBaseVault)
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        BaseVaultConfigLib._setCrosschainVaults(_baseVaultStorage(), chainSelectors, vaults);
    }

    /// @inheritdoc IBaseVault
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit)
        external
        override(BaseVault, IBaseVault)
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        BaseVaultConfigLib._setCcipGasLimit(_baseVaultStorage(), chainSelector, gasLimit);
    }

    /// @inheritdoc IBaseVault
    function setDefaultCcipGasLimit(uint256 gasLimit)
        external
        override(BaseVault, IBaseVault)
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        BaseVaultConfigLib._setDefaultCcipGasLimit(_baseVaultStorage(), gasLimit);
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns this vault's accounted underlying-asset value
    /// @return tvl The active strategy position plus applicable vault-held recovery assets
    /// @dev Returns zero when this vault has neither an active strategy position nor applicable recovery assets
    /// @dev Includes pending epoch-deposit, rebalance-deposit, and CCIP-send recovery amounts held by this vault
    /// @dev Returns only the pending CCIP-send recovery amount when no active adapter is set
    function _getTVL() internal view override returns (uint256 tvl) {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        if (activeAdapter != address(0)) {
            tvl = IProtocolAdapter(activeAdapter).getTVL() + $.s_epochDepositRecovery.amount
                + $_baseVault.s_rebalanceDepositRecovery.amount + $.s_ccipSendRecovery.amount;
        } else {
            // The adapter is cleared before a remote rebalance send; a failed send remains locally recoverable
            tvl = $.s_ccipSendRecovery.amount;
        }
    }

    /// @notice Sets the active strategy protocol adapter
    /// @param protocolId The protocol ID of the strategy
    /// @return adapter The address of the active strategy protocol adapter
    /// @dev Reverts if protocolId has no registered adapter
    /// @dev Reverts if the registered adapter is bound to a different vault
    /// @dev ChildVault has enough bytecode headroom to inline the library implementation,
    ///      which also avoids unresolved external library calls in ChildVault verification.
    function _setActiveAdapter(bytes32 protocolId) internal override returns (address adapter) {
        adapter =
            BaseVaultStrategyLib._setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    /// @notice Clears the active strategy protocol adapter for this chain, given a known adapter
    /// @param adapter The active strategy adapter being cleared, already known by the caller
    /// @dev ChildVault has enough bytecode headroom to inline the library implementation,
    ///      which also avoids unresolved external library calls in ChildVault verification.
    function _clearActiveAdapter(address adapter) internal override {
        BaseVaultStrategyLib._clearActiveAdapter(_baseVaultStorage(), adapter);
    }
}
