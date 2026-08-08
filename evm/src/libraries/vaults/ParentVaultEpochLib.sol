// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {ParentVaultFeesLib} from "./ParentVaultFeesLib.sol";
import {ParentVaultMathLib} from "./ParentVaultMathLib.sol";
import {Types} from "../Types.sol";

/// @title Yieldcoin v2 ParentVault epoch lifecycle logic library
/// @author @contractlevel
/// @notice Handles ParentVault epoch settlement while ParentVault keeps external strategy and CCIP actions.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultEpochLib {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Minimum time an epoch must be open
    uint256 internal constant MIN_EPOCH_PERIOD = 1 hours;

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice The action ParentVault must take after closeEpoch settles net flow
    enum ExternalAction {
        NONE, // 0: no net flow to execute (deposits and withdraws netted to zero)
        DEPOSIT_TO_LOCAL_STRATEGY, // 1: net deposit, active strategy is on this chain
        SEND_DEPOSIT_TO_REMOTE_STRATEGY, // 2: net deposit, active strategy is on a remote chain
        WITHDRAW_FROM_LOCAL_STRATEGY, // 3: net withdraw, active strategy is on this chain
        WAIT_FOR_REMOTE_WITHDRAW // 4: net withdraw, active strategy is on a remote chain
    }

    /// @notice The external action ParentVault should execute after closeEpoch settlement
    /// @param epochNonce The nonce of the epoch that was just closed
    /// @param action The action ParentVault must take
    /// @param amount The net deposit or withdraw amount to act on
    /// @param totalDepositAmount The epoch's total deposit amount, needed by ParentVault to finalize a local net withdraw
    struct CloseEpochExternalAction {
        uint256 epochNonce;
        ExternalAction action;
        uint256 amount;
        uint256 totalDepositAmount;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    /// @notice Emitted when an epoch is open
    /// @param epochNonce The nonce of the open epoch
    event EpochOpen(uint256 indexed epochNonce);
    /// @notice Emitted when a remote net-deposit epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of asset being deposited on the remote strategy chain
    event EpochDepositExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a remote net-withdraw epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of asset that needs to be withdrawn
    event EpochWithdrawExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);

    /*//////////////////////////////////////////////////////////////
                                EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Settles the current epoch and returns the external action ParentVault must execute.
    /// @param $ ParentVault namespaced storage
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @param minDepositAmount The minimum deposit amount
    /// @param isLocalStrategy Whether this chain currently has the active strategy adapter
    /// @return externalAction The external action, epoch nonce, net amount, and total deposit amount ParentVault
    ///         needs to execute the action and finalize the epoch after settlement
    function closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 tvl,
        address share,
        uint256 sharePrecision,
        uint256 assetPrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    ) public returns (CloseEpochExternalAction memory externalAction) {
        externalAction = _closeEpoch($, tvl, share, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);
    }

    /// @notice Settles the current epoch and returns the external action ParentVault must execute.
    /// @param $ ParentVault namespaced storage
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @param minDepositAmount The minimum deposit amount
    /// @param isLocalStrategy Whether this chain currently has the active strategy adapter
    /// @return externalAction The external action, epoch nonce, net amount, and total deposit amount ParentVault
    ///         needs to execute the action and finalize the epoch after settlement
    /// @dev Precondition: no rebalance may be in progress
    /// @dev Precondition: the previous epoch (if one exists) must be CLAIMABLE
    /// @dev Precondition: the current epoch must be OPEN and have been open for at least MIN_EPOCH_PERIOD
    /// @dev Precondition: the epoch must have nonzero deposits or withdrawals
    /// @dev Collects the performance fee and computes the settlement price per share before computing net flow
    /// @dev Precondition: settlement must not mint zero shares for a minimum-size depositor
    function _closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 tvl,
        address share,
        uint256 sharePrecision,
        uint256 assetPrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    ) internal returns (CloseEpochExternalAction memory externalAction) {
        if ($.s_rebalance.state != Types.RebalanceState.NONE) {
            revert IParentVault.ParentVault__RebalanceInProgress();
        }

        uint256 epochNonce = $.s_epochNonce;
        uint256 previousEpochNonce = epochNonce - 1;
        if (previousEpochNonce != 0 && $.s_epochs[previousEpochNonce].status != Types.EpochStatus.CLAIMABLE) {
            revert IParentVault.ParentVault__EpochNotClaimable(previousEpochNonce);
        }

        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);
        if (block.timestamp < s_epoch.openedAtTimestamp + MIN_EPOCH_PERIOD) {
            revert IParentVault.ParentVault__EpochTooShort(epochNonce);
        }
        uint256 totalDepositAmount = s_epoch.totalDepositAmount;
        uint256 totalShareBurnAmount = s_epoch.totalShareBurnAmount;
        if (totalDepositAmount == 0 && totalShareBurnAmount == 0) {
            revert IParentVault.ParentVault__EmptyEpoch(epochNonce);
        }

        uint256 totalShares = $.s_totalShares;
        uint256 grossPricePerShare =
            ParentVaultFeesLib._calculatePricePerShare(tvl, totalShares, sharePrecision, assetPrecision);
        (uint256 settlementPricePerShare, uint256 feeShares) = ParentVaultFeesLib._collectPerformanceFee(
            $, epochNonce, tvl, grossPricePerShare, totalShares, share, sharePrecision, assetPrecision
        );

        uint256 totalWithdraw =
            ParentVaultMathLib._mulDivDown(totalShareBurnAmount, settlementPricePerShare, sharePrecision);
        int256 netFlow = int256(totalDepositAmount) - int256(totalWithdraw);

        uint256 newShares = ParentVaultFeesLib._calculateNewShares(
            tvl, totalDepositAmount, totalShares + feeShares, sharePrecision, assetPrecision
        );
        if (totalDepositAmount != 0 && newShares * minDepositAmount < totalDepositAmount) {
            revert IParentVault.ParentVault__DepositWouldMintZeroShares();
        }
        /// @dev This is the sole write to s_totalShares for the epoch: totalShares is the pre-fee value
        ///      read above, feeShares folds in any performance-fee dilution _collectPerformanceFee minted
        ///      (without itself writing storage - see its NatSpec), and newShares/totalShareBurnAmount
        ///      fold in this epoch's deposits/withdraws.
        $.s_totalShares = totalShares + feeShares + newShares - totalShareBurnAmount;

        s_epoch.pricePerShare = settlementPricePerShare;
        s_epoch.remainingDepositClaimAmount = totalDepositAmount;
        s_epoch.remainingShareMintAmount = newShares;
        s_epoch.remainingShareBurnAmount = totalShareBurnAmount;

        bool isSynchronousLocalWithdraw = isLocalStrategy && netFlow < 0;
        if (!isSynchronousLocalWithdraw) {
            // WITHDRAW_FROM_LOCAL_STRATEGY resolves synchronously within the same
            // transaction via finalizeLocalNetWithdraw, which writes the actual (not
            // theoretical) totalWithdrawClaimAmount/remainingWithdrawClaimAmount once the
            // real adapter withdraw amount is known - writing the theoretical `totalWithdraw`
            // here would just be overwritten moments later. Every other case (both deposit
            // branches, and the remote-withdraw path - which resolves in a later transaction,
            // so the theoretical value must be observable in the meantime) still needs it.
            s_epoch.totalWithdrawClaimAmount = totalWithdraw;
            s_epoch.remainingWithdrawClaimAmount = totalWithdraw;
        }

        externalAction.epochNonce = epochNonce;
        externalAction.totalDepositAmount = totalDepositAmount;
        if (netFlow >= 0) {
            if (netFlow == 0 || isLocalStrategy) {
                s_epoch.status = Types.EpochStatus.CLAIMABLE;
                emit EpochClaimable(epochNonce);
            } else {
                s_epoch.status = Types.EpochStatus.EXECUTING;
                emit EpochDepositExecuting(epochNonce, uint256(netFlow));
            }

            if (netFlow == 0) return externalAction;

            externalAction.amount = uint256(netFlow);
            if (isLocalStrategy) {
                externalAction.action = ExternalAction.DEPOSIT_TO_LOCAL_STRATEGY;
            } else {
                externalAction.action = ExternalAction.SEND_DEPOSIT_TO_REMOTE_STRATEGY;
            }
        } else {
            uint256 netWithdrawAmount = uint256(-netFlow);
            externalAction.amount = netWithdrawAmount;
            if (isLocalStrategy) {
                externalAction.action = ExternalAction.WITHDRAW_FROM_LOCAL_STRATEGY;
            } else {
                externalAction.action = ExternalAction.WAIT_FOR_REMOTE_WITHDRAW;
                s_epoch.status = Types.EpochStatus.EXECUTING;
                emit EpochWithdrawExecuting(epochNonce, netWithdrawAmount);
            }
        }
    }

    /// @notice Completes the most recently closed remote net-deposit epoch.
    /// @param $ ParentVault namespaced storage
    /// @dev Precondition: at least one epoch must have completed
    /// @dev Precondition: the previous epoch must have positive net flow and be EXECUTING
    function completeEpochDeposit(ParentVaultStore.ParentVaultStorage storage $) public {
        _completeEpochDeposit($);
    }

    /// @notice Completes the most recently closed remote net-deposit epoch.
    /// @param $ ParentVault namespaced storage
    function _completeEpochDeposit(ParentVaultStore.ParentVaultStorage storage $) internal {
        uint256 currentEpochNonce = $.s_epochNonce;
        if (currentEpochNonce == 1) revert IParentVault.ParentVault__NoCompletedEpoch();

        uint256 epochNonce = currentEpochNonce - 1;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.totalDepositAmount <= s_epoch.totalWithdrawClaimAmount) {
            revert IParentVault.ParentVault__EpochNotNetDeposit(epochNonce);
        }

        _finalizeEpoch(s_epoch, epochNonce);
    }

    /// @notice Finalizes a local net-withdraw epoch after ParentVault receives actual adapter output.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce being finalized
    /// @param totalDepositAmount The epoch's total deposit amount, as already settled by `closeEpoch`
    /// @param amountOut The actual amount withdrawn from the local strategy
    function finalizeLocalNetWithdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 totalDepositAmount,
        uint256 amountOut
    ) public {
        _finalizeLocalNetWithdraw($, epochNonce, totalDepositAmount, amountOut);
    }

    /// @notice Finalizes a local net-withdraw epoch after ParentVault receives actual adapter output.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce being finalized
    /// @param totalDepositAmount The epoch's total deposit amount, as already settled by `closeEpoch`
    /// @param amountOut The actual amount withdrawn from the local strategy
    function _finalizeLocalNetWithdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 totalDepositAmount,
        uint256 amountOut
    ) internal {
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        uint256 totalWithdrawClaimAmount = totalDepositAmount + amountOut;
        s_epoch.totalWithdrawClaimAmount = totalWithdrawClaimAmount;
        s_epoch.remainingWithdrawClaimAmount = totalWithdrawClaimAmount;
        s_epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }

    /// @notice Marks a settled epoch as claimable.
    /// @param s_epoch The epoch's storage struct
    /// @param epochNonce The nonce of the epoch being finalized
    /// @dev Precondition: the epoch's status must be EXECUTING
    function _finalizeEpoch(Types.Epoch storage s_epoch, uint256 epochNonce) internal {
        if (s_epoch.status != Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochNotExecuting(epochNonce);
        }

        s_epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }

    /// @notice Opens the next epoch.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce just closed by `closeEpoch`, as the next nonce is `epochNonce + 1`
    function openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) public {
        _openNextEpoch($, epochNonce);
    }

    /// @notice Opens the next epoch.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce just closed by `closeEpoch`, as the next nonce is `epochNonce + 1`
    function _openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) internal {
        uint256 nextNonce = epochNonce + 1;
        $.s_epochNonce = nextNonce;
        $.s_epochs[nextNonce].status = Types.EpochStatus.OPEN;
        $.s_epochs[nextNonce].openedAtTimestamp = block.timestamp;
        emit EpochOpen(nextNonce);
    }
}
