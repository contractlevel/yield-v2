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
    /// @dev Thrown when the ParentVault itself is provided as a beneficiary
    error ParentVault__InvalidBeneficiary();
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
    /// @dev Thrown when closeEpoch is called with no deposits and no withdraw intents
    /// @param epochNonce The nonce for the empty epoch
    error ParentVault__EmptyEpoch(uint256 epochNonce);
    /// @dev Thrown when closeEpoch is called with zero TVL while shares are outstanding
    error ParentVault__ZeroTvlWithOutstandingShares();
    /// @dev Thrown when the scaled TVL-to-share ratio rounds down to zero
    error ParentVault__ZeroPricePerShare();
    /// @dev Thrown when an epoch contains shares to burn while the authoritative share supply is zero
    error ParentVault__ShareBurnWithZeroTotalShares();
    /// @dev Thrown when closeEpoch would settle deposits into too few shares for minimum-size depositors
    error ParentVault__DepositWouldMintZeroShares();
    /// @dev Thrown when the epoch is not executing
    /// @param epochNonce The nonce for the epoch that is not executing
    error ParentVault__EpochNotExecuting(uint256 epochNonce);
    /// @dev Thrown when epoch deposit completion is attempted for an epoch without positive net flow
    /// @param epochNonce The nonce for the epoch that is not a net-deposit epoch
    error ParentVault__EpochNotNetDeposit(uint256 epochNonce);
    /// @dev Thrown when remote-withdraw settlement is attempted for an epoch without negative net flow
    /// @param epochNonce The nonce for the epoch that is not a net-withdraw epoch
    error ParentVault__EpochNotNetWithdraw(uint256 epochNonce);
    /// @dev Thrown when the rebalance is in progress
    error ParentVault__RebalanceInProgress();
    /// @dev Thrown when no rebalance is in progress
    error ParentVault__NoRebalanceInProgress();
    /// @dev Thrown when report-driven completion is attempted for a Parent-local rebalance target
    error ParentVault__CannotCompleteLocalRebalance();
    /// @dev Thrown when a provided epoch nonce does not match the nonce required by the current operation
    /// @param epochNonce The invalid epoch nonce provided by the caller or decoded from a CCIP message
    error ParentVault__InvalidEpochNonce(uint256 epochNonce);
    /// @dev Thrown when a provided rebalance nonce does not match the current rebalance nonce
    /// @param rebalanceNonce The invalid rebalance nonce provided by the caller or decoded from a CCIP message
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
    /// @dev Thrown when the reported destination deposit amount is zero or exceeds the amount sent
    /// @param actualDepositAmount The post-CCIP amount reported by the destination deposit success event
    /// @param expectedDepositAmount The net deposit amount sent by the ParentVault
    error ParentVault__InvalidActualDepositAmount(uint256 actualDepositAmount, uint256 expectedDepositAmount);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev IParentVault remains the canonical vault ABI; linked libraries redeclare matching events only to emit them.
    /// @notice Emitted when a deposit is submitted
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset deposited
    event DepositSubmitted(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw intent is submitted
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares escrowed for burning when the withdraw is claimed
    event WithdrawSubmitted(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param depositor The address of the depositor
    /// @param shareMintAmount The amount of Yieldcoin shares minted
    event DepositClaimed(uint256 indexed epochNonce, address indexed depositor, uint256 indexed shareMintAmount);
    /// @notice Emitted when a withdraw is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param withdrawer The address of the withdrawer
    /// @param amount The amount of underlying asset withdrawn
    event WithdrawClaimed(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when an epoch is open
    /// @param epochNonce The nonce of the open epoch
    event EpochOpen(uint256 indexed epochNonce);
    /// @notice Emitted when a remote net-deposit epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of underlying asset being deposited on the remote strategy chain
    event EpochDepositExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a remote net-withdraw epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of underlying asset that needs to be withdrawn
    event EpochWithdrawExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a remote withdrawal shortfall is forfeited instead of sent cross-chain
    /// @param epochNonce The nonce of the settled epoch
    /// @param amount The remote withdrawal shortfall retained in the remote strategy
    event RemoteWithdrawDustForfeited(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);
    /// @notice Emitted when a remote epoch deposit is reconciled against the amount delivered by CCIP
    /// @param epochNonce The nonce of the reconciled epoch
    /// @param actualDepositAmount The post-CCIP amount accepted by the destination deposit path
    /// @param shareReduction The nominal pending shares removed because of the delivery shortfall
    event EpochDepositReconciled(
        uint256 indexed epochNonce, uint256 indexed actualDepositAmount, uint256 indexed shareReduction
    );
    /// @notice Emitted when a CCIP withdrawal message delivers less underlying asset than expected
    /// @param epochNonce The nonce of the epoch with the short withdrawal
    /// @param expectedAmount The amount of underlying asset expected from the remote strategy
    /// @param actualAmount The amount of underlying asset delivered by the CCIP message
    event EpochWithdrawAmountShort(
        uint256 indexed epochNonce, uint256 indexed expectedAmount, uint256 indexed actualAmount
    );
    /// @notice Emitted when a rebalance is initiated
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param protocolId The target strategy protocol ID
    /// @param chainSelector The target strategy chain selector
    event RebalanceInitiated(uint256 indexed rebalanceNonce, bytes32 indexed protocolId, uint64 indexed chainSelector);
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
    /// @notice Emitted when a deposit is cancelled
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset refunded
    event DepositCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw intent is cancelled
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares that were intended to burn to redeem the underlying asset
    event WithdrawCancelled(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is force-cancelled by the cancel deposit operator
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset refunded
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
    /// @dev Must be called once after the adapter is deployed and registered, before operational use
    /// @dev Reverts if the caller does not have DEFAULT_ADMIN_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the initial active protocol adapter has already been set
    /// @dev Reverts if protocolId does not have a registered adapter
    /// @dev Reverts if the registered adapter is bound to another vault
    /// @dev Sets the active strategy to protocolId on this chain
    function setInitialActiveProtocolAdapter(bytes32 protocolId) external;

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if treasury is the zero address
    function setTreasury(address treasury) external;

    /// @notice Sets whether a protocol is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to configure
    /// @param isSupported Whether the protocol is supported
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if protocolId is zero
    /// @dev When removing support, reverts if protocolId belongs to the active strategy
    /// @dev When removing support, reverts if protocolId belongs to the pending strategy
    function setSupportedProtocol(bytes32 protocolId, bool isSupported) external;

    /// @notice Force-cancels a user's deposit in the current open epoch, refunding their exact deposited amount
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev Reverts if the caller does not have CANCEL_DEPOSIT_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deliberately callable while paused
    function forceCancelDeposit(address user) external;

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the vault
    /// @param amount The amount of underlying asset to deposit
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Reverts if amount is less than the minimum deposit amount
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires the caller to have sufficient underlying-asset balance and allowance for amount
    function deposit(uint256 amount) external returns (uint256 epochNonce);

    /// @notice Deposits the caller's underlying asset for a beneficiary
    /// @param beneficiary The user that owns the resulting epoch deposit position
    /// @param amount The amount of underlying asset to deposit
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Reverts if beneficiary is the zero address
    /// @dev Reverts if beneficiary is this ParentVault
    /// @dev Reverts if amount is less than the minimum deposit amount
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires the caller to have sufficient underlying-asset balance and allowance for amount
    /// @dev The beneficiary, not the caller, owns the epoch position and any cancellation refund
    function depositFor(address beneficiary, uint256 amount) external returns (uint256 epochNonce);

    /// @notice Submits a withdraw intent by escrowing shares in the current epoch
    /// @param shareBurnAmount The amount of shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The nonce of the epoch containing the withdraw intent
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires the caller to have sufficient share balance and allowance for shareBurnAmount
    function withdraw(uint256 shareBurnAmount) external returns (uint256 epochNonce);

    /// @notice Submits a withdraw intent for a beneficiary by escrowing the caller's shares
    /// @param beneficiary The user that owns the resulting epoch withdraw position
    /// @param shareBurnAmount The amount of caller shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The nonce of the epoch containing the withdraw intent
    /// @dev Reverts if beneficiary is the zero address
    /// @dev Reverts if beneficiary is this ParentVault
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires the caller to have sufficient share balance and allowance for shareBurnAmount
    /// @dev The beneficiary, not the caller, owns the epoch position and any cancellation refund
    function withdrawFor(address beneficiary, uint256 shareBurnAmount) external returns (uint256 epochNonce);

    /// @notice Claims the shares allocated to the caller's deposit in a settled epoch
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if the caller has no deposit in the epoch
    function claimShares(uint256 epochNonce) external returns (uint256 shareMintAmount);

    /// @notice Claims the shares allocated to a user's deposit in a settled epoch
    /// @param user The depositor whose position is claimed and that receives the minted shares
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted to user
    /// @dev Reverts if user is the zero address
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no deposit in the epoch
    /// @dev Anyone may call this function, but the minted shares are always sent to user
    function claimSharesFor(address user, uint256 epochNonce) external returns (uint256 shareMintAmount);

    /// @notice Claims the underlying asset for a completed epoch withdraw
    /// @param epochNonce The nonce of the epoch to claim from
    /// @return withdrawAmount The amount of underlying asset transferred to the withdrawer
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if the caller has no withdraw intent in the epoch
    function claimAsset(uint256 epochNonce) external returns (uint256 withdrawAmount);

    /// @notice Claims the underlying asset allocated to a user's withdraw intent in a settled epoch
    /// @param user The withdrawer whose position is claimed and that receives the underlying asset
    /// @param epochNonce The nonce of the epoch to claim from
    /// @return withdrawAmount The amount of underlying asset transferred to user
    /// @dev Reverts if user is the zero address
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no withdraw intent in the epoch
    /// @dev Anyone may call this function, but the underlying asset is always sent to user
    function claimAssetFor(address user, uint256 epochNonce) external returns (uint256 withdrawAmount);

    /// @notice Cancels and refunds the caller's deposit in the current open epoch
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if the caller has no deposit in the current epoch
    function cancelDeposit() external;

    /// @notice Cancels the caller's withdraw intent in the current open epoch and returns the escrowed shares
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if the caller has no withdraw intent in the current epoch
    function cancelWithdraw() external;

    /*//////////////////////////////////////////////////////////////
                              OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Settles the current epoch, executes its net asset flow, and opens the next epoch
    /// @param expectedEpochNonce The current epoch nonce the call is intended to close
    /// @param tvl The underlying-asset value of the active strategy before settling the current epoch
    /// @dev Reverts if expectedEpochNonce does not match the current epoch nonce
    /// @dev Called by the WorkflowRouter
    /// @dev Net flow is the total deposited underlying asset minus the total underlying asset owed for withdraw claims
    /// @dev A zero net flow makes the epoch claimable without moving assets
    /// @dev A positive net flow is deposited locally or sent by CCIP to the remote active strategy; a remote epoch
    ///      remains executing until completeEpochDeposit is called after the ChildVault confirms the deposit
    /// @dev A negative net flow is withdrawn locally and made claimable, or remains executing while CRE triggers
    ///      the remote strategy withdrawal and return transfer
    /// @dev The caller-supplied TVL is trusted and is not validated against onchain strategy state
    /// @dev An incorrect tvl irreversibly corrupts epoch share accounting once a user claims from the affected epoch
    /// @dev Reverts if the caller does not have EPOCH_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if a rebalance is in progress
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if the preceding epoch is still executing
    /// @dev Reverts if the current epoch has been open for less than MIN_EPOCH_PERIOD
    /// @dev Reverts if the epoch contains neither deposits nor withdraw intents
    /// @dev Reverts if tvl is zero while shares are outstanding
    /// @dev Reverts if the scaled TVL-to-share ratio rounds down to zero
    /// @dev Reverts if shares are submitted for withdrawal while the authoritative share supply is zero
    /// @dev Reverts if deposit settlement would allocate zero shares to a minimum-size deposit
    /// @dev Reverts if the epoch's total deposit or total withdraw amount cannot be safely cast to int256
    /// @dev Requires any local strategy or CCIP interaction selected by the net-flow branch to succeed
    /// @dev The preceding-epoch guard prevents claims and strategy changes while a remote epoch remains executing
    /// @dev If a remote strategy withdrawal fails, users cannot claim until recovery succeeds on the ChildVault
    /// @dev An epoch nonce of one has no preceding epoch because initialization opens epoch one
    /// @dev Zero TVL with outstanding shares requires restoring TVL through an on-behalf-of strategy supply before
    ///      settlement can continue; the permanent admin seed deposit means this requires a full strategy loss
    /// @dev See KI-008 and KI-010 in docs/security/KNOWN_ISSUES.md
    function closeEpoch(uint256 expectedEpochNonce, uint256 tvl) external;

    /// @notice Completes the most recently closed remote net-deposit epoch
    /// @param expectedEpochNonce The completed epoch nonce the call is intended to finalize
    /// @param actualDepositAmount The post-CCIP amount emitted by the destination deposit success event
    /// @dev Reverts if expectedEpochNonce does not match the most recently closed epoch nonce
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the caller does not have EPOCH_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the previous epoch is not an executing net-deposit epoch
    /// @dev Reverts if actualDepositAmount is zero or exceeds the expected net deposit amount
    /// @dev Reverts if reconciliation would reduce the epoch's pending share allocation to zero
    function completeEpochDeposit(uint256 expectedEpochNonce, uint256 actualDepositAmount) external;

    /// @notice Initiates a rebalance from the current strategy to a new strategy
    /// @param expectedRebalanceNonce The current rebalance nonce the call is intended to initiate
    /// @param newStrategy The new strategy to rebalance to
    /// @dev Reverts if expectedRebalanceNonce does not match the current rebalance nonce
    /// @dev Reverts if the caller does not have REBALANCE_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if a rebalance is already in progress
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if no epoch has completed
    /// @dev Reverts if MIN_REBALANCE_PERIOD has not elapsed since the last completed rebalance
    /// @dev Reverts if newStrategy matches the active strategy
    /// @dev Reverts if the preceding epoch is still executing
    /// @dev Reverts if newStrategy.chainSelector is not the local chain or a registered crosschain vault's chain
    /// @dev Reverts if newStrategy.protocolId is not supported
    /// @dev If the active strategy is local, reverts if its withdrawal returns zero assets
    /// @dev If the new strategy is local, reverts if its protocol has no registered adapter
    /// @dev If the new strategy is local, reverts if the registered adapter is bound to another vault
    /// @dev Requires any local strategy or CCIP interaction selected by the rebalance branch to succeed
    function initiateRebalance(uint256 expectedRebalanceNonce, Types.Strategy memory newStrategy) external;

    /// @notice Completes a rebalance
    /// @param expectedRebalanceNonce The current rebalance nonce the call is intended to finalize
    /// @dev Reverts if expectedRebalanceNonce does not match the current rebalance nonce
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the caller does not have REBALANCE_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if no rebalance is in progress
    function completeRebalance(uint256 expectedRebalanceNonce) external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether the initial active protocol adapter has been set
    /// @return initialActiveProtocolAdapterSet Whether the initial active protocol adapter has been set
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet);

    /// @notice Returns the share precision factor (fixed at SHARE_PRECISION)
    /// @return sharePrecision The share precision factor
    function getSharePrecision() external pure returns (uint256 sharePrecision);

    /// @notice Returns the minimum deposit amount
    /// @return minAssetAmount The minimum asset amount, equal to 1 * i_assetPrecision
    function getMinAssetAmount() external view returns (uint256 minAssetAmount);

    /// @notice Returns the remote-withdraw dust threshold
    /// @return threshold One hundredth of a whole underlying asset unit
    function getRemoteWithdrawDustThreshold() external view returns (uint256 threshold);

    /// @notice Returns whether a protocol ID is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to query
    /// @return isSupported Whether the protocol ID is supported
    function getSupportedProtocol(bytes32 protocolId) external view returns (bool isSupported);

    /// @notice Returns the rebalance state
    /// @return rebalance The current rebalance state
    function getRebalance() external view returns (Types.Rebalance memory rebalance);

    /// @notice Returns the state and TVL required to determine the next ParentVault operation
    /// @return state The current ParentVault operational state
    function getParentOperationalState() external view returns (Types.ParentOperationalState memory state);

    /// @notice Returns the epoch data for a given epoch nonce
    /// @param epochNonce The epoch nonce to query
    /// @return epoch Types.Epoch struct includes:
    ///         uint256 totalDepositAmount - the total underlying asset deposited in the epoch
    ///         uint256 totalShareBurnAmount - the total shares submitted for withdraw in the epoch
    ///         uint256 totalWithdrawClaimAmount - the total underlying asset allocated to epoch withdraw claims
    ///         uint256 remainingDepositClaimAmount - the unclaimed underlying asset attributed to deposits
    ///         uint256 remainingShareMintAmount - the shares remaining to mint for deposits
    ///         uint256 remainingShareBurnAmount - the escrowed shares remaining to burn for withdraw claims
    ///         uint256 remainingWithdrawClaimAmount - the underlying asset remaining to claim for withdraw claims
    ///         uint256 openedAtTimestamp - the timestamp when the epoch opened
    ///         Types.EpochStatus status - the epoch status
    function getEpoch(uint256 epochNonce) external view returns (Types.Epoch memory epoch);

    /// @notice Returns the current epoch nonce
    /// @return epochNonce The nonce of the currently active epoch
    function getEpochNonce() external view returns (uint256 epochNonce);

    /// @notice Returns the total number of Yieldcoin shares tracked by the vault
    /// @return totalShares The total share count tracked by the vault
    /// @dev Updated at epoch settlement before the corresponding shares are minted or burned at claim time, so it
    ///      may be higher or lower than the share token's totalSupply() while claims remain pending
    function getTotalShares() external view returns (uint256 totalShares);

    /// @notice Returns the underlying-asset deposit amount submitted by a user for a given epoch
    /// @param user The address of the depositor
    /// @param epochNonce The epoch nonce of the deposit
    /// @return amount The underlying-asset amount the user deposited into the given epoch
    function getDepositAmount(address user, uint256 epochNonce) external view returns (uint256 amount);

    /// @notice Returns the share amount escrowed by a user for an epoch withdraw intent
    /// @param user The address of the withdrawer
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @return shareBurnAmount The shares escrowed for burning when the withdraw is claimed
    function getWithdrawShareBurnAmount(address user, uint256 epochNonce)
        external
        view
        returns (uint256 shareBurnAmount);

    /// @notice Returns the operator multisig that receives protocol fees
    /// @return treasury The address of the operator multisig for protocol fees
    function getTreasury() external view returns (address treasury);

    /// @notice Returns the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share);
}
