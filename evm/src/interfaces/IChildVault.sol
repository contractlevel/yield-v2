// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IBaseVault} from "./IBaseVault.sol";
import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 ChildVault Interface
/// @author @contractlevel
/// @notice Interface for Child-only Yieldcoin v2 vault behavior
interface IChildVault is IBaseVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when a recovery strategy is invalid
    error ChildVault__InvalidRecoveryStrategy();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
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
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovers a failed epoch deposit into the active Child strategy
    /// @dev Precondition: epoch deposit recovery state must exist
    function recoverFailedEpochDeposit() external;

    /// @notice Recovers a failed epoch withdraw from the active Child strategy
    /// @dev Precondition: epoch withdraw recovery state must exist
    function recoverFailedEpochWithdraw() external;

    /// @notice Recovers a failed rebalance withdraw from the active Child strategy
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function recoverFailedRebalanceWithdraw() external;

    /// @notice Recovers a failed rebalance deposit into the active Child strategy
    /// @dev Precondition: rebalance deposit recovery state must exist
    function recoverFailedRebalanceDeposit() external;

    /// @notice Retries a failed ChildVault CCIP send
    /// @dev Precondition: CCIP send recovery state must exist
    function recoverFailedCcipSend() external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets failed epoch deposit recovery state
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Gets failed epoch withdraw recovery state
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery);

    /// @notice Gets failed rebalance withdraw recovery state
    /// @return recovery Types.RebalanceWithdrawRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         uint256 amount - the amount that needs to be rebalanced/withdraw from the old strategy
    ///         uint256 createdAt - block.timestamp the recovery state was stored
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery);

    /// @notice Gets failed CCIP send recovery state
    /// @return recovery The stored CCIP send recovery state
    function getCcipSendRecovery() external view returns (Types.CcipSendRecovery memory recovery);
}
