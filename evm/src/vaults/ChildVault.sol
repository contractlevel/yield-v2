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
/// @notice ChildVault is a contract that inherits from BaseVault. It's used to interact with Strategy protocols and communicate with the Parent and other ChildVaults across chains.
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
    /// @notice Initializes implementation-level immutable configuration for the ChildVault.
    /// @param params BaseVault constructor parameters for values baked into the implementation bytecode
    /// @param parentChainSelector CCIP selector for the parent chain
    /// @dev Precondition: parentChainSelector must not be zero
    /// @dev Precondition: parentChainSelector must not equal params.thisChainSelector
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector) BaseVault(params) {
        _revertIfZeroChainSelector(parentChainSelector);
        if (parentChainSelector == params.thisChainSelector) revert ChildVault__InvalidParentChainSelector();
        i_parentChainSelector = parentChainSelector;
        _disableInitializers();
    }

    /// @notice Initializes ChildVault mutable proxy state.
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    function initialize(BaseVault.InitParams memory params) external nonReentrant initializer {
        __BaseVault_init(params);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives CCIP messages
    /// @param message Any2EVMMessage.
    /// @dev Precondition: the call must not be reentered
    /// @dev Precondition: the message must be sent by an allowed sender (a crosschain vault mapped to an allowed source chain selector)
    /// @dev Precondition: there must not be an existent recovery mode
    /// @dev Precondition: the received token must be i_asset
    /// @dev Precondition: there should only be 1 token sent
    /// @dev Precondition: the amount of token receive must be more than 0
    /// @dev Precondition: the received tx type must be supported: EPOCH_NET_DEPOSIT or REBALANCE
    /// @dev Precondition: EPOCH_NET_DEPOSIT messages must originate from the parent chain
    /// @dev Precondition: the decoded nonce must be greater than the last nonce of its type handled by this child vault
    /// @dev Precondition: the contract must not be paused
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

        /// @dev data decodes to a uint256 epochNonce for epoch net deposits and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));

        if (ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT) {
            if (message.sourceChainSelector != i_parentChainSelector) {
                revert BaseVault__InvalidSourceChainSelector(message.sourceChainSelector, i_parentChainSelector);
            }
            uint256 epochNonce = abi.decode(data, (uint256));
            _handleEpochNonce($, epochNonce);
            _handleCCIPDeposit($, $_baseVault, epochNonce, receivedAmount);
        }
        /// @dev see BaseVault::_handleCCIPRebalance
        else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            _handleRebalanceNonce($, rebalanceNonce);
            _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
        } else {
            revert BaseVault__InvalidTxType(ccipTxType);
        }

        emit CCIPReceived(message.messageId, message.sourceChainSelector, ccipTxType);
    }

    /// @notice Internal function to only allow messages from allowed crosschain vaults
    /// @param sender The address of the sender
    /// @param srcChainSelector The CCIP selector of the chain
    /// @dev Precondition: Sender must be the crosschain vault for the source chain selector
    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view override {
        BaseVaultCcipLib._onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    /// @notice Handles the CCIP EPOCH_NET_DEPOSIT deposit message
    /// @param $ ChildVaultStorage for nonce and recovery state
    /// @param $_baseVault BaseVaultStorage for the active strategy adapter and recovery state
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that was bridged to deposit into the active strategy on this child chain
    /// @dev Only reachable on a ChildVault: the ParentVault sends a CCIP deposit to the active strategy chain
    ///      when an epoch's net flow is positive (more deposits than withdraws).
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

    /// @notice Sends a ChildVault CCIP message and stores recovery state on failure
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol id; only meaningful when ccipTxType is REBALANCE
    /// @dev Overrides BaseVault::_ccipSend to use a try/catch. (Parent failures use atomic revert)
    /// @dev Precondition: no recovery state must currently exist
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) internal override {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);
        /// @notice This same check runs again inside BaseVaultCcipLib._send (reached below via
        ///         tryCcipSend), but it's deliberately duplicated here too, outside the try/catch,
        ///         so a config error (e.g. an unregistered destination chain) reverts atomically
        ///         instead of being caught below and misfiled as retryable CCIP send recovery state.
        //slither-disable-next-line unused-return
        BaseVaultCcipLib._validateCcipSend($_baseVault, bridgeAmount, destinationChainSelector, i_thisChainSelector);

        try this.tryCcipSend(bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId) {}
        catch {
            _storeCcipSendRecovery($_baseVault, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);
        }
    }

    /// @notice Executes a CCIP send through an external self-call boundary for ChildVault try/catch recovery
    /// @dev Precondition: caller must be this vault
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol id; only meaningful when ccipTxType is REBALANCE
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
    /// @notice Executes the epoch withdraw from a strategy
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset to withdraw from the active strategy
    /// @dev This is called by the WorkflowRouter when net flow is negative (more withdraws than deposits).
    /// @dev Precondition: Caller must have the EPOCH_OPERATOR_ROLE
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: epochNonce must be greater than the last epoch nonce handled by this child vault
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

    /// @notice Withdraws the entire tvl from the active strategy protocol adapter and sends it to the new strategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @dev This is called by the WorkflowRouter.
    /// @dev This function shouldn't be in BaseVault because if a rebalance needs to be executed on the parent, this
    ///      is what happens: CRE workflow writes to parent; if parent == strategy, ParentVault.initiateRebalance
    ///      performs the equivalent withdraw-then-rebalance steps synchronously in the same call instead of via
    ///      this CRE-triggered function.
    /// @dev Precondition: caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: rebalanceNonce must be greater than the last rebalance nonce handled by this child vault
    /// @dev Precondition: call must not be reentered
    /// @dev Precondition: there must be no existent recovery mode
    /// @dev Precondition: the contract must not be paused
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

    /// @notice Executes a rebalance by attempting to withdraw from the old strategy with _executeWithdraw. If that was successful, then attempts to rebalance with _rebalanceToNewStrategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @return success Whether the withdraw from the old strategy succeeded or not
    /// @return amountRebalanced The amount rebalanced
    /// @dev The try/catch that handles a failed withdraw from the old strategy lives inside _executeWithdraw;
    ///      this function branches on its returned `success` flag rather than catching directly.
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

    /// @notice Rebalances the TVL to the new strategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param tvlToRebalance The TVL amount to rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @param oldAdapter The previously-active strategy adapter, already known by the caller
    /// @dev Handles a local rebalance on this chain or a crosschain rebalance to the new strategy chain.
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
    /// @dev Precondition: a recovery mode must be active (not NONE)
    /// @dev Precondition: function must not be reentered
    /// @dev Precondition: the contract must not be paused
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
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of asset to retry depositing
    /// @dev amount is already checked non-zero upstream, by `_ccipReceive`'s call to `_validateReceivedTokenAndGetAmount`
    /// @dev No recovery state must currently exist - already enforced by the sole caller, `_ccipReceive`,
    ///      which checks `_requireNoRecovery` before this is reached, with no recovery-mutating call in between.
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

    /// @notice Recovers a failed epoch deposit tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    function _recoverFailedEpochDeposit(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        Types.EpochRecovery memory recovery = $.s_epochDepositRecovery;
        uint256 epochNonce = recovery.epochNonce;

        _executeDeposit(recovery.amount, true, $_baseVault.s_activeProtocolAdapter);
        _clearEpochDepositRecovery($, $_baseVault, epochNonce);

        emit EpochDepositToStrategySuccess(epochNonce, recovery.amount);
    }

    /// @notice Clears recovery state for a failed epoch deposit
    /// @param $ ChildVaultStorage for the epoch deposit recovery state
    /// @param $_baseVault BaseVaultStorage for recovery mode
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
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of asset to retry withdrawing
    /// @dev amount is already checked non-zero upstream, by `executeEpochWithdraw`'s call to `_revertIfZeroAmount`
    /// @dev No recovery state must currently exist - already enforced by the sole caller, `executeEpochWithdraw`,
    ///      which checks `_requireNoRecovery` before this is reached, with no recovery-mutating call in between.
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

    /// @notice Recovers a failed epoch withdraw tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    /// @dev Precondition: amountOut from strategy withdraw must not be 0
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
    /// @param $ ChildVaultStorage for the epoch withdraw recovery state
    /// @param $_baseVault BaseVaultStorage for recovery mode
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
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    /// @param rebalanceNonce The rebalance nonce of the failed withdraw
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @dev Precondition: strategy chain selector must not be zero
    /// @dev No recovery state must currently exist - already enforced by the sole caller, `executeRebalance`,
    ///      which checks `_requireNoRecovery` before this is reached, with no recovery-mutating call in between.
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

    /// @notice Recovers a failed rebalance withdraw tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
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
    /// @param $ ChildVaultStorage for the rebalance withdraw recovery state
    /// @param $_baseVault BaseVaultStorage for recovery mode
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
    /// @param $_baseVault BaseVaultStorage
    /// @param bridgeAmount The amount of asset that was being bridged
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol id; only meaningful when ccipTxType is REBALANCE
    /// @dev No recovery state must currently exist - already enforced by the sole caller, `_ccipSend`'s own
    ///      catch block, which checks `_requireNoRecovery` at the top of the same function, immediately
    ///      before the try/catch; the only intervening action is the CCIP send attempt itself, and
    ///      `nonReentrant` blocks any reentrant call from mutating recovery state in between.
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
    /// @param $_baseVault BaseVaultStorage
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
    /// @param $ ChildVaultStorage for Child Recovery state
    /// @param $_baseVault BaseVaultStorage for recovery mode
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
    /// @param $ ChildVaultStorage for handled nonces
    /// @param epochNonce The epoch nonce to handle
    /// @dev Reverts unless epochNonce is greater than the last handled epoch nonce
    function _handleEpochNonce(ChildVaultStorage storage $, uint256 epochNonce) internal {
        uint256 lastHandledNonce = $.s_lastHandledEpochNonce;
        if (epochNonce <= lastHandledNonce) {
            revert ChildVault__InvalidEpochNonce(epochNonce, lastHandledNonce);
        }
        $.s_lastHandledEpochNonce = epochNonce;
    }

    /// @notice Validates and stores a rebalance nonce as handled by this child vault
    /// @param $ ChildVaultStorage for handled nonces
    /// @param rebalanceNonce The rebalance nonce to handle
    /// @dev Reverts unless rebalanceNonce is greater than the last handled rebalance nonce
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
    /// @notice Gets the CCIP selector for the parent chain
    /// @return parentChainSelector The CCIP selector for the parent chain
    function getParentChainSelector() external view returns (uint64 parentChainSelector) {
        parentChainSelector = i_parentChainSelector;
    }

    /// @notice Gets the highest epoch nonce handled by this child vault
    /// @return lastHandledEpochNonce The highest handled epoch nonce
    function getLastHandledEpochNonce() external view returns (uint256 lastHandledEpochNonce) {
        lastHandledEpochNonce = _childVaultStorage().s_lastHandledEpochNonce;
    }

    /// @notice Gets the highest rebalance nonce handled by this child vault
    /// @return lastHandledRebalanceNonce The highest handled rebalance nonce
    function getLastHandledRebalanceNonce() external view returns (uint256 lastHandledRebalanceNonce) {
        lastHandledRebalanceNonce = _childVaultStorage().s_lastHandledRebalanceNonce;
    }

    /// @notice Gets failed epoch deposit recovery state
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochDepositRecovery;
    }

    /// @notice Gets failed epoch withdraw recovery state
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochWithdrawRecovery;
    }

    /// @notice Gets failed rebalance withdraw recovery state
    /// @return recovery The stored rebalance withdraw recovery state
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery) {
        recovery = _childVaultStorage().s_rebalanceWithdrawRecovery;
    }

    /// @notice Gets failed CCIP send recovery state
    /// @return recovery The stored CCIP send recovery state
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
    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain, or 0 if not
    /// @return tvl The Yieldcoin TVL
    /// @dev Unlike the Parent Vault implementation, which only includes s_rebalanceDepositRecovery.amount, the
    ///      Child Vault implementation also includes s_epochDepositRecovery.amount and s_ccipSendRecovery.amount.
    /// @dev Returns 0 if the TVL has been bridged away with no adapter set; if a rebalance-away CCIP send
    ///      failed, the stranded funds are still counted via s_ccipSendRecovery.amount. This should not be
    ///      read onchain when Parent state is REBALANCING.
    function _getTVL() internal view override returns (uint256 tvl) {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        if (activeAdapter != address(0)) {
            tvl = IProtocolAdapter(activeAdapter).getTVL() + $.s_epochDepositRecovery.amount
                + $_baseVault.s_rebalanceDepositRecovery.amount + $.s_ccipSendRecovery.amount;
        } else {
            /// @dev The adapter is cleared before a rebalance-away CCIP send; if that send fails, the funds
            ///      are still held locally and tracked by s_ccipSendRecovery.amount (0 if no recovery is pending).
            tvl = $.s_ccipSendRecovery.amount;
        }
    }

    /// @notice Sets the active strategy protocol adapter
    /// @param protocolId The protocol ID of the strategy
    /// @return adapter The address of the active strategy protocol adapter
    /// @dev Precondition: the protocol ID must have a registered adapter
    /// @dev Precondition: the registered adapter must be bound to this vault
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
