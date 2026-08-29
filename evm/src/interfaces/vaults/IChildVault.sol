// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IBaseVault} from "./IBaseVault.sol";
import {Types} from "../../libraries/Types.sol";

/// @title Yieldcoin v2 ChildVault Interface
/// @author @contractlevel
/// @notice Interface for Child-only Yieldcoin v2 vault behavior
interface IChildVault is IBaseVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when a recovery strategy is invalid
    error ChildVault__InvalidRecoveryStrategy();
    /// @dev Thrown when the parent chain selector is invalid for this child vault
    error ChildVault__InvalidParentChainSelector();
    /// @dev Thrown when an epoch nonce is not greater than the last nonce handled by this child vault
    /// @param providedNonce The epoch nonce supplied to the child vault
    /// @param lastHandledNonce The highest epoch nonce previously handled by this child vault
    error ChildVault__InvalidEpochNonce(uint256 providedNonce, uint256 lastHandledNonce);
    /// @dev Thrown when a rebalance nonce is not greater than the last nonce handled by this child vault
    /// @param providedNonce The rebalance nonce supplied to the child vault
    /// @param lastHandledNonce The highest rebalance nonce previously handled by this child vault
    error ChildVault__InvalidRebalanceNonce(uint256 providedNonce, uint256 lastHandledNonce);
    /// @dev Thrown when an external self-call helper is called by any address other than this contract
    error ChildVault__OnlySelf();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit to the strategy fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of underlying asset that failed to deposit
    event EpochDepositToStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a strategy withdrawal fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of underlying asset that failed to withdraw
    event EpochWithdrawFromStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a rebalance withdrawal from the old strategy fails
    /// @param rebalanceNonce The nonce of the rebalance
    event RebalanceWithdrawFailure(uint256 indexed rebalanceNonce);

    /// @notice Emitted when failed epoch deposit recovery state is stored
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of underlying asset to retry depositing
    event EpochDepositRecoveryStored(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when failed epoch deposit recovery state is cleared
    /// @param epochNonce The epoch nonce of the recovered deposit
    event EpochDepositRecoveryCleared(uint256 indexed epochNonce);

    /// @notice Emitted when failed epoch withdraw recovery state is stored
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of underlying asset to retry withdrawing
    event EpochWithdrawRecoveryStored(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when failed epoch withdraw recovery state is cleared
    /// @param epochNonce The epoch nonce of the recovered withdraw
    event EpochWithdrawRecoveryCleared(uint256 indexed epochNonce);

    /// @notice Emitted when failed rebalance withdraw recovery state is stored
    /// @param rebalanceNonce The nonce of the failed rebalance withdraw
    /// @param protocolId The target strategy protocol ID
    /// @param chainSelector The target strategy chain selector
    event RebalanceWithdrawRecoveryStored(
        uint256 indexed rebalanceNonce, bytes32 indexed protocolId, uint64 indexed chainSelector
    );

    /// @notice Emitted when failed rebalance withdraw recovery state is cleared
    /// @param rebalanceNonce The nonce of the recovered rebalance withdraw
    event RebalanceWithdrawRecoveryCleared(uint256 indexed rebalanceNonce);

    /// @notice Emitted when failed CCIP send recovery state is stored
    /// @param ccipTxType The CCIP transaction type to replay
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param amount The amount of underlying asset to bridge
    event CcipSendRecoveryStored(
        Types.CcipTx indexed ccipTxType, uint64 indexed destinationChainSelector, uint256 indexed amount
    );

    /// @notice Emitted when failed CCIP send recovery state is cleared
    /// @param ccipTxType The CCIP transaction type being retried
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param amount The amount of underlying asset to bridge
    event CcipSendRecoveryCleared(
        Types.CcipTx indexed ccipTxType, uint64 indexed destinationChainSelector, uint256 indexed amount
    );

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
    /// @dev Reverts atomically if the CCIP send exceeds the token-pool capacity
    /// @dev Stores CCIP-send recovery for other valid CCIP send-attempt failures
    function executeEpochWithdraw(uint256 epochNonce, uint256 amount) external;

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
    /// @dev Reverts atomically if a remote CCIP send exceeds the token-pool capacity
    /// @dev Stores CCIP-send recovery for other valid remote CCIP send-attempt failures
    function executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the CCIP selector for the parent chain
    /// @return parentChainSelector The CCIP selector for the parent chain
    function getParentChainSelector() external view returns (uint64 parentChainSelector);

    /// @notice Returns the highest epoch nonce handled by this child vault
    /// @return lastHandledEpochNonce The highest handled epoch nonce
    function getLastHandledEpochNonce() external view returns (uint256 lastHandledEpochNonce);

    /// @notice Returns the highest rebalance nonce handled by this child vault
    /// @return lastHandledRebalanceNonce The highest handled rebalance nonce
    function getLastHandledRebalanceNonce() external view returns (uint256 lastHandledRebalanceNonce);

    /// @notice Returns the state and TVL required to determine the next ChildVault operation
    /// @return state The current ChildVault operational state
    function getChildOperationalState() external view returns (Types.ChildOperationalState memory state);

    /// @notice Returns the failed epoch deposit recovery state
    /// @return recovery Types.EpochRecovery struct includes:
    ///         uint256 epochNonce - the nonce of the failed epoch deposit
    ///         uint256 amount - the amount of underlying asset to retry depositing
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Returns the failed epoch withdraw recovery state
    /// @return recovery Types.EpochRecovery struct includes:
    ///         uint256 epochNonce - the nonce of the failed epoch withdrawal
    ///         uint256 amount - the amount of underlying asset to retry withdrawing
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Returns the failed rebalance withdraw recovery state
    /// @return recovery Types.RebalanceWithdrawRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         Types.Strategy strategy - the target strategy to continue the rebalance into after withdrawal succeeds
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery);

    /// @notice Returns the failed CCIP send recovery state
    /// @return recovery Types.CcipSendRecovery struct includes:
    ///         uint256 amount - the amount of underlying asset to bridge
    ///         uint256 nonce - the epoch or rebalance nonce of the failed operation
    ///         bytes32 protocolId - the target protocol ID for a rebalance, otherwise zero
    ///         uint64 destinationChainSelector - the CCIP selector of the destination chain
    ///         Types.CcipTx ccipTxType - the CCIP transaction type to retry
    function getCcipSendRecovery() external view returns (Types.CcipSendRecovery memory recovery);
}
