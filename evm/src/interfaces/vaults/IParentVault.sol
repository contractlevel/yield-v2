// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IBaseVault} from "./IBaseVault.sol";
import {Types} from "../../libraries/Types.sol";

/// @title Yieldcoin v2 ParentVault Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 ParentVault
interface IParentVault is IBaseVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the amount is zero
    error ParentVault__NoZeroAmount();
    /// @dev Thrown when the zero protocol ID is provided
    error ParentVault__NoZeroProtocolId();
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
    /// @dev Thrown when the price per share rounds down to zero (near-total loss with a large outstanding share supply)
    error ParentVault__ZeroPricePerShare();
    /// @dev Thrown when closeEpoch would settle deposits into too few shares for minimum-size depositors
    error ParentVault__DepositWouldMintZeroShares();
    /// @dev Thrown when the epoch is not executing
    /// @param epochNonce The nonce for the epoch that is not executing
    error ParentVault__EpochNotExecuting(uint256 epochNonce);
    /// @dev Thrown when the rebalance is in progress
    error ParentVault__RebalanceInProgress();
    /// @dev Thrown when no rebalance is in progress
    error ParentVault__NoRebalanceInProgress();
    /// @dev Thrown when the decoded epoch nonce does not match s_epochNonce - 1
    /// @param epochNonce The decoded epoch nonce from the CCIP message
    error ParentVault__InvalidEpochNonce(uint256 epochNonce);
    /// @dev Thrown when the decoded rebalance nonce does not match s_rebalance.nonce
    /// @param rebalanceNonce The decoded rebalance nonce from the CCIP message
    error ParentVault__InvalidRebalanceNonce(uint256 rebalanceNonce);
    /// @dev Thrown when the decoded protocol ID does not match s_rebalance.pendingStrategy.protocolId
    /// @param protocolId The decoded protocol ID from the CCIP message
    error ParentVault__InvalidPendingProtocolId(bytes32 protocolId);
    /// @dev Thrown when initiateRebalance is called before any epoch has completed
    error ParentVault__NoCompletedEpoch();
    /// @dev Thrown when initiateRebalance is called before MIN_REBALANCE_PERIOD has elapsed since the last rebalance completed
    /// @param rebalanceNonce The nonce of the rebalance that was attempted too soon
    error ParentVault__RebalanceTooSoon(uint256 rebalanceNonce);
    /// @dev Thrown when the new strategy matches the active strategy
    error ParentVault__SameStrategy();
    /// @dev Thrown when a prior epoch is still executing
    /// @param epochNonce The nonce of the executing epoch
    error ParentVault__EpochExecuting(uint256 epochNonce);
    /// @dev Thrown when the initial active protocol adapter has already been set
    error ParentVault__InitialActiveProtocolAdapterAlreadySet();
    /// @dev Thrown when initiateRebalance is called with an unsupported chain selector
    /// @param chainSelector The unsupported chain selector
    error ParentVault__InvalidChainSelector(uint64 chainSelector);
    /// @dev Thrown when initiateRebalance is called with an unsupported protocol ID
    /// @param protocolId The unsupported protocol ID
    error ParentVault__InvalidProtocolId(bytes32 protocolId);
    /// @dev Thrown when attempting to remove support for the active strategy protocol
    /// @param protocolId The active protocol ID
    error ParentVault__CannotRemoveActiveProtocol(bytes32 protocolId);
    /// @dev Thrown when attempting to remove support for the pending strategy protocol
    /// @param protocolId The pending protocol ID
    error ParentVault__CannotRemovePendingProtocol(bytes32 protocolId);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev IParentVault remains the canonical vault ABI; linked libraries redeclare matching events only to emit them.
    /// @notice Emitted when a deposit is made
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset deposited
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
    /// @param amount The amount of asset withdrawn
    event WithdrawClaimed(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when an epoch is open
    /// @param epochNonce The nonce of the open epoch
    event EpochOpen(uint256 indexed epochNonce);
    /// @notice Emitted when an epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of asset that needs to be withdrawn
    event EpochExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);
    /// @notice Emitted when a CCIP withdraw message delivers less asset than expected
    /// @param epochNonce The nonce of the epoch with the short withdrawal
    /// @param expectedAmount The amount of asset expected from the remote strategy
    /// @param actualAmount The amount of asset delivered by the CCIP message
    event EpochWithdrawAmountShort(
        uint256 indexed epochNonce, uint256 indexed expectedAmount, uint256 indexed actualAmount
    );
    /// @notice Emitted when a rebalance is initiated
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param chainSelector The target strategy chain selector
    /// @param protocolId The target strategy protocol ID
    event RebalanceInitiated(uint256 indexed rebalanceNonce, uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when a rebalance is completed
    /// @param rebalanceNonce The nonce of the completed rebalance
    /// @param newProtocolId The protocol ID for the new strategy
    /// @param newChainSelector The chain selector for the new strategy
    event RebalanceCompleted(
        uint256 indexed rebalanceNonce, bytes32 indexed newProtocolId, uint64 indexed newChainSelector
    );
    /// @notice Emitted when management fees are collected
    /// @param rebalanceNonce The nonce of the rebalance that collected the fee
    /// @param feeShares The number of shares minted to the treasury
    event ManagementFeeCollected(uint256 indexed rebalanceNonce, uint256 indexed feeShares);
    /// @notice Emitted when performance fees are collected
    /// @param epochNonce The epoch nonce that collected the fee
    /// @param feeShares The number of shares minted to the treasury
    /// @param settlementPricePerShare The price per share after fee-share dilution. This raises the high water
    ///        mark, except when rounding causes it to land a dust amount below the existing high water mark -
    ///        the high water mark is only ever raised, never lowered, so it may not equal this value
    event PerformanceFeeCollected(
        uint256 indexed epochNonce, uint256 indexed feeShares, uint256 indexed settlementPricePerShare
    );
    /// @notice Emitted when a deposit is cancelled
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset that was cancelled
    event DepositCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw is cancelled
    /// @param epochNonce The epoch nonce of the withdraw
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares that were intended to burn to redeem the underlying asset
    event WithdrawCancelled(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is force-cancelled by the cancel deposit operator
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset that was cancelled
    event DepositForceCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when the initial active protocol adapter is set
    /// @param protocolId The protocol ID of the initial active strategy
    /// @param adapter The registered adapter for the protocol ID
    event InitialActiveProtocolAdapterSet(bytes32 indexed protocolId, address indexed adapter);

    /// @notice Emitted when the treasury address is set
    /// @param treasury The address of the treasury
    event TreasurySet(address indexed treasury);
    /// @notice Emitted when a protocol's supported (on any chain) status is set
    /// @param protocolId The protocol ID of the protocol whose support status has been set
    /// @param isSupported True if supported on any chain, false if not
    event SupportedProtocolSet(bytes32 indexed protocolId, bool indexed isSupported);

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

    /// @notice Sets whether a protocol is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to configure
    /// @param isSupported Whether the protocol is supported
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: protocolId must not be zero
    /// @dev Precondition: if isSupported is false, protocolId must not be the active or pending strategy's protocol ID
    function setSupportedProtocol(bytes32 protocolId, bool isSupported) external;

    /// @notice Force-cancels a user's deposit in the current open epoch, refunding their exact deposited amount
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev Precondition: Caller must have the CANCEL_DEPOSIT_OPERATOR_ROLE
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must have a deposit for the current epoch
    function forceCancelDeposit(address user) external;

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the vault
    /// @param amount The amount of asset to deposit
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Precondition: amount must meet the minimum deposit amount requirement
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    function deposit(uint256 amount) external returns (uint256 epochNonce);

    /// @notice Submit USDC withdraw intent
    /// @param shareBurnAmount The amount of shares to burn for the withdraw
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their shareBurnAmount
    function withdraw(uint256 shareBurnAmount) external returns (uint256 epochNonce);

    /// @notice Claim Yieldcoin shares after a deposit
    /// @dev Finalizes an individual deposit
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function claimShares(uint256 epochNonce) external returns (uint256 shareMintAmount);

    /// @notice Claims the underlying asset for a completed epoch withdrawal
    /// @dev Finalizes an individual withdraw
    /// @param epochNonce The nonce of the epoch to claim from
    /// @return withdrawAmount The amount of asset transferred to the withdrawer
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function claimAsset(uint256 epochNonce) external returns (uint256 withdrawAmount);

    /// @notice Cancels a deposit
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function cancelDeposit() external;

    /// @notice Cancels a withdraw
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function cancelWithdraw() external;

    /*//////////////////////////////////////////////////////////////
                              OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Closes an epoch and handles the net flow
    /// @dev Opens the next epoch
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @dev Precondition: caller must have the EPOCH_OPERATOR_ROLE
    /// @dev Precondition: there must not be an active rebalance
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: the epoch must be open
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: the epoch must have been open for at least MIN_EPOCH_PERIOD
    /// @dev Precondition: the epoch must not have zero deposits and zero withdrawals
    /// @dev Precondition: tvl must not be zero while shares are outstanding
    /// @dev Precondition: the resulting price per share must not round down to zero
    /// @dev Precondition: settlement must not mint zero shares for a minimum-size depositor
    function closeEpoch(uint256 tvl) external;

    /// @notice Initiates a rebalance from the current strategy to a new strategy
    /// @param newStrategy The new strategy to rebalance to
    /// @dev Precondition: caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: a rebalance must not already be in progress
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: at least one epoch must have completed
    /// @dev Precondition: newStrategy must differ from the current active strategy
    /// @dev Precondition: no prior epoch may still be executing
    /// @dev Precondition: newStrategy's chain selector must be supported
    /// @dev Precondition: newStrategy's protocol ID must be supported
    function initiateRebalance(Types.Strategy memory newStrategy) external;

    /// @notice Completes a rebalance
    /// @dev Precondition: caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: a rebalance must be in progress
    function completeRebalance() external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether the initial active protocol adapter has been set
    /// @return initialActiveProtocolAdapterSet Whether the initial active protocol adapter has been set
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet);

    /// @notice Returns the performance fee high water mark
    /// @return highWaterMark The highest price per share recorded for performance fee purposes
    function getPerformanceFeeHighWaterMark() external view returns (uint256 highWaterMark);

    /// @notice Returns the share precision factor (WAD_PRECISION / i_assetPrecision)
    /// @return sharePrecision The share precision factor
    function getSharePrecision() external view returns (uint256 sharePrecision);

    /// @notice Returns the minimum deposit amount (1 * i_assetPrecision)
    /// @return minDepositAmount The minimum deposit amount
    function getMinDepositAmount() external view returns (uint256 minDepositAmount);

    /// @notice Returns whether a protocol ID is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to query
    /// @return isSupported Whether the protocol ID is supported
    function getSupportedProtocol(bytes32 protocolId) external view returns (bool isSupported);

    /// @notice Returns the rebalance state
    /// @return rebalance The current rebalance state
    function getRebalance() external view returns (Types.Rebalance memory rebalance);

    /// @notice Returns the epoch data for a given epoch nonce
    /// @param epochNonce The epoch nonce to query
    /// @return epoch The epoch data including status, deposit/withdraw totals, price per share, and opened timestamp
    function getEpoch(uint256 epochNonce) external view returns (Types.Epoch memory epoch);

    /// @notice Returns the current epoch nonce
    /// @return epochNonce The nonce of the currently active epoch
    function getEpochNonce() external view returns (uint256 epochNonce);

    /// @notice Returns the total number of Yieldcoin shares tracked by the vault
    /// @return totalShares The total share count tracked by the vault
    function getTotalShares() external view returns (uint256 totalShares);

    /// @notice Returns the asset deposit amount submitted by a user for a given epoch
    /// @param user The address of the depositor
    /// @param epochNonce The epoch nonce of the deposit
    /// @return amount The asset amount the user deposited into the given epoch
    function getDepositAmount(address user, uint256 epochNonce) external view returns (uint256 amount);

    /// @notice Returns the share burn amount submitted by a user for a given epoch withdraw intent
    /// @param user The address of the withdrawer
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @return shareBurnAmount The number of Yieldcoin shares the user submitted for burning in the given epoch
    function getWithdrawShareBurnAmount(address user, uint256 epochNonce)
        external
        view
        returns (uint256 shareBurnAmount);

    /// @notice Gets the operator multisig for protocol fees
    /// @return treasury The address of the operator multisig for protocol fees
    function getTreasury() external view returns (address treasury);

    /// @notice Gets the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share);
}
