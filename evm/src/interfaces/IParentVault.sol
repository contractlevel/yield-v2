// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IBaseVault} from "./IBaseVault.sol";

/// @title Yieldcoin v2 ParentVault Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 ParentVault
interface IParentVault is IBaseVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the amount is zero
    error ParentVault__NoZeroAmount();
    /// @dev Thrown when the deposit amount is less than the minimum deposit amount
    /// @param amount The amount of the deposit
    error ParentVault__AmountTooSmall(uint256 amount);
    /// @dev Thrown when the epoch is not open
    /// @param epochNonce The nonce for the epoch that is not open
    error ParentVault__EpochNotOpen(uint256 epochNonce);
    /// @dev Thrown when the epoch is not claimable
    /// @param epochNonce The nonce for the epoch that is not claimable
    error ParentVault__EpochNotClaimable(uint256 epochNonce);
    /// @dev Thrown when the user has no deposit for the epoch nonce
    /// @param depositor The address of the depositor
    /// @param epochNonce The nonce for the epoch that the depositor has no deposit for
    error ParentVault__NoDeposit(address depositor, uint256 epochNonce);
    /// @dev Thrown when the user has no withdraw intent for the epoch nonce
    /// @param withdrawer The address of the withdrawer
    /// @param epochNonce The nonce for the epoch that the withdrawer has no withdraw intent for
    error ParentVault__NoWithdraw(address withdrawer, uint256 epochNonce);
    /// @dev Thrown when the epoch is too short
    /// @param epochNonce The nonce for the epoch that is too short
    error ParentVault__EpochTooShort(uint256 epochNonce);
    /// @dev Thrown when closeEpoch is called with no deposits and no withdrawals
    /// @param epochNonce The nonce for the empty epoch
    error ParentVault__EmptyEpoch(uint256 epochNonce);
    /// @dev Thrown when closeEpoch is called with zero TVL while shares are outstanding
    error ParentVault__ZeroTvlWithOutstandingShares();
    /// @dev Thrown when the epoch is not executing
    /// @param epochNonce The nonce for the epoch that is not executing
    error ParentVault__EpochNotExecuting(uint256 epochNonce);
    /// @dev Thrown when the rebalance is in progress
    error ParentVault__RebalanceInProgress();
    /// @dev Thrown when no rebalance is in progress
    error ParentVault__NoRebalanceInProgress();
    /// @dev Thrown when initiateRebalance is called before any epoch has completed
    error ParentVault__NoCompletedEpoch();
    /// @dev Thrown when the new strategy matches the active strategy
    error ParentVault__SameStrategy();
    /// @dev Thrown when a prior epoch is still executing
    /// @param epochNonce The nonce of the executing epoch
    error ParentVault__EpochExecuting(uint256 epochNonce);
    /// @dev Thrown when the initial active protocol adapter has already been set
    error ParentVault__InitialActiveProtocolAdapterAlreadySet();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit is made
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of USDC deposited
    event DepositSubmitted(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw is made
    /// @param epochNonce The epoch nonce of the withdraw
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares burned
    event WithdrawSubmitted(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param depositor The address of the depositor
    /// @param shareMintAmount The amount of Yieldcoin shares minted
    event DepositClaimed(uint256 indexed epochNonce, address indexed depositor, uint256 indexed shareMintAmount);
    /// @notice Emitted when a withdraw is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param withdrawer The address of the withdrawer
    /// @param amount The amount of USDC withdrawn
    event WithdrawClaimed(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when an epoch is open
    /// @param epochNonce The nonce of the open epoch
    event EpochOpen(uint256 indexed epochNonce);
    /// @notice Emitted when an epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of USDC that needs to be withdrawn
    event EpochExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);
    /// @notice Emitted when a CCIP withdraw message delivers less USDC than expected
    /// @param epochNonce The nonce of the epoch with the short withdrawal
    /// @param expectedAmount The amount of USDC expected from the remote strategy
    /// @param actualAmount The amount of USDC delivered by the CCIP message
    event EpochWithdrawAmountShort(uint256 indexed epochNonce, uint256 expectedAmount, uint256 actualAmount);
    /// @notice Emitted when a rebalance is initiated
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param chainSelector The target strategy chain selector
    /// @param protocolId The target strategy protocol ID
    event RebalanceInitiated(uint256 indexed rebalanceNonce, uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when a rebalance is completed
    /// @param rebalanceNonce The nonce of the completed rebalance
    event RebalanceCompleted(uint256 indexed rebalanceNonce);
    /// @notice Emitted when management fees are collected
    /// @param rebalanceNonce The nonce of the rebalance that collected the fee
    /// @param feeShares The number of shares minted to the treasury
    event ManagementFeeCollected(uint256 indexed rebalanceNonce, uint256 indexed feeShares);
    /// @notice Emitted when performance fees are collected
    /// @param epochNonce The epoch nonce that collected the fee
    /// @param feeShares The number of shares minted to the treasury
    /// @param highWaterMark The prior performance fee high water mark
    event PerformanceFeeCollected(uint256 indexed epochNonce, uint256 indexed feeShares, uint256 indexed highWaterMark);
    /// @notice Emitted when a deposit is cancelled
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of USDC that was cancelled
    event DepositCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw is cancelled
    /// @param epochNonce The epoch nonce of the withdraw
    /// @param withdrawer The address of the withdrawer
    /// @param amount The amount of USDC that was cancelled
    event WithdrawCancelled(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when the initial active protocol adapter is set
    /// @param protocolId The protocol ID of the initial active strategy
    /// @param adapter The registered adapter for the protocol ID
    event InitialActiveProtocolAdapterSet(bytes32 indexed protocolId, address indexed adapter);

    /// @notice Emitted when the treasury address is set
    /// @param treasury The address of the treasury
    event TreasurySet(address indexed treasury);

    /*//////////////////////////////////////////////////////////////
                              SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the initial active protocol adapter after deployment
    /// @param protocolId The protocol ID of the initial active strategy
    /// @dev This must be called once after the adapter is deployed and registered, before operational use.
    /// @dev Precondition: caller must have the DEFAULT_ADMIN_ROLE
    /// @dev Precondition: the initial active protocol adapter must not already be set
    /// @dev Precondition: the protocol ID must have a registered adapter
    function setInitialActiveProtocolAdapter(bytes32 protocolId) external;

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    function setTreasury(address treasury) external;

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovers a failed rebalance deposit into the active Parent strategy
    /// @dev Precondition: rebalance deposit recovery state must exist
    function recoverFailedRebalanceDeposit() external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether the initial active protocol adapter has been set
    /// @return initialActiveProtocolAdapterSet Whether the initial active protocol adapter has been set
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet);

    /// @notice Returns the performance fee high water mark
    /// @return highWaterMark The highest price per share recorded for performance fee purposes
    function getPerformanceFeeHighWaterMark() external view returns (uint256 highWaterMark);
}
