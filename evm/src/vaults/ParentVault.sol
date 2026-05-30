// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseVault} from "./BaseVault.sol";
import {IParentVault} from "../interfaces/IParentVault.sol";
import {IAdapterRegistry} from "../interfaces/IAdapterRegistry.sol";
import {IShare} from "../interfaces/IShare.sol";
import {Types} from "../libraries/Types.sol";
import {Roles} from "../libraries/Roles.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {PolicyProtected, IPolicyProtected, Ownable} from "@chainlink/policy-management/core/PolicyProtected.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    AccessControlDefaultAdminRules,
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Yieldcoin v2 ParentVault
/// @author @contractlevel
/// @notice Only one ParentVault is deployed on a single chain in the entire Yieldcoin v2 system.
/// @notice This contract acts as the entry/exit point for users to deposit and withdraw in the Yieldcoin v2 system.
contract ParentVault is BaseVault, IParentVault, PolicyProtected {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Minimum time an epoch must be open
    uint256 internal constant MIN_EPOCH_PERIOD = 1 hours;
    /// @dev Basis points denominator (100% = 10_000 bps)
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    /// @dev Performance fee rate (7.77%)
    uint256 internal constant PERFORMANCE_FEE_BPS = 777;
    /// @dev Annual management fee rate (1%)
    uint256 internal constant MANAGEMENT_FEE_BPS = 100;

    /// @dev USDC precision
    uint256 internal constant USDC_PRECISION = 1e6;
    /// @dev WAD precision
    uint256 internal constant WAD_PRECISION = 1e18;
    /// @dev Initial Yieldcoin share mint precision
    uint256 internal constant SHARE_PRECISION = WAD_PRECISION / USDC_PRECISION;
    /// @dev Minimum deposit amount
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 100 * USDC_PRECISION;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev Yieldcoin (YIELD) share token
    address internal immutable i_share;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    Types.Rebalance internal s_rebalance;

    /// @dev Total number of Yieldcoin shares minted and available to claim
    /// @notice One subtlety: between closeEpoch and the last claimUsdc call for an epoch, s_totalShares could be decremented but the actual Yieldcoin share tokens haven't been burned yet.
    /// The i_share.totalSupply() will be higher than s_totalShares during this window. Therefore we never use i_share.totalSupply() as an authoritative share count — always use s_totalShares.
    uint256 internal s_totalShares;
    /// @dev Highest price per share ever recorded for performance fee purposes
    uint256 internal s_performanceFeeHighWaterMark;
    /// @dev Current epoch nonce
    uint256 internal s_epochNonce;
    /// @dev Epochs
    mapping(uint256 epochNonce => Types.Epoch) internal s_epochs;
    /// @dev Mapping of depositors to their deposits for each epoch
    mapping(address depositor => mapping(uint256 epochId => uint256 usdcAmount)) s_deposits;
    /// @dev Mapping of withdrawers to their withdraw intents for each epoch
    mapping(address withdrawer => mapping(uint256 epochId => uint256 shareBurnAmount)) s_withdraws;
    /// @dev Treasury address for collecting fees. This should be the protocol operator's multisig.
    address internal s_treasury;
    /// @dev Whether the initial active protocol adapter has been set
    bool internal s_initialActiveProtocolAdapterSet;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param params BaseVault Constructor parameters
    /// @param treasury The address of the operator multisig for protocol fees
    /// @param share The address of the Yieldcoin (YIELD) share token
    /// @param policyEngineManager The address authorized to replace this vault's attached policy engine
    /// @param policyEngine The address of the Yieldcoin v2 PolicyEngine
    /// @dev PolicyProtected ownership is initialized to the vault default admin only to satisfy inherited Ownable state.
    ///      Runtime policy engine replacement is controlled by POLICY_ENGINE_MANAGER_ROLE.
    /// @dev The initial active protocol adapter is set after deployment with setInitialActiveProtocolAdapter.
    ///      Deployment order: deploy vault, deploy adapter with vault address, register adapter, then call setter.
    //slither-disable-next-line missing-zero-check
    constructor(
        BaseVault.ConstructorParams memory params,
        address treasury,
        address share,
        address policyEngineManager,
        address policyEngine
    ) BaseVault(params) PolicyProtected(params.defaultAdmin, policyEngine) {
        i_share = share;
        s_performanceFeeHighWaterMark = SHARE_PRECISION;
        s_epochNonce = 1;
        s_epochs[1].status = Types.EpochStatus.OPEN;
        s_epochs[1].openedAtTimestamp = block.timestamp;
        s_rebalance.nonce = 1;
        s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;
        s_treasury = treasury;
        _grantRole(Roles.POLICY_ENGINE_MANAGER_ROLE, policyEngineManager);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IParentVault
    /// @notice Sets the initial active protocol adapter after deployment
    /// @param protocolId The protocol ID of the initial active strategy
    /// @dev This is called once after the adapter is deployed and registered inside the *same deploy script*, before operational use.
    /// @dev Precondition: Caller must have the DEFAULT_ADMIN_ROLE
    /// @dev Precondition: the initial active protocol adapter must not already be set
    /// @dev Precondition: the protocol ID must have a registered adapter
    function setInitialActiveProtocolAdapter(bytes32 protocolId)
        external
        nonReentrant
        onlyRole(Roles.DEFAULT_ADMIN_ROLE)
    {
        if (s_initialActiveProtocolAdapterSet) {
            revert ParentVault__InitialActiveProtocolAdapterAlreadySet();
        }

        address adapter = IAdapterRegistry(i_adapterRegistry).getAdapter(protocolId);
        if (adapter == address(0)) revert BaseVault__NoAdapterRegistered(protocolId);

        s_initialActiveProtocolAdapterSet = true;
        s_rebalance.activeStrategy.protocolId = protocolId;
        s_rebalance.activeStrategy.chainSelector = i_thisChainSelector;
        s_activeProtocolAdapter = adapter;

        emit InitialActiveProtocolAdapterSet(protocolId, adapter);
    }

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    //slither-disable-next-line missing-zero-check
    function setTreasury(address treasury) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        s_treasury = treasury;
        emit TreasurySet(treasury);
    }

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits USDC into the vault
    /// @param amount The amount of USDC to deposit
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Precondition: amount must meet the minimum deposit amount requirement
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    function deposit(uint256 amount) external nonReentrant whenNotPaused runPolicy returns (uint256 epochNonce) {
        if (amount < MIN_DEPOSIT_AMOUNT) revert ParentVault__AmountTooSmall(amount);
        epochNonce = s_epochNonce;
        /// @dev This condition should never be hit under normal operations as the epoch nonce is incremented on openNextEpoch
        if (s_epochs[epochNonce].status != Types.EpochStatus.OPEN) revert ParentVault__EpochNotOpen(epochNonce);

        s_deposits[msg.sender][epochNonce] += amount;
        s_epochs[epochNonce].totalDepositAmount += amount;

        IERC20(i_usdc).safeTransferFrom(msg.sender, address(this), amount);
        emit DepositSubmitted(epochNonce, msg.sender, amount);
    }

    /// @notice Submit USDC withdraw intent
    /// @param shareBurnAmount The amount of shares to burn for the withdraw
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their shareBurnAmount
    function withdraw(uint256 shareBurnAmount)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 epochNonce)
    {
        if (shareBurnAmount == 0) revert ParentVault__NoZeroAmount();
        epochNonce = s_epochNonce;
        /// @dev This condition should never be hit under normal operations as the epoch nonce is incremented on openNextEpoch
        if (s_epochs[epochNonce].status != Types.EpochStatus.OPEN) revert ParentVault__EpochNotOpen(epochNonce);

        s_withdraws[msg.sender][epochNonce] += shareBurnAmount;
        s_epochs[epochNonce].totalShareBurnAmount += shareBurnAmount;

        IERC20(i_share).safeTransferFrom(msg.sender, address(this), shareBurnAmount);

        emit WithdrawSubmitted(epochNonce, msg.sender, shareBurnAmount);
    }

    /// @notice Claim Yieldcoin shares after a deposit
    /// @notice Finalizes an individual deposit
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function claimShares(uint256 epochNonce)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 shareMintAmount)
    {
        Types.Epoch storage epoch = s_epochs[epochNonce];
        if (epoch.status != Types.EpochStatus.CLAIMABLE) revert ParentVault__EpochNotClaimable(epochNonce);

        uint256 usdcDepositAmount = s_deposits[msg.sender][epochNonce];
        if (usdcDepositAmount == 0) revert ParentVault__NoDeposit(msg.sender, epochNonce);

        if (usdcDepositAmount == epoch.remainingDepositClaimAmount) {
            shareMintAmount = epoch.remainingShareMintAmount;
        } else {
            shareMintAmount = usdcDepositAmount * epoch.remainingShareMintAmount / epoch.remainingDepositClaimAmount;
        }

        epoch.remainingDepositClaimAmount -= usdcDepositAmount;
        epoch.remainingShareMintAmount -= shareMintAmount;

        delete s_deposits[msg.sender][epochNonce];
        IShare(i_share).mint(msg.sender, shareMintAmount);

        emit DepositClaimed(epochNonce, msg.sender, shareMintAmount);
    }

    /// @notice Claim USDC after a withdraw
    /// @notice Finalizes an individual withdraw
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return usdcWithdrawAmount The amount of USDC withdrawn for the withdraw
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function claimUsdc(uint256 epochNonce)
        external
        nonReentrant
        whenNotPaused
        runPolicy
        returns (uint256 usdcWithdrawAmount)
    {
        Types.Epoch storage epoch = s_epochs[epochNonce];
        if (epoch.status != Types.EpochStatus.CLAIMABLE) revert ParentVault__EpochNotClaimable(epochNonce);

        uint256 shareBurnAmount = s_withdraws[msg.sender][epochNonce];
        if (shareBurnAmount == 0) revert ParentVault__NoWithdraw(msg.sender, epochNonce);

        if (shareBurnAmount == epoch.remainingShareBurnAmount) {
            usdcWithdrawAmount = epoch.remainingWithdrawClaimAmount;
        } else {
            usdcWithdrawAmount = shareBurnAmount * epoch.remainingWithdrawClaimAmount / epoch.remainingShareBurnAmount;
        }

        epoch.remainingShareBurnAmount -= shareBurnAmount;
        epoch.remainingWithdrawClaimAmount -= usdcWithdrawAmount;

        delete s_withdraws[msg.sender][epochNonce];

        IShare(i_share).burn(address(this), shareBurnAmount);

        emit WithdrawClaimed(epochNonce, msg.sender, usdcWithdrawAmount);
        if (usdcWithdrawAmount != 0) IERC20(i_usdc).safeTransfer(msg.sender, usdcWithdrawAmount);
    }

    /// @notice Cancels a deposit
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function cancelDeposit() external nonReentrant whenNotPaused runPolicy {
        uint256 epochNonce = s_epochNonce;
        if (s_epochs[epochNonce].status != Types.EpochStatus.OPEN) revert ParentVault__EpochNotOpen(epochNonce);

        uint256 usdcDepositAmount = s_deposits[msg.sender][epochNonce];
        if (usdcDepositAmount == 0) revert ParentVault__NoDeposit(msg.sender, epochNonce);
        delete s_deposits[msg.sender][epochNonce];
        s_epochs[epochNonce].totalDepositAmount -= usdcDepositAmount;

        IERC20(i_usdc).safeTransfer(msg.sender, usdcDepositAmount);

        emit DepositCancelled(epochNonce, msg.sender, usdcDepositAmount);
    }

    /// @notice Cancels a withdraw
    /// @dev This deletes the entire withdraw entry for the user and epoch nonce
    /// @dev Precondition: the function must not be reentered
    /// @dev Precondition: the contract must not be paused
    /// @dev Precondition: tx must be compliant with the policy
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function cancelWithdraw() external nonReentrant whenNotPaused runPolicy {
        uint256 epochNonce = s_epochNonce;
        if (s_epochs[epochNonce].status != Types.EpochStatus.OPEN) revert ParentVault__EpochNotOpen(epochNonce);

        uint256 shareBurnAmount = s_withdraws[msg.sender][epochNonce];
        if (shareBurnAmount == 0) revert ParentVault__NoWithdraw(msg.sender, epochNonce);
        delete s_withdraws[msg.sender][epochNonce];

        s_epochs[epochNonce].totalShareBurnAmount -= shareBurnAmount;

        IERC20(i_share).safeTransfer(msg.sender, shareBurnAmount);

        emit WithdrawCancelled(epochNonce, msg.sender, shareBurnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives CCIP messages
    /// @param message Any2EVMMessage.
    /// @dev Precondition: the message must be sent by an allowed sender (a crosschain vault mapped to an allowed source chain selector)
    /// @dev Precondition: the received token must be i_usdc
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        nonReentrant
        onlyAllowedSender(abi.decode(message.sender, (address)), message.sourceChainSelector)
    {
        uint256 receivedUsdcAmount = _validateReceivedTokenAndGetAmount(message);

        /// @dev data decodes to a uint256 epochNonce for epoch net withdraws and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));
        if (ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW) {
            uint256 epochNonce = abi.decode(data, (uint256));
            Types.Epoch storage epoch = s_epochs[epochNonce];

            /// @dev calculate the expected withdraw amount bridged back to the parent for the epoch
            uint256 expectedWithdrawUsdc = epoch.totalWithdrawClaimAmount - epoch.totalDepositAmount;
            /// @dev update the total withdraw claim amount
            epoch.totalWithdrawClaimAmount = epoch.totalDepositAmount + receivedUsdcAmount;
            epoch.remainingWithdrawClaimAmount = epoch.totalWithdrawClaimAmount;
            if (receivedUsdcAmount < expectedWithdrawUsdc) {
                emit EpochWithdrawAmountShort(epochNonce, expectedWithdrawUsdc, receivedUsdcAmount);
            }

            _finalizeEpoch(epochNonce);
        }
        /// @dev see BaseVault::_handleCCIPRebalance
        else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            bool success = _handleCCIPRebalance(rebalanceNonce, protocolId, receivedUsdcAmount);
            if (success) _finalizeRebalance(rebalanceNonce);
        } else {
            revert BaseVault__InvalidTxType(ccipTxType);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Closes an epoch and handles the net flow
    /// @notice Called by WorkflowRouter
    /// @notice The `netFlow` is `total USDC deposit amount` minus `calculated total USDC withdraw amount` for the given epoch
    ///         When `netFlow >= 0`: the epoch is CLAIMABLE
    ///         When `netFlow > 0` and the active strategy is local to this chain: the netFlow is deposited straight into the strategy
    ///         When `netFlow > 0` and the active strategy is remote to this chain: the netFlow is sent via CCIP to the strategy
    ///         When `netFlow < 0` and the active strategy is local to this chain: the netFlow is withdrawn from the strategy and the epoch is CLAIMABLE
    ///         When `netFlow < 0` and the active strategy is remote to this chain: EpochExecuting() event triggers CRE to write to strategy chain and the epoch is EXECUTING
    /// @notice Opens the next epoch
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @dev Precondition: the caller must have the EPOCH_OPERATOR_ROLE
    /// @dev Precondition: there must not be an active rebalance
    /// @dev Precondition: there must not be a stored recovery mode
    /// @dev Precondition: the previous epoch must be claimable, if a previous epoch exists
    /// @dev Precondition: the epoch must be open
    /// @dev Precondition: the epoch period must have exceeded the MIN_EPOCH_PERIOD
    /// @dev Precondition: there must have been a deposit or withdraw intent submitted during the epoch
    /// @dev Precondition: local strategy interactions must be successful
    /// @dev The previous-epoch guard prevents closing a later epoch while a prior
    ///      remote-withdraw epoch is still EXECUTING. This protects withdraw claimants:
    ///      if a child strategy withdraw fails, the owed USDC is not back on the Parent,
    ///      so affected users cannot claim until recoverFailedEpochWithdraw succeeds.
    ///
    ///      The guard intentionally does not make the Parent aware of pending child-side
    ///      remote-deposit recovery. Remote net-deposit epochs are marked CLAIMABLE on
    ///      the Parent before the Child deposit into the strategy completes. If that
    ///      child deposit fails, user claims are still live: withdrawer USDC is already
    ///      covered by netting/settlement, and depositors can claim shares minted at
    ///      epoch close. The remaining issue is yield drag from idle USDC on the Child,
    ///      so singleton child recovery plus workflow retry discipline is sufficient.
    /// @dev previousEpochNonce == 0 means no prior epoch exists (constructor sets s_epochNonce = 1).
    /// @notice The tvl parameter is provided by the CRE workflow via WorkflowRouter and is trusted
    ///         to accurately reflect the active strategy chain's TVL. The CRE workflow is audited to
    ///         the same standard as this contract. No onchain validation of this value is performed;
    ///         an incorrect value will corrupt epoch share accounting irrecoverably once any user
    ///         claims against the affected epoch.
    /// @dev Precondition: `tvl == 0 && s_totalShares > 0` will cause a revert
    /// @notice If TVL goes to zero with shares outstanding, closeEpoch will revert.
    ///         Anyone can call donate() to restore TVL; the next close will price shares against the donated amount.
    function closeEpoch(uint256 tvl) external nonReentrant onlyRole(Roles.EPOCH_OPERATOR_ROLE) {
        if (s_rebalance.state != Types.RebalanceState.NONE) revert ParentVault__RebalanceInProgress();

        _requireNoRecovery();

        uint256 epochNonce = s_epochNonce;
        uint256 previousEpochNonce = epochNonce - 1;
        if (previousEpochNonce != 0 && s_epochs[previousEpochNonce].status != Types.EpochStatus.CLAIMABLE) {
            revert ParentVault__EpochNotClaimable(previousEpochNonce);
        }

        Types.Epoch storage epoch = s_epochs[epochNonce];
        if (epoch.status != Types.EpochStatus.OPEN) revert ParentVault__EpochNotOpen(epochNonce);
        if (block.timestamp < epoch.openedAtTimestamp + MIN_EPOCH_PERIOD) {
            revert ParentVault__EpochTooShort(epochNonce);
        }
        if (epoch.totalDepositAmount == 0 && epoch.totalShareBurnAmount == 0) {
            revert ParentVault__EmptyEpoch(epochNonce);
        }

        // 1. Calculate gross price per share before performance fee dilution
        uint256 grossPricePerShare = _calculatePricePerShare(tvl);

        // 2. Collect performance fee on net yield and settle users at the post-fee price
        uint256 settlementPricePerShare = _collectPerformanceFee(epochNonce, tvl, grossPricePerShare);

        // 3. Calculate total withdraw USDC owed
        uint256 totalWithdrawUsdc = epoch.totalShareBurnAmount * settlementPricePerShare / SHARE_PRECISION;

        // 4. Calculate net flow (signed)
        // positive: deposits exceed withdrawals, surplus goes to strategy
        // negative: withdrawals exceed deposits, strategy must send USDC back
        int256 netFlow = int256(epoch.totalDepositAmount) - int256(totalWithdrawUsdc);

        // 5. Mint new shares and burn withdrawn shares
        uint256 newShares = epoch.totalDepositAmount * SHARE_PRECISION / settlementPricePerShare;
        s_totalShares = s_totalShares + newShares - epoch.totalShareBurnAmount; // @review gas optimization

        // 6. Store epoch settlement data
        epoch.totalWithdrawClaimAmount = totalWithdrawUsdc;
        epoch.pricePerShare = settlementPricePerShare;
        epoch.remainingDepositClaimAmount = epoch.totalDepositAmount;
        epoch.remainingShareMintAmount = newShares;
        epoch.remainingShareBurnAmount = epoch.totalShareBurnAmount;
        epoch.remainingWithdrawClaimAmount = totalWithdrawUsdc;
        epoch.closedAtTimestamp = block.timestamp;

        // 7. Transition epoch status and handle net flow
        /// @dev deposits exceeded withdraws
        if (netFlow >= 0) {
            epoch.status = Types.EpochStatus.CLAIMABLE;
            emit EpochClaimable(epochNonce);

            if (netFlow > 0) {
                address activeAdapter = s_activeProtocolAdapter;
                bool isLocalStrategy = activeAdapter != address(0);
                /// @dev active strategy is local
                if (isLocalStrategy) {
                    /// @dev true for revertOnFail because this is local
                    _executeDeposit(uint256(netFlow), true);
                    emit DepositToStrategySuccess(epochNonce, uint256(netFlow));
                }
                /// @dev active stategy is remote
                else {
                    _ccipSend(
                        uint256(netFlow),
                        s_rebalance.activeStrategy.chainSelector,
                        Types.CcipTx.EPOCH_NET_DEPOSIT,
                        abi.encode(epochNonce)
                    );
                }
            }
        }
        /// @dev withdraws exceeded deposits
        else {
            uint256 netWithdrawAmount = uint256(-netFlow);

            address activeAdapter = s_activeProtocolAdapter;
            bool isLocalStrategy = activeAdapter != address(0);
            /// @dev active strategy is local
            if (isLocalStrategy) {
                // local strategy: withdraw directly and finalise immediately
                /// @dev true for revertOnFail because this is local
                (, uint256 amountOut) = _executeWithdraw(netWithdrawAmount, true);
                epoch.totalWithdrawClaimAmount = epoch.totalDepositAmount + amountOut;
                epoch.remainingWithdrawClaimAmount = epoch.totalWithdrawClaimAmount;
                emit WithdrawFromStrategySuccess(epochNonce, amountOut);
                epoch.status = Types.EpochStatus.CLAIMABLE;
                emit EpochClaimable(epochNonce);
            }
            /// @dev active strategy is remote
            else {
                // remote strategy: CRE handles the withdrawal
                epoch.status = Types.EpochStatus.EXECUTING;
                emit EpochExecuting(epochNonce, netWithdrawAmount);
            }
        }

        _openNextEpoch();
    }

    /// @notice Calculates the USDC value of a Yieldcoin share token
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @return pricePerShare USDC value of a Yieldcoin share token
    function _calculatePricePerShare(uint256 tvl) internal view returns (uint256 pricePerShare) {
        uint256 totalShares = s_totalShares;
        if (totalShares != 0 && tvl != 0) {
            pricePerShare = tvl * SHARE_PRECISION / totalShares;
        } else if (totalShares == 0) {
            /// @dev Bootstrap: no shares exist yet, so define 1 USDC = 1 share.
            pricePerShare = SHARE_PRECISION; // 1e12
        } else {
            /// @dev This is a rare edgecase that should never happen. To prevent the protocol from being bricked, call donate(tvl)
            revert ParentVault__ZeroTvlWithOutstandingShares();
        }
    }

    /// @notice Opens the next epoch
    /// @notice Increments the epoch nonce and sets the status for the new epoch to OPEN
    function _openNextEpoch() internal {
        uint256 nextNonce = ++s_epochNonce;
        s_epochs[nextNonce].status = Types.EpochStatus.OPEN;
        s_epochs[nextNonce].openedAtTimestamp = block.timestamp;
        emit EpochOpen(nextNonce);
    }

    /// @notice Called by _ccipReceive when strategy sends net withdrawal proceeds back to Parent
    /// @param epochNonce The epoch being finalised
    function _finalizeEpoch(uint256 epochNonce) internal {
        Types.Epoch storage epoch = s_epochs[epochNonce];
        if (epoch.status != Types.EpochStatus.EXECUTING) revert ParentVault__EpochNotExecuting(epochNonce);

        epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice Initiates a rebalance from the current strategy to a new strategy
    /// @param newStrategy The new strategy to rebalance to
    /// @notice This is called by the WorkflowRouter
    /// @dev Precondition: the caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: A rebalance must not already be in progress
    /// @dev Precondiiton: newStrategy must not be the same as the current active strategy
    /// @dev Precondition: An epoch must not be EXECUTING
    /// @dev Precondition: If current/active/previous strategy is on this chain, withdrawing tvl from the old strategy must succeed
    /// @dev Precondition: If current/active/previous strategy and newStrategy is on this chain, depositing tvl into the new strategy must succeed
    /// @dev Precondition: there must not be a stored recovery mode
    function initiateRebalance(Types.Strategy memory newStrategy)
        external
        nonReentrant
        onlyRole(Roles.REBALANCE_OPERATOR_ROLE)
    {
        // revert if rebalance is already in progress
        if (s_rebalance.state != Types.RebalanceState.NONE) revert ParentVault__RebalanceInProgress();

        _requireNoRecovery();

        // revert if the new strategy is the same as the active strategy
        if (
            s_rebalance.activeStrategy.protocolId == newStrategy.protocolId
                && s_rebalance.activeStrategy.chainSelector == newStrategy.chainSelector
        ) {
            revert ParentVault__SameStrategy();
        }

        // @review revert if currentEpochNonce == 1

        // revert if an epoch is in flight
        uint256 currentEpochNonce = s_epochNonce;
        // Cannot rebalance if any epoch is still EXECUTING
        // The previous epoch may still be awaiting CCIP confirmation
        if (currentEpochNonce > 1 && s_epochs[currentEpochNonce - 1].status == Types.EpochStatus.EXECUTING) {
            revert ParentVault__EpochExecuting(currentEpochNonce - 1);
        }

        s_rebalance.state = Types.RebalanceState.REBALANCING;
        s_rebalance.pendingStrategy = newStrategy;
        s_rebalance.lastRebalanceInitiatedTimestamp = block.timestamp;
        emit RebalanceInitiated(s_rebalance.nonce, newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev check if old/previously-active strategy chain selector is this one
        //slither-disable-next-line incorrect-equality
        if (s_rebalance.activeStrategy.chainSelector == i_thisChainSelector) {
            // withdraw from local strategy
            (, uint256 amountOut) = _executeWithdraw(type(uint256).max, true);
            emit RebalanceWithdrawSuccess(s_rebalance.nonce, amountOut);
            if (newStrategy.chainSelector == i_thisChainSelector) {
                // deposit into local strategy
                _setActiveAdapter(newStrategy.protocolId);
                _executeDeposit(amountOut, true);
                emit RebalanceDepositSuccess(s_rebalance.nonce, amountOut);
                _finalizeRebalance(s_rebalance.nonce);
            } else {
                // ccip send to new strategy chain
                s_activeProtocolAdapter = address(0);
                _ccipSend(
                    amountOut,
                    newStrategy.chainSelector,
                    Types.CcipTx.REBALANCE,
                    abi.encode(s_rebalance.nonce, newStrategy.protocolId)
                );
            }
        } // else, CRE is trigged by the event to write to old strategy chain and rebalance/bridge from there
    }

    /// @notice Completes a rebalance
    /// @notice The WorkflowRouter calls this
    /// @dev Precondition: caller must have REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: there must not be a stored recovery mode
    function completeRebalance(uint256 rebalanceNonce) external nonReentrant onlyRole(Roles.REBALANCE_OPERATOR_ROLE) {
        _requireNoRecovery();
        _finalizeRebalance(rebalanceNonce);
    }

    /// @notice Finalizes a rebalance
    /// @param rebalanceNonce the nonce of the rebalance to finalize
    /// @dev Precondition: a rebalance must be in progress
    /// @dev Precondition: rebalanceNonce must be the current rebalanceNonce @review we can probably delete this param
    /// @notice Collects a management fee based on time elapsed since the last rebalance completed
    function _finalizeRebalance(uint256 rebalanceNonce) internal {
        if (s_rebalance.state != Types.RebalanceState.REBALANCING) revert ParentVault__NoRebalanceInProgress();
        if (s_rebalance.nonce != rebalanceNonce) revert ParentVault__InvalidRebalanceNonce(rebalanceNonce);

        uint256 lastRebalanceCompletedTimestamp = s_rebalance.lastRebalanceCompletedTimestamp;

        s_rebalance.activeStrategy = s_rebalance.pendingStrategy;
        s_rebalance.state = Types.RebalanceState.NONE;
        s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;
        delete s_rebalance.pendingStrategy;

        emit RebalanceCompleted(rebalanceNonce);
        ++s_rebalance.nonce;
        _collectManagementFee(rebalanceNonce, lastRebalanceCompletedTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovers a failed rebalance deposit into the active Parent strategy and finalizes the rebalance
    /// @dev Precondition: rebalance deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: rebalance state must be REBALANCING
    /// @dev Precondition: pending recovery nonce must be the current nonce
    /// @notice This Parent implemention overrides the BaseVault because we can finalize the rebalance in same atomic tx
    function recoverFailedRebalanceDeposit() external override(BaseVault, IParentVault) {
        (uint256 rebalanceNonce,) = _recoverFailedRebalanceDeposit();
        _finalizeRebalance(rebalanceNonce);
    }

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates and collects the management fee based on time elapsed since the last rebalance completed
    /// @notice Roughly 1% of the TVL is taken annually. The actual amount is proportional to time elapsed and current total shares
    /// @notice The management fee is taken in Yieldcoin share tokens and minted to s_treasury
    /// @param rebalanceNonce The nonce of the rebalance collecting the fee
    /// @param lastRebalanceCompletedTimestamp The timestamp when the rebalance last completed
    function _collectManagementFee(uint256 rebalanceNonce, uint256 lastRebalanceCompletedTimestamp) internal {
        uint256 elapsed = block.timestamp - lastRebalanceCompletedTimestamp;
        uint256 totalShares = s_totalShares;
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        uint256 feeShares = (totalShares * MANAGEMENT_FEE_BPS * elapsed + denominator - 1) / denominator;
        if (feeShares != 0) {
            s_totalShares = totalShares + feeShares;
            IShare(i_share).mint(s_treasury, feeShares);
            emit ManagementFeeCollected(rebalanceNonce, feeShares);
        }
    }

    /// @notice Collects performance fee when the gross price exceeds the high water mark
    /// @param epochNonce The epoch nonce collecting the fee
    /// @param tvl The strategy TVL before current epoch deposits and withdrawals settle
    /// @param grossPricePerShare The epoch price per share before performance fee dilution
    /// @return settlementPricePerShare The epoch price per share after performance fee dilution
    function _collectPerformanceFee(uint256 epochNonce, uint256 tvl, uint256 grossPricePerShare)
        internal
        returns (uint256 settlementPricePerShare)
    {
        uint256 highWaterMark = s_performanceFeeHighWaterMark;
        if (grossPricePerShare <= highWaterMark) return grossPricePerShare;

        uint256 totalShares = s_totalShares;
        uint256 yieldPerShare = grossPricePerShare - highWaterMark;
        /// @dev totalYield is the USDC value created above the prior after-fee high water mark.
        uint256 totalYield = _ceilDiv(yieldPerShare * totalShares, SHARE_PRECISION);
        /// @dev feeUsdc is 7.77% of net yield, rounded up in favor of the protocol.
        uint256 feeUsdc = _ceilDiv(totalYield * PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);

        /// @dev Defensive guard: if rounding or bad TVL input would make the fee consume
        ///      all TVL, skip fee collection for this epoch and leave the HWM unchanged.
        if (feeUsdc >= tvl) {
            return grossPricePerShare;
        }

        /// @dev Mint enough shares so treasury's post-mint ownership is worth feeUsdc:
        ///      feeShares / (totalShares + feeShares) * tvl = feeUsdc
        ///      feeShares = feeUsdc * totalShares / (tvl - feeUsdc)
        uint256 feeShares = _ceilDiv(feeUsdc * totalShares, tvl - feeUsdc);

        if (feeShares != 0) {
            s_totalShares = totalShares + feeShares;
            IShare(i_share).mint(s_treasury, feeShares);
            emit PerformanceFeeCollected(epochNonce, feeShares, highWaterMark);
        }

        // @review definite gas optimization in here with s_totalShares reads
        settlementPricePerShare = _calculatePricePerShare(tvl);
        s_performanceFeeHighWaterMark = settlementPricePerShare;
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL VIEW AND PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Divides and rounds up
    /// @param numerator The numerator
    /// @param denominator The denominator
    /// @return result The rounded-up quotient
    // @review replacing this with OZ mulDiv or solady
    function _ceilDiv(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        result = numerator == 0 ? 0 : (numerator - 1) / denominator + 1;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the rebalance state
    /// @return rebalance The current rebalance state
    function getRebalance() external view returns (Types.Rebalance memory rebalance) {
        rebalance = s_rebalance;
    }

    /// @notice Returns the epoch data for a given epoch nonce
    /// @param epochNonce The epoch nonce to query
    /// @return epoch The epoch data including status, deposit/withdraw totals, price per share, and timestamps
    function getEpoch(uint256 epochNonce) external view returns (Types.Epoch memory epoch) {
        epoch = s_epochs[epochNonce];
    }

    /// @notice Returns the current epoch nonce
    /// @return epochNonce The nonce of the currently active epoch
    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = s_epochNonce;
    }

    /// @notice Returns the total number of Yieldcoin shares tracked by the vault
    /// @dev This leads the on-chain share supply: updated at epoch close, minted/burned lazily at claim time
    /// @return totalShares The total share count tracked by the vault
    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = s_totalShares;
    }

    /// @notice Returns the USDC deposit amount submitted by a user for a given epoch
    /// @param user The address of the depositor
    /// @param epochNonce The epoch nonce of the deposit
    /// @return amount The USDC amount the user deposited into the given epoch
    function getDepositAmount(address user, uint256 epochNonce) external view returns (uint256 amount) {
        amount = s_deposits[user][epochNonce];
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
        shareBurnAmount = s_withdraws[user][epochNonce];
    }

    /// @inheritdoc IParentVault
    function getInitialActiveProtocolAdapterSet() external view returns (bool initialActiveProtocolAdapterSet) {
        initialActiveProtocolAdapterSet = s_initialActiveProtocolAdapterSet;
    }

    /// @inheritdoc IParentVault
    function getPerformanceFeeHighWaterMark() external view returns (uint256 highWaterMark) {
        highWaterMark = s_performanceFeeHighWaterMark;
    }

    /// @notice Gets the operator multisig for protocol fees
    /// @return treasury The address of the operator multisig for protocol fees
    function getTreasury() external view returns (address treasury) {
        treasury = s_treasury;
    }

    /// @notice Gets the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share) {
        share = i_share;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Resolves the owner() conflict between Ownable (via PolicyProtected) and
    ///         AccessControlDefaultAdminRules. Returns the default admin address.
    function owner() public view override(Ownable, AccessControlDefaultAdminRules) returns (address) {
        return AccessControlDefaultAdminRules.owner();
    }

    /// @notice Attaches a policy engine.
    /// @dev Precondition: Caller must have the POLICY_ENGINE_MANAGER_ROLE
    /// @param policyEngine The policy engine to attach
    function attachPolicyEngine(address policyEngine) external override onlyRole(Roles.POLICY_ENGINE_MANAGER_ROLE) {
        _attachPolicyEngine(policyEngine);
    }

    function supportsInterface(bytes4 interfaceId) public pure override(BaseVault, PolicyProtected) returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId
            || interfaceId == type(IPolicyProtected).interfaceId;
    }

    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain
    ///         Returns 0 if this chain is not the active strategy chain
    /// @return tvl The Yieldcoin TVL
    /// @notice The Child Vault implementation includes s_epochDepositRecovery.amount
    /// @notice Returns 0 if the TVL is in transit over CCIP. This should not be read onchain when Parent state is REBALANCING
    function _getTVL() internal view override returns (uint256 tvl) {
        address activeAdapter = s_activeProtocolAdapter;
        if (activeAdapter == address(0)) return 0;
        tvl = IProtocolAdapter(activeAdapter).getTVL();
        if (tvl == 0) tvl = s_rebalanceDepositRecovery.amount;
    }
}
