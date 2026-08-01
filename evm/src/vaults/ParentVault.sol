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
import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {PolicyProtectedUpgradeable} from "@chainlink/policy-management/core/PolicyProtectedUpgradeable.sol";
import {PolicyProtectedBaseUpgradeable} from "@chainlink/policy-management/core/PolicyProtectedBaseUpgradeable.sol";
import {IPolicyProtected} from "@chainlink/policy-management/interfaces/IPolicyProtected.sol";

import {
    AccessControlDefaultAdminRulesUpgradeable,
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Yieldcoin v2 ParentVault
/// @author @contractlevel
/// @notice The entry/exit point for users to deposit and withdraw in the Yieldcoin v2 system.
/// @dev Only one ParentVault is deployed on a single chain in the entire Yieldcoin v2 system.
contract ParentVault is BaseVault, ParentVaultStore, IParentVault, PolicyProtectedUpgradeable {
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
    /// @notice Initializes implementation-level immutable configuration for the ParentVault.
    /// @param params BaseVault constructor parameters for values baked into the implementation bytecode
    /// @param share The address of the Yieldcoin (YIELD) share token
    /// @dev Precondition: share must not be the zero address
    constructor(BaseVault.ConstructorParams memory params, address share) BaseVault(params) {
        _revertIfZeroAddress(share);

        i_share = share;
        i_minDepositAmount = 1 * i_assetPrecision;

        _disableInitializers();
    }

    /// @notice Initializes ParentVault mutable proxy state.
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    /// @param treasury The address of the operator multisig for protocol fees
    /// @param policyEngineManager The address authorized to replace this vault's attached policy engine
    /// @param policyEngine The address of the Yieldcoin v2 PolicyEngine
    /// @param cancelDepositOperator The address authorized to force-cancel stuck deposits
    /// @dev Precondition: treasury must not be the zero address
    /// @dev Precondition: policyEngineManager must not be the zero address
    /// @dev Precondition: policyEngine must not be the zero address
    /// @dev Precondition: cancelDepositOperator must not be the zero address
    /// @dev PolicyProtected ownership is initialized to the vault default admin only to satisfy inherited Ownable state.
    ///      Runtime policy engine replacement is controlled by POLICY_ENGINE_MANAGER_ROLE.
    /// @dev The initial active protocol adapter is set after deployment with setInitialActiveProtocolAdapter.
    ///      Deployment order: deploy vault implementation, deploy vault proxy, deploy adapter with proxy address,
    ///      register adapter, then call setter on the proxy.
    function initialize(
        BaseVault.InitParams memory params,
        address treasury,
        address policyEngineManager,
        address policyEngine,
        address cancelDepositOperator
    ) external nonReentrant initializer {
        _revertIfZeroAddress(treasury);
        _revertIfZeroAddress(policyEngineManager);
        _revertIfZeroAddress(cancelDepositOperator);
        _validatePolicyEngine(policyEngine);

        __BaseVault_init(params);
        __PolicyProtected_init(params.defaultAdmin, policyEngine);

        ParentVaultStorage storage $ = _parentVaultStorage();
        $.s_performanceFeeHighWaterMark = i_assetPrecision;
        $.s_epochNonce = 1;
        $.s_epochs[1].status = Types.EpochStatus.OPEN;
        $.s_epochs[1].openedAtTimestamp = block.timestamp;
        $.s_rebalance.nonce = 1;
        $.s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;
        $.s_treasury = treasury;
        _grantRole(Roles.POLICY_ENGINE_MANAGER_ROLE, policyEngineManager);
        _grantRole(Roles.CANCEL_DEPOSIT_OPERATOR_ROLE, cancelDepositOperator);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the initial active protocol adapter after deployment
    /// @param protocolId The protocol ID of the initial active strategy
    /// @dev This is called once after the adapter is deployed and registered inside the *same deploy script*, before operational use.
    /// @dev Precondition: Caller must have the DEFAULT_ADMIN_ROLE
    /// @dev Precondition: the initial active protocol adapter must not already be set
    /// @dev Precondition: the protocol ID must have a registered adapter
    /// @dev Precondition: the registered adapter must be bound to this vault
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

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: treasury must not be the zero address
    function setTreasury(address treasury) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        ParentVaultConfigLib.setTreasury(_parentVaultStorage(), treasury);
    }

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the vault
    /// @param amount The amount of asset to deposit
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Precondition: amount must meet the minimum deposit amount requirement
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function deposit(uint256 amount) external nonReentrant whenNotPaused runPolicy returns (uint256 epochNonce) {
        epochNonce =
            ParentVaultUserEpochLib.deposit(_parentVaultStorage(), i_asset, msg.sender, amount, i_minDepositAmount);
    }

    /// @notice Submit USDC withdraw intent
    /// @param shareBurnAmount The amount of shares to burn for the withdraw
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev ParentVault policy intentionally overlaps with YieldcoinShare transfer checks for defense-in-depth.
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their shareBurnAmount
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function withdraw(uint256 shareBurnAmount)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 epochNonce)
    {
        epochNonce = ParentVaultUserEpochLib.withdraw(_parentVaultStorage(), i_share, msg.sender, shareBurnAmount);
    }

    /// @notice Claim Yieldcoin shares after a deposit
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Finalizes an individual deposit.
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function claimShares(uint256 epochNonce)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 shareMintAmount)
    {
        shareMintAmount = ParentVaultUserEpochLib.claimShares(_parentVaultStorage(), i_share, msg.sender, epochNonce);
    }

    /// @notice Claim underlying asset after a withdraw
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return withdrawAmount The amount of asset withdrawn
    /// @dev Finalizes an individual withdraw.
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function claimAsset(uint256 epochNonce)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 withdrawAmount)
    {
        withdrawAmount = ParentVaultUserEpochLib.claimAsset(
            _parentVaultStorage(), i_share, i_asset, msg.sender, epochNonce
        );
    }

    /// @notice Cancels a deposit
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function cancelDeposit() external nonReentrant whenNotPaused runPolicy {
        ParentVaultUserEpochLib.cancelDeposit(_parentVaultStorage(), i_asset, msg.sender);
    }

    /// @notice Cancels a withdraw
    /// @dev This deletes the entire withdraw entry for the user and epoch nonce
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev ParentVault policy intentionally overlaps with YieldcoinShare transfer checks for defense-in-depth.
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    function cancelWithdraw() external nonReentrant whenNotPaused runPolicy {
        ParentVaultUserEpochLib.cancelWithdraw(_parentVaultStorage(), i_share, msg.sender);
    }

    /// @notice Force-cancels a user's deposit in the current open epoch, refunding their exact deposited amount
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: caller must have the CANCEL_DEPOSIT_OPERATOR_ROLE
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    /// @dev ParentVaultUserEpochLib is linked by Solidity and executes by DELEGATECALL in the vault context.
    /// @dev Intentionally does not include whenNotPaused and runPolicy
    function forceCancelDeposit(address user) external nonReentrant onlyRole(Roles.CANCEL_DEPOSIT_OPERATOR_ROLE) {
        ParentVaultUserEpochLib.forceCancelDeposit(_parentVaultStorage(), i_asset, user);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives CCIP messages
    /// @param message Any2EVMMessage.
    /// @dev Precondition: the call must not be reentered
    /// @dev Precondition: the message must be sent by an allowed sender (a crosschain vault mapped to an allowed source chain selector)
    /// @dev Precondition: the message must originate from the active strategy chain
    /// @dev Precondition: the received token must be i_asset
    /// @dev Precondition: there must not be an existent recovery mode
    /// @dev Precondition: if epoch tx: the decoded nonce must match the previous
    /// @dev Precondition: if rebalance tx: the state must be REBALANCING
    /// @dev Precondition: if rebalance tx: the decoded nonce must match the current
    /// @dev Precondition: if rebalance tx: the decoded protocolId must match the pending protocolId
    /// @dev Precondition: the contract must not be paused
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
        uint256 receivedAmount = BaseVaultCcipLib.validateReceivedTokenAndGetAmount(message, i_asset);

        /// @dev data decodes to a uint256 epochNonce for epoch net withdraws and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));
        (uint256 rebalanceNonce, bytes32 protocolId) =
            ParentVaultCcipLib.receiveCcip($, ccipTxType, data, receivedAmount);
        if (rebalanceNonce != 0) {
            bool success = _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
            /// @dev _ccipReceive only runs on the chain a rebalance CCIP message was sent to, so the
            ///      pending strategy's chain selector is always this chain - no need to read it from
            ///      storage (BaseVaultCcipLib.sol -> BaseVault._ccipSend sends to newStrategy.chainSelector).
            if (success) {
                _finalizeRebalance(
                    rebalanceNonce, Types.Strategy({protocolId: protocolId, chainSelector: i_thisChainSelector})
                );
            }
        }

        // @review CCIPReceived event? to mirror CCIPBridged?
    }

    /*//////////////////////////////////////////////////////////////
                                 EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Closes an epoch and handles the net flow, then opens the next epoch
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @dev Called by WorkflowRouter.
    /// @dev The `netFlow` is `total asset deposit amount` minus `calculated total asset withdraw amount` for the given epoch.
    ///      When `netFlow == 0`: the epoch is CLAIMABLE
    ///      When `netFlow > 0` and the active strategy is local to this chain: the netFlow is deposited straight into the strategy
    ///      When `netFlow > 0` and the active strategy is remote to this chain: the netFlow is sent via CCIP and the epoch is EXECUTING
    ///      When `netFlow < 0` and the active strategy is local to this chain: the netFlow is withdrawn from the strategy and the epoch is CLAIMABLE
    ///      When `netFlow < 0` and the active strategy is remote to this chain: EpochWithdrawExecuting() triggers CRE to write to the strategy chain and the epoch is EXECUTING
    /// @dev Precondition: the caller must have the EPOCH_OPERATOR_ROLE
    /// @dev Precondition: there must not be an active rebalance
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: the previous epoch must be claimable, if a previous epoch exists
    /// @dev Precondition: the epoch must be open
    /// @dev Precondition: the epoch period must have exceeded the MIN_EPOCH_PERIOD
    /// @dev Precondition: there must have been a deposit or withdraw intent submitted during the epoch
    /// @dev Precondition: local strategy interactions must be successful
    /// @dev Precondition: the contract must not be paused
    /// @dev The previous-epoch guard prevents closing a later epoch while a prior
    ///      remote epoch is still EXECUTING. This prevents claims and strategy changes until cross-chain settlement completes.
    ///      if a child strategy withdraw fails, the owed USDC is not back on the Parent,
    ///      so affected users cannot claim until executeRecovery() succeeds on the child vault.
    /// @dev previousEpochNonce == 0 means no prior epoch exists (initialize() sets s_epochNonce = 1).
    /// @dev The tvl parameter is provided by the CRE workflow via WorkflowRouter and is trusted
    ///      to accurately reflect the active strategy chain's TVL. The CRE workflow is audited to
    ///      the same standard as this contract. No onchain validation of this value is performed;
    ///      an incorrect value will corrupt epoch share accounting irrecoverably once any user
    ///      claims against the affected epoch.
    /// @dev Precondition: `tvl == 0 && s_totalShares > 0` will cause a revert
    /// @dev Precondition: If deposits exist, aggregate minted shares must cover at least one share per minimum deposit amount.
    /// @dev If TVL goes to zero with shares outstanding, closeEpoch reverts until TVL is restored via
    ///      an on-behalf-of supply to the active protocol; the permanent admin seed deposit means this
    ///      requires a full loss of the active strategy, not a partial one. See KI-008, KI-010 in docs/KNOWN_ISSUES.md.
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
    /// @dev Called by WorkflowRouter after the destination ChildVault emits EpochDepositToStrategySuccess.
    /// @dev Deliberately callable while paused: claims remain paused, but confirmed settlement can finalize.
    /// @dev Precondition: caller must have EPOCH_OPERATOR_ROLE
    /// @dev Precondition: the previous epoch must be an executing net-deposit epoch
    function completeEpochDeposit() external nonReentrant onlyRole(Roles.EPOCH_OPERATOR_ROLE) {
        ParentVaultEpochLib.completeEpochDeposit(_parentVaultStorage());
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice Initiates a rebalance from the current strategy to a new strategy
    /// @param newStrategy The new strategy to rebalance to
    /// @dev This is called by the WorkflowRouter.
    /// @dev Precondition: the caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: A rebalance must not already be in progress
    /// @dev Precondition: MIN_REBALANCE_PERIOD must have elapsed since the last rebalance completed
    /// @dev Precondition: newStrategy must not be the same as the current active strategy
    /// @dev Precondition: An epoch must not be EXECUTING
    /// @dev Precondition: If current/active/previous strategy is on this chain, withdrawing tvl from the old strategy must succeed
    /// @dev Precondition: If current/active/previous strategy and newStrategy is on this chain, depositing tvl into the new strategy must succeed
    /// @dev Precondition: there must not be a stored recovery mode
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

        /// @dev check if old/previously-active strategy chain selector is this one
        //slither-disable-next-line incorrect-equality
        if (result.action != ParentVaultRebalanceLib.ExternalAction.NONE) {
            // withdraw from local strategy
            address activeAdapter = $_baseVault.s_activeProtocolAdapter;
            (, uint256 amountOut) = _executeWithdraw(type(uint256).max, true, activeAdapter);
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
    /// @dev The WorkflowRouter calls this.
    /// @dev Precondition: caller must have REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: function must not be reentered
    function completeRebalance() external nonReentrant onlyRole(Roles.REBALANCE_OPERATOR_ROLE) {
        _requireNoRecovery(_baseVaultStorage());
        Types.Rebalance storage s_rebalance = _parentVaultStorage().s_rebalance;
        _finalizeRebalance(s_rebalance.nonce, s_rebalance.pendingStrategy);
    }

    /// @notice Finalizes an in-progress rebalance via ParentVaultRebalanceLib.
    /// @dev Every ParentVault call site with a persisted pending rebalance funnels through here rather
    ///      than calling ParentVaultRebalanceLib.finalizeRebalance directly, so there is exactly one
    ///      place that knows how to reach the library. `_ccipReceive`'s rebalance-complete branch
    ///      already has `rebalanceNonce`/`newStrategy` in memory and passes them straight through,
    ///      avoiding a redundant SLOAD of `s_rebalance.nonce`/`pendingStrategy`. Callers that don't
    ///      (`completeRebalance`, `executeRecovery`) read them from storage once, immediately before
    ///      calling. The local-to-local path never persists a pending rebalance in the first place -
    ///      see `_finalizeLocalToLocalRebalance` below.
    /// @param rebalanceNonce The current `s_rebalance.nonce`
    /// @param newStrategy The current `s_rebalance.pendingStrategy`
    function _finalizeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal {
        ParentVaultRebalanceLib.finalizeRebalance(_parentVaultStorage(), i_share, rebalanceNonce, newStrategy, false);
    }

    /// @notice Finalizes a rebalance that resolved synchronously within the same initiateRebalance()
    ///         call (both old and new strategy on this chain) - state/pendingStrategy were never
    ///         persisted, so there is nothing to validate or clear.
    /// @param rebalanceNonce The rebalance nonce, already known by the caller
    /// @param newStrategy The new strategy, already known by the caller
    function _finalizeLocalToLocalRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal {
        ParentVaultRebalanceLib.finalizeRebalance(_parentVaultStorage(), i_share, rebalanceNonce, newStrategy, true);
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev The only recovery mode that can be active on Parent is REBALANCE_DEPOSIT.
    /// @dev Precondition: a recovery mode must be active (not NONE)
    /// @dev Precondition: function must not be reentered
    /// @dev Finalizes the rebalance in the same atomic tx
    /// @dev Precondition: the contract must not be paused
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
    /// @param protocolId The protocol identifier of the protocol to support, ie keccak256("aave-v3")
    /// @param isSupported Whether a protocol is supported on any chain. True for supported, false for not
    /// @dev Precondition: caller must have CONFIG_OPERATOR_ROLE
    /// @dev Precondition: protocolId must not be zero
    /// @dev Precondition: an unsupported protocol must not be the active or pending strategy protocol
    /// @dev Emits SupportedProtocolSet event
    function setSupportedProtocol(bytes32 protocolId, bool isSupported) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        ParentVaultConfigLib.setSupportedProtocol(_parentVaultStorage(), protocolId, isSupported);
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
    /// @return epoch The epoch data including status, deposit/withdraw totals, price per share, and timestamps
    function getEpoch(uint256 epochNonce) external view returns (Types.Epoch memory epoch) {
        epoch = _parentVaultStorage().s_epochs[epochNonce];
    }

    /// @notice Returns the current epoch nonce
    /// @return epochNonce The nonce of the currently active epoch
    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    /// @notice Returns the total number of Yieldcoin shares tracked by the vault
    /// @dev This leads the on-chain share supply: updated at epoch close, minted/burned lazily at claim time
    /// @return totalShares The total share count tracked by the vault
    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = _parentVaultStorage().s_totalShares;
    }

    /// @notice Returns the asset deposit amount submitted by a user for a given epoch
    /// @param user The address of the depositor
    /// @param epochNonce The epoch nonce of the deposit
    /// @return amount The asset amount the user deposited into the given epoch
    function getDepositAmount(address user, uint256 epochNonce) external view returns (uint256 amount) {
        amount = _parentVaultStorage().s_deposits[user][epochNonce];
    }

    /// @notice Returns the share burn amount submitted by a user for a given epoch withdraw intent
    /// @param user The address of the withdrawer
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @return shareBurnAmount The number of Yieldcoin shares the user submitted for burning in the given epoch
    function getWithdrawShareBurnAmount(address user, uint256 epochNonce)
        external
        view
        returns (uint256 shareBurnAmount)
    {
        shareBurnAmount = _parentVaultStorage().s_withdraws[user][epochNonce];
    }

    /// @inheritdoc IParentVault
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet) {
        initialActiveProtocolAdapterSet = _parentVaultStorage().s_initialActiveProtocolAdapterSet;
    }

    /// @inheritdoc IParentVault
    function getPerformanceFeeHighWaterMark() external view returns (uint256 highWaterMark) {
        highWaterMark = _parentVaultStorage().s_performanceFeeHighWaterMark;
    }

    /// @notice Gets the operator multisig for protocol fees
    /// @return treasury The address of the operator multisig for protocol fees
    function getTreasury() external view returns (address treasury) {
        treasury = _parentVaultStorage().s_treasury;
    }

    /// @notice Gets the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share) {
        share = i_share;
    }

    /// @notice Gets the share precision
    /// @return sharePrecision The share precision
    function getSharePrecision() external pure returns (uint256 sharePrecision) {
        sharePrecision = SHARE_PRECISION;
    }

    /// @notice Gets the minimum deposit amount (1 * i_assetPrecision)
    /// @return minDepositAmount The minimum deposit amount
    function getMinDepositAmount() external view returns (uint256 minDepositAmount) {
        minDepositAmount = i_minDepositAmount;
    }

    /// @notice Gets whether a protocolId is supported on any chain across the Yieldcoin v2 system.
    /// @param protocolId The protocol identifier to check, ie keccak256("aave-v3")
    /// @return isSupported true if supported on any chain, false if not supported on any chain
    function getSupportedProtocol(bytes32 protocolId) external view returns (bool isSupported) {
        isSupported = _parentVaultStorage().s_supportedProtocol[protocolId];
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Resolves the owner() conflict between OwnableUpgradeable (via PolicyProtectedUpgradeable) and
    ///         AccessControlDefaultAdminRules. Returns the default admin address.
    function owner()
        public
        view
        override(OwnableUpgradeable, AccessControlDefaultAdminRulesUpgradeable)
        returns (address)
    {
        return AccessControlDefaultAdminRulesUpgradeable.owner();
    }

    /// @notice Attaches a policy engine.
    /// @dev Precondition: Caller must have the POLICY_ENGINE_MANAGER_ROLE
    /// @param policyEngine The policy engine to attach
    function attachPolicyEngine(address policyEngine) external override onlyRole(Roles.POLICY_ENGINE_MANAGER_ROLE) {
        _validatePolicyEngine(policyEngine);
        _attachPolicyEngine(policyEngine);
    }

    /// @notice Returns whether this contract implements the given interface ID
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return Whether this contract implements `interfaceId`
    /// @dev Overrides BaseVault and PolicyProtectedUpgradeable. Re-implements the full interface ID check directly
    ///      (rather than calling both supers) so it can additionally support IPolicyProtected: IERC165,
    ///      IAccessControlDefaultAdminRules, and IAny2EVMMessageReceiver (from BaseVault), plus IPolicyProtected.
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(BaseVault, PolicyProtectedUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId
            || interfaceId == type(IPolicyProtected).interfaceId;
    }

    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain, or 0 if not
    /// @return tvl The Yieldcoin TVL
    /// @dev Unlike the Child Vault implementation, which also includes s_epochDepositRecovery.amount and
    ///      s_ccipSendRecovery.amount, the Parent Vault implementation only includes s_rebalanceDepositRecovery.amount.
    /// @dev Returns 0 if the TVL is in transit over CCIP. This should not be read onchain when Parent state is REBALANCING.
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
