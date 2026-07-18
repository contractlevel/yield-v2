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
    /// @dev Thrown when an external self-call helper is called by any address other than this contract
    error ChildVault__OnlySelf();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit to the strategy fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that failed to deposit
    event DepositToStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a withdraw from the strategy fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that failed to withdraw
    event WithdrawFromStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a rebalance withdraw from the old strategy fails
    /// @param rebalanceNonce The nonce of the rebalance
    event RebalanceWithdrawFailure(uint256 indexed rebalanceNonce);

    /// @notice Emitted when failed epoch deposit recovery state is stored
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of USDC to retry depositing
    event EpochDepositRecoveryStored(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when failed epoch deposit recovery state is cleared
    /// @param epochNonce The epoch nonce of the recovered deposit
    event EpochDepositRecoveryCleared(uint256 indexed epochNonce);

    /// @notice Emitted when failed epoch withdraw recovery state is stored
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of USDC to retry withdrawing
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
    /// @param amount The amount of USDC to bridge
    event CcipSendRecoveryStored(
        Types.CcipTx indexed ccipTxType, uint64 indexed destinationChainSelector, uint256 indexed amount
    );

    /// @notice Emitted when failed CCIP send recovery state is cleared
    /// @param ccipTxType The CCIP transaction type being retried
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param amount The amount of USDC to bridge
    event CcipSendRecoveryCleared(
        Types.CcipTx indexed ccipTxType, uint64 indexed destinationChainSelector, uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                                  CRE
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the epoch withdraw from a strategy
    /// @dev Called by the WorkflowRouter when net flow is negative
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset to withdraw from the active strategy
    /// @dev Precondition: caller must have the EPOCH_OPERATOR_ROLE
    function executeEpochWithdraw(uint256 epochNonce, uint256 amount) external;

    /// @notice Withdraws the entire TVL from the active strategy adapter and sends it to the new strategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @dev Precondition: caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: there must be no existent recovery mode
    /// @dev Precondition: if the withdraw from the active strategy fails, newStrategy's chain selector must not be zero
    ///      (enforced when storing rebalance withdraw recovery state, so it can be retried later)
    function executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the CCIP selector for the parent chain
    /// @return parentChainSelector The CCIP selector for the parent chain
    function getParentChainSelector() external view returns (uint64 parentChainSelector);

    /// @notice Gets failed epoch deposit recovery state
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Gets failed epoch withdraw recovery state
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Gets failed rebalance withdraw recovery state
    /// @return recovery Types.RebalanceWithdrawRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         Types.Strategy strategy - the target strategy to continue the rebalance into after withdraw succeeds
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery);

    /// @notice Gets failed CCIP send recovery state
    /// @return recovery The stored CCIP send recovery state
    function getCcipSendRecovery() external view returns (Types.CcipSendRecovery memory recovery);
}
