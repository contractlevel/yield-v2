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

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovers a failed epoch deposit into the active Child strategy
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @dev Precondition: epoch deposit recovery state must exist
    function recoverFailedEpochDeposit(uint256 epochNonce) external;

    /// @notice Recovers a failed epoch withdraw from the active Child strategy
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @dev Precondition: epoch withdraw recovery state must exist
    function recoverFailedEpochWithdraw(uint256 epochNonce) external;

    /// @notice Recovers a failed rebalance withdraw from the active Child strategy
    /// @param rebalanceNonce The nonce of the failed rebalance withdraw
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function recoverFailedRebalanceWithdraw(uint256 rebalanceNonce) external;

    /// @notice Recovers a failed rebalance deposit into the active Child strategy
    /// @param rebalanceNonce The nonce of the failed rebalance deposit
    /// @dev Precondition: rebalance deposit recovery state must exist
    function recoverFailedRebalanceDeposit(uint256 rebalanceNonce) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets failed epoch deposit recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery(uint256 epochNonce) external view returns (Types.AmountRecovery memory recovery);

    /// @notice Gets failed epoch withdraw recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery(uint256 epochNonce) external view returns (Types.AmountRecovery memory recovery);

    /// @notice Gets failed rebalance withdraw recovery state
    /// @param rebalanceNonce The rebalance nonce to query
    /// @return recovery The stored rebalance withdraw recovery state
    function getRebalanceWithdrawRecovery(uint256 rebalanceNonce)
        external
        view
        returns (Types.RebalanceWithdrawRecovery memory recovery);
}
