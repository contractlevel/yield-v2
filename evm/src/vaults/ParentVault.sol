// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVault} from "./BaseVault.sol";
import {ParentVaultStore} from "./ParentVaultStore.sol";
import {IBaseVault} from "../interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../interfaces/vaults/IParentVault.sol";
import {Types} from "../libraries/Types.sol";
import {Roles} from "../libraries/Roles.sol";
import {BaseVaultCcipLib} from "../libraries/vaults/BaseVaultCcipLib.sol";
import {ParentVaultCcipLib} from "../libraries/vaults/ParentVaultCcipLib.sol";
import {ParentVaultConfigLib} from "../libraries/vaults/ParentVaultConfigLib.sol";
import {ParentVaultEpochLib} from "../libraries/vaults/ParentVaultEpochLib.sol";
import {ParentVaultRebalanceLib} from "../libraries/vaults/ParentVaultRebalanceLib.sol";
import {ParentVaultUserEpochLib} from "../libraries/vaults/ParentVaultUserEpochLib.sol";
import {IProtocolAdapter} from "../interfaces/adapters/IProtocolAdapter.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";

import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Yieldcoin v2 ParentVault
/// @author @contractlevel
/// @notice The user entry and exit point for deposits and withdraw intents in Yieldcoin v2
/// @dev Coordinates user accounting, epoch settlement, fees, and crosschain strategy allocation
/// @dev The Yieldcoin v2 system has one ParentVault
contract ParentVault is BaseVault, ParentVaultStore, IParentVault {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Precision of the 18-decimal YIELD share token
    uint256 internal constant SHARE_PRECISION = 1e18;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev Yieldcoin (YIELD) share token
    address internal immutable i_share;
    /// @dev Minimum deposit amount: 1 * i_assetPrecision
    uint256 internal immutable i_minDepositAmount;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes immutable ParentVault configuration and disables implementation initializers
    /// @param params BaseVault constructor parameters for values baked into the implementation bytecode
    /// @param share The address of the Yieldcoin (YIELD) share token
    /// @dev Reverts if BaseVault immutable configuration is invalid
    /// @dev Reverts if share is the zero address
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(BaseVault.ConstructorParams memory params, address share) BaseVault(params) {
        _revertIfZeroAddress(share);

        i_share = share;
        i_minDepositAmount = 1 * i_assetPrecision;

        _disableInitializers();
    }

    /// @notice Initializes ParentVault mutable proxy state
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    /// @param treasury The address of the operator multisig for protocol fees
    /// @param cancelDepositOperator The address authorized to force-cancel stuck deposits
    /// @dev Reverts if any BaseVault initializer parameter is invalid
    /// @dev Reverts if treasury is the zero address
    /// @dev Reverts if cancelDepositOperator is the zero address
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the proxy has already been initialized
    /// @dev Grants CANCEL_DEPOSIT_OPERATOR_ROLE to cancelDepositOperator
    /// @dev Opens epoch one and initializes rebalance nonce one
    /// @dev The initial active protocol adapter must be configured separately after its deployment and registration
    function initialize(BaseVault.InitParams memory params, address treasury, address cancelDepositOperator)
        external
        nonReentrant
        initializer
    {
        _revertIfZeroAddress(treasury);
        _revertIfZeroAddress(cancelDepositOperator);

        __BaseVault_init(params);

        ParentVaultStorage storage $ = _parentVaultStorage();
        $.s_epochNonce = 1;
        $.s_epochs[1].status = Types.EpochStatus.OPEN;
        $.s_epochs[1].openedAtTimestamp = block.timestamp;
        $.s_rebalance.nonce = 1;
        $.s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;
        $.s_treasury = treasury;
        _grantRole(Roles.CANCEL_DEPOSIT_OPERATOR_ROLE, cancelDepositOperator);
    }

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
    function setInitialActiveProtocolAdapter(bytes32 protocolId)
        external
        nonReentrant
        onlyRole(Roles.DEFAULT_ADMIN_ROLE)
    {
        ParentVaultStorage storage $ = _parentVaultStorage();
        if ($.s_initialActiveProtocolAdapterSet) {
            revert ParentVault__InitialActiveProtocolAdapterAlreadySet();
        }

        address adapter = _setActiveAdapter(protocolId);

        $.s_initialActiveProtocolAdapterSet = true;
        $.s_rebalance.activeStrategy.protocolId = protocolId;
        $.s_rebalance.activeStrategy.chainSelector = i_thisChainSelector;

        emit InitialActiveProtocolAdapterSet(protocolId, adapter);
    }

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
    function deposit(uint256 amount) external nonReentrant whenNotPaused returns (uint256 epochNonce) {
        epochNonce =
            ParentVaultUserEpochLib.deposit(_parentVaultStorage(), i_asset, msg.sender, amount, i_minDepositAmount);
    }

    /// @notice Submits a withdraw intent by escrowing shares in the current epoch
    /// @param shareBurnAmount The amount of shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The nonce of the epoch containing the withdraw intent
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires the caller to have sufficient share balance and allowance for shareBurnAmount
    function withdraw(uint256 shareBurnAmount) external nonReentrant whenNotPaused returns (uint256 epochNonce) {
        epochNonce = ParentVaultUserEpochLib.withdraw(_parentVaultStorage(), i_share, msg.sender, shareBurnAmount);
    }

    /// @notice Claims the shares allocated to the caller's deposit in a settled epoch
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if the caller has no deposit in the epoch
    function claimShares(uint256 epochNonce) external nonReentrant whenNotPaused returns (uint256 shareMintAmount) {
        shareMintAmount = ParentVaultUserEpochLib.claimShares(_parentVaultStorage(), i_share, msg.sender, epochNonce);
    }

    /// @notice Claims the underlying asset for a completed epoch withdraw
    /// @param epochNonce The nonce of the epoch to claim from
    /// @return withdrawAmount The amount of underlying asset transferred to the withdrawer
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if the caller has no withdraw intent in the epoch
    function claimAsset(uint256 epochNonce) external nonReentrant whenNotPaused returns (uint256 withdrawAmount) {
        withdrawAmount =
            ParentVaultUserEpochLib.claimAsset(_parentVaultStorage(), i_share, i_asset, msg.sender, epochNonce);
    }

    /// @notice Cancels and refunds the caller's deposit in the current open epoch
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if the caller has no deposit in the current epoch
    function cancelDeposit() external nonReentrant whenNotPaused {
        ParentVaultUserEpochLib.cancelDeposit(_parentVaultStorage(), i_asset, msg.sender);
    }

    /// @notice Cancels the caller's withdraw intent in the current open epoch and returns the escrowed shares
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if the caller has no withdraw intent in the current epoch
    function cancelWithdraw() external nonReentrant whenNotPaused {
        ParentVaultUserEpochLib.cancelWithdraw(_parentVaultStorage(), i_share, msg.sender);
    }

    /// @notice Force-cancels a user's deposit in the current open epoch, refunding their exact deposited amount
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev Reverts if the caller does not have CANCEL_DEPOSIT_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deliberately callable while paused
    function forceCancelDeposit(address user) external nonReentrant onlyRole(Roles.CANCEL_DEPOSIT_OPERATOR_ROLE) {
        ParentVaultUserEpochLib.forceCancelDeposit(_parentVaultStorage(), i_asset, user);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Handles an inbound CCIP epoch withdrawal or rebalance message
    /// @param message The CCIP message received from the router
    /// @dev Reverts if the caller is not the configured CCIP router
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if no crosschain vault is registered for the source chain
    /// @dev Reverts if the decoded sender is not the registered crosschain vault
    /// @dev Reverts if the message does not originate from the active strategy chain
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if the message does not deliver exactly one token amount
    /// @dev Reverts if the delivered token is not the configured underlying asset
    /// @dev Reverts if the delivered amount is zero
    /// @dev Reverts if the transaction type is not EPOCH_NET_WITHDRAW or REBALANCE
    /// @dev Reverts if message data cannot be decoded for its transaction type
    /// @dev For EPOCH_NET_WITHDRAW, reverts if the decoded nonce is not the most recently closed epoch
    /// @dev For EPOCH_NET_WITHDRAW, reverts if the identified epoch is not executing
    /// @dev For REBALANCE, reverts if no rebalance is in progress
    /// @dev For REBALANCE, reverts if the decoded nonce does not match the active rebalance
    /// @dev For REBALANCE, reverts if the decoded protocol ID does not match the pending strategy
    /// @dev Reverts if a rebalance protocol has no registered adapter
    /// @dev Reverts if the registered rebalance adapter is bound to another vault
    /// @dev Stores rebalance-deposit recovery if the target strategy deposit fails
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        nonReentrant
        whenNotPaused
        onlyAllowedSender(abi.decode(message.sender, (address)), message.sourceChainSelector)
    {
        ParentVaultStorage storage $ = _parentVaultStorage();
        uint64 activeStrategyChainSelector = $.s_rebalance.activeStrategy.chainSelector;
        if (message.sourceChainSelector != activeStrategyChainSelector) {
            revert BaseVault__InvalidSourceChainSelector(message.sourceChainSelector, activeStrategyChainSelector);
        }

        _requireNoRecovery(_baseVaultStorage());
        uint256 receivedAmount = BaseVaultCcipLib._validateReceivedTokenAndGetAmount(message, i_asset);

        // data decodes to a uint256 epochNonce for epoch net withdrawals and a
        // (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));
        (uint256 rebalanceNonce, bytes32 protocolId) =
            ParentVaultCcipLib._receiveCcip($, ccipTxType, data, receivedAmount);
        if (rebalanceNonce != 0) {
            bool success = _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
            // A rebalance message is received on its pending strategy chain, which is this chain
            if (success) {
                _finalizeRebalance(
                    rebalanceNonce, Types.Strategy({protocolId: protocolId, chainSelector: i_thisChainSelector})
                );
            }
        }

        emit CCIPReceived(message.messageId, message.sourceChainSelector, ccipTxType);
    }

    /*//////////////////////////////////////////////////////////////
                                 EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Settles the current epoch, executes its net asset flow, and opens the next epoch
    /// @param tvl The underlying-asset value of the active strategy before settling the current epoch
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
    /// @dev Reverts if the resulting price per share rounds down to zero
    /// @dev Reverts if deposit settlement would allocate zero shares to a minimum-size deposit
    /// @dev Requires any local strategy or CCIP interaction selected by the net-flow branch to succeed
    /// @dev The preceding-epoch guard prevents claims and strategy changes while a remote epoch remains executing
    /// @dev If a remote strategy withdrawal fails, users cannot claim until recovery succeeds on the ChildVault
    /// @dev An epoch nonce of one has no preceding epoch because initialization opens epoch one
    /// @dev Zero TVL with outstanding shares requires restoring TVL through an on-behalf-of strategy supply before
    ///      settlement can continue; the permanent admin seed deposit means this requires a full strategy loss
    /// @dev See KI-008 and KI-010 in docs/KNOWN_ISSUES.md
    function closeEpoch(uint256 tvl) external nonReentrant whenNotPaused onlyRole(Roles.EPOCH_OPERATOR_ROLE) {
        ParentVaultStorage storage $ = _parentVaultStorage();
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        bool isLocalStrategy = activeAdapter != address(0);
        ParentVaultEpochLib.CloseEpochExternalAction memory externalAction = ParentVaultEpochLib.closeEpoch(
            $, tvl, i_share, SHARE_PRECISION, i_assetPrecision, i_minDepositAmount, isLocalStrategy
        );

        if (externalAction.action == ParentVaultEpochLib.ExternalAction.DEPOSIT_TO_LOCAL_STRATEGY) {
            _executeDeposit(externalAction.amount, true, activeAdapter);
            emit EpochDepositToStrategySuccess(externalAction.epochNonce, externalAction.amount);
        } else if (externalAction.action == ParentVaultEpochLib.ExternalAction.SEND_DEPOSIT_TO_REMOTE_STRATEGY) {
            _ccipSend(
                externalAction.amount,
                $.s_rebalance.activeStrategy.chainSelector,
                Types.CcipTx.EPOCH_NET_DEPOSIT,
                externalAction.epochNonce,
                bytes32(0)
            );
        } else if (externalAction.action == ParentVaultEpochLib.ExternalAction.WITHDRAW_FROM_LOCAL_STRATEGY) {
            (, uint256 amountOut) = _executeWithdraw(externalAction.amount, true, activeAdapter);
            emit EpochWithdrawFromStrategySuccess(externalAction.epochNonce, amountOut);
            ParentVaultEpochLib.finalizeLocalNetWithdraw(
                $, externalAction.epochNonce, externalAction.totalDepositAmount, amountOut
            );
        }
        // else CRE is triggered by EpochWithdrawExecuting and writes to the strategy chain to withdraw and CCIP-send here

        ParentVaultEpochLib.openNextEpoch($, externalAction.epochNonce);
    }

    /// @notice Completes the most recently closed remote net-deposit epoch
    /// @dev Callable while the vault is paused so confirmed remote settlement can be finalized
    /// @dev Reverts if the caller does not have EPOCH_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the previous epoch is not an executing net-deposit epoch
    function completeEpochDeposit() external nonReentrant onlyRole(Roles.EPOCH_OPERATOR_ROLE) {
        ParentVaultEpochLib.completeEpochDeposit(_parentVaultStorage());
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice Initiates a rebalance from the current strategy to a new strategy
    /// @param newStrategy The new strategy to rebalance to
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
    function initiateRebalance(Types.Strategy memory newStrategy)
        external
        nonReentrant
        whenNotPaused
        onlyRole(Roles.REBALANCE_OPERATOR_ROLE)
    {
        ParentVaultStorage storage $ = _parentVaultStorage();
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);

        bool isSupportedChain = newStrategy.chainSelector == i_thisChainSelector
            || $_baseVault.s_crosschainVaults[newStrategy.chainSelector] != address(0);

        ParentVaultRebalanceLib.InitiateRebalanceResult memory result =
            ParentVaultRebalanceLib.initiateRebalance($, newStrategy, i_thisChainSelector, isSupportedChain);

        // Continue synchronously when the previously active strategy is local
        //slither-disable-next-line incorrect-equality
        if (result.action != ParentVaultRebalanceLib.ExternalAction.NONE) {
            // withdraw from local strategy
            address activeAdapter = $_baseVault.s_activeProtocolAdapter;
            (, uint256 amountOut) = _executeWithdraw(type(uint256).max, true, activeAdapter);
            _revertIfZeroAmount(amountOut);
            emit RebalanceWithdrawSuccess(result.rebalanceNonce, amountOut);
            if (result.action == ParentVaultRebalanceLib.ExternalAction.WITHDRAW_LOCAL_TO_LOCAL) {
                // deposit into local strategy
                address newAdapter = _setActiveAdapter(newStrategy.protocolId);
                _executeDeposit(amountOut, true, newAdapter);
                emit RebalanceDepositSuccess(result.rebalanceNonce, amountOut);
                _finalizeLocalToLocalRebalance(result.rebalanceNonce, newStrategy);
            } else {
                // ccip send to new strategy chain
                _clearActiveAdapter(activeAdapter);
                _ccipSend(
                    amountOut,
                    newStrategy.chainSelector,
                    Types.CcipTx.REBALANCE,
                    result.rebalanceNonce,
                    newStrategy.protocolId
                );
            }
        } // else, CRE is trigged by the event to write to old strategy chain and rebalance/bridge from there
    }

    /// @notice Completes a rebalance
    /// @dev Callable while the vault is paused so confirmed remote settlement can be finalized
    /// @dev Reverts if the caller does not have REBALANCE_OPERATOR_ROLE
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a recovery mode is active
    /// @dev Reverts if no rebalance is in progress
    function completeRebalance() external nonReentrant onlyRole(Roles.REBALANCE_OPERATOR_ROLE) {
        _requireNoRecovery(_baseVaultStorage());
        Types.Rebalance storage s_rebalance = _parentVaultStorage().s_rebalance;
        _finalizeRebalance(s_rebalance.nonce, s_rebalance.pendingStrategy);
    }

    /// @notice Finalizes an in-progress rebalance with persisted pending state
    /// @param rebalanceNonce The nonce of the rebalance to finalize
    /// @param newStrategy The pending strategy to activate
    /// @dev Reverts if no rebalance is in progress
    function _finalizeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal {
        ParentVaultRebalanceLib._finalizeRebalance(_parentVaultStorage(), i_share, rebalanceNonce, newStrategy, false);
    }

    /// @notice Finalizes a local-to-local rebalance that completed synchronously without persisted pending state
    /// @param rebalanceNonce The rebalance nonce, already known by the caller
    /// @param newStrategy The new strategy, already known by the caller
    function _finalizeLocalToLocalRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal {
        ParentVaultRebalanceLib._finalizeRebalance(_parentVaultStorage(), i_share, rebalanceNonce, newStrategy, true);
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev Permissionless because the operation and all inputs are fixed by stored recovery state
    /// @dev REBALANCE_DEPOSIT is the only recovery mode supported by ParentVault
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
        if ($_baseVault.s_recoveryMode != Types.RecoveryMode.REBALANCE_DEPOSIT) revert BaseVault__NoPendingRecovery();
        _recoverFailedRebalanceDeposit($_baseVault);
        Types.Rebalance storage s_rebalance = _parentVaultStorage().s_rebalance;
        _finalizeRebalance(s_rebalance.nonce, s_rebalance.pendingStrategy);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets whether a protocol is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to configure
    /// @param isSupported Whether the protocol is supported
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if protocolId is zero
    /// @dev When removing support, reverts if protocolId belongs to the active strategy
    /// @dev When removing support, reverts if protocolId belongs to the pending strategy
    function setSupportedProtocol(bytes32 protocolId, bool isSupported) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        ParentVaultConfigLib.setSupportedProtocol(_parentVaultStorage(), protocolId, isSupported);
    }

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if treasury is the zero address
    function setTreasury(address treasury) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        ParentVaultConfigLib.setTreasury(_parentVaultStorage(), treasury);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the rebalance state
    /// @return rebalance The current rebalance state
    function getRebalance() external view returns (Types.Rebalance memory rebalance) {
        rebalance = _parentVaultStorage().s_rebalance;
    }

    /// @notice Returns the epoch data for a given epoch nonce
    /// @param epochNonce The epoch nonce to query
    /// @return epoch Types.Epoch struct includes:
    ///         uint256 totalDepositAmount - the total underlying asset deposited in the epoch
    ///         uint256 totalShareBurnAmount - the total shares submitted for withdraw in the epoch
    ///         uint256 totalWithdrawClaimAmount - the total underlying asset allocated to epoch withdraw claims
    ///         uint256 pricePerShare - the settlement price per share
    ///         uint256 remainingDepositClaimAmount - the unclaimed underlying asset attributed to deposits
    ///         uint256 remainingShareMintAmount - the shares remaining to mint for deposits
    ///         uint256 remainingShareBurnAmount - the escrowed shares remaining to burn for withdraw claims
    ///         uint256 remainingWithdrawClaimAmount - the underlying asset remaining to claim for withdraw claims
    ///         uint256 openedAtTimestamp - the timestamp when the epoch opened
    ///         Types.EpochStatus status - the epoch status
    function getEpoch(uint256 epochNonce) external view returns (Types.Epoch memory epoch) {
        epoch = _parentVaultStorage().s_epochs[epochNonce];
    }

    /// @notice Returns the current epoch nonce
    /// @return epochNonce The nonce of the currently active epoch
    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    /// @notice Returns the total number of Yieldcoin shares tracked by the vault
    /// @return totalShares The total share count tracked by the vault
    /// @dev Updated at epoch settlement before the corresponding shares are minted or burned at claim time, so it
    ///      may be higher or lower than the share token's totalSupply() while claims remain pending
    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = _parentVaultStorage().s_totalShares;
    }

    /// @notice Returns the underlying-asset deposit amount submitted by a user for a given epoch
    /// @param user The address of the depositor
    /// @param epochNonce The epoch nonce of the deposit
    /// @return amount The underlying-asset amount the user deposited into the given epoch
    function getDepositAmount(address user, uint256 epochNonce) external view returns (uint256 amount) {
        amount = _parentVaultStorage().s_deposits[user][epochNonce];
    }

    /// @notice Returns the share amount escrowed by a user for an epoch withdraw intent
    /// @param user The address of the withdrawer
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @return shareBurnAmount The shares escrowed for burning when the withdraw is claimed
    function getWithdrawShareBurnAmount(address user, uint256 epochNonce)
        external
        view
        returns (uint256 shareBurnAmount)
    {
        shareBurnAmount = _parentVaultStorage().s_withdraws[user][epochNonce];
    }

    /// @notice Returns whether the initial active protocol adapter has been set
    /// @return initialActiveProtocolAdapterSet Whether the initial active protocol adapter has been set
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet) {
        initialActiveProtocolAdapterSet = _parentVaultStorage().s_initialActiveProtocolAdapterSet;
    }

    /// @notice Returns the operator multisig that receives protocol fees
    /// @return treasury The address of the operator multisig for protocol fees
    function getTreasury() external view returns (address treasury) {
        treasury = _parentVaultStorage().s_treasury;
    }

    /// @notice Returns the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share) {
        share = i_share;
    }

    /// @notice Returns the share precision factor (fixed at SHARE_PRECISION)
    /// @return sharePrecision The share precision factor
    function getSharePrecision() external pure returns (uint256 sharePrecision) {
        sharePrecision = SHARE_PRECISION;
    }

    /// @notice Returns the minimum deposit amount (1 * i_assetPrecision)
    /// @return minDepositAmount The minimum deposit amount
    function getMinDepositAmount() external view returns (uint256 minDepositAmount) {
        minDepositAmount = i_minDepositAmount;
    }

    /// @notice Returns whether a protocol ID is supported on any chain across the Yieldcoin v2 system
    /// @param protocolId The protocol ID to query
    /// @return isSupported Whether the protocol ID is supported
    function getSupportedProtocol(bytes32 protocolId) external view returns (bool isSupported) {
        isSupported = _parentVaultStorage().s_supportedProtocol[protocolId];
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the current default admin
    /// @notice Returns whether this contract implements the given interface ID
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return isSupported Whether this contract implements `interfaceId`
    /// @dev Supports IERC165, IAccessControlDefaultAdminRules, and IAny2EVMMessageReceiver
    function supportsInterface(bytes4 interfaceId) public pure override(BaseVault) returns (bool isSupported) {
        isSupported = interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId;
    }

    /// @notice Returns this vault's accounted underlying-asset value
    /// @return tvl The active local strategy position plus applicable vault-held recovery assets
    /// @dev Returns zero when this vault has neither an active strategy position nor applicable recovery assets
    /// @dev Includes pending rebalance-deposit recovery held by this vault when an active adapter is set
    /// @dev Returns zero when no active adapter is set
    function _getTVL() internal view override returns (uint256 tvl) {
        BaseVaultStorage storage $ = _baseVaultStorage();
        address activeAdapter = $.s_activeProtocolAdapter;
        if (activeAdapter != address(0)) {
            tvl = IProtocolAdapter(activeAdapter).getTVL() + $.s_rebalanceDepositRecovery.amount;
        } else {
            tvl = 0;
        }
    }
}
