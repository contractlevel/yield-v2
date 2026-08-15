// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {ParentVaultMathLib} from "./ParentVaultMathLib.sol";
import {Types} from "../Types.sol";
import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";

/// @title Yieldcoin v2 ParentVault epoch lifecycle logic library
/// @author @contractlevel
/// @notice Handles ParentVault epoch settlement while ParentVault keeps external strategy and CCIP actions
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context
library ParentVaultEpochLib {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeCastLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Minimum time an epoch must be open
    uint256 internal constant MIN_EPOCH_PERIOD = 1 hours;

    /// @notice The action ParentVault must take after closeEpoch settles net flow
    /// @param NONE No external action because deposits and withdraws netted to zero
    /// @param DEPOSIT_TO_LOCAL_STRATEGY Deposit the positive net flow into the local active strategy
    /// @param SEND_DEPOSIT_TO_REMOTE_STRATEGY Send the positive net flow to the remote active strategy
    /// @param WITHDRAW_FROM_LOCAL_STRATEGY Withdraw the negative net flow from the local active strategy
    /// @param WAIT_FOR_REMOTE_WITHDRAW Wait for the remote active strategy to return the negative net flow
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
    /// @param totalDepositAmount The epoch's total deposit amount, used to finalize a local net withdraw
    struct CloseEpochExternalAction {
        uint256 epochNonce;
        ExternalAction action;
        uint256 amount;
        uint256 totalDepositAmount;
    }

    /// @notice Parameters used to validate and settle the current epoch
    /// @param expectedEpochNonce The current epoch nonce expected by the caller
    /// @param tvl The underlying-asset value of the active strategy before settlement
    /// @param sharePrecision The precision factor of the Yieldcoin share token
    /// @param assetPrecision The precision factor of the underlying asset
    /// @param minDepositAmount The minimum underlying-asset deposit amount
    /// @param isLocalStrategy Whether the active strategy is on the ParentVault chain
    struct CloseEpochParams {
        uint256 expectedEpochNonce;
        uint256 tvl;
        uint256 sharePrecision;
        uint256 assetPrecision;
        uint256 minDepositAmount;
        bool isLocalStrategy;
    }

    /// @notice Intermediate accounting values calculated while settling an epoch
    /// @param totalDepositAmount The total underlying asset submitted for deposit in the epoch
    /// @param totalShareBurnAmount The total shares submitted for withdrawal in the epoch
    /// @param totalShares The authoritative share count immediately before epoch settlement
    /// @param totalWithdraw The underlying asset allocated to all withdrawal intents at the supplied TVL
    /// @param newShares The shares allocated to all deposit intents at the supplied TVL
    /// @param netFlow Deposits minus withdrawal allocations, denominated in the underlying asset
    struct EpochAccounting {
        uint256 totalDepositAmount;
        uint256 totalShareBurnAmount;
        uint256 totalShares;
        uint256 totalWithdraw;
        uint256 newShares;
        int256 netFlow;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL
    /// @notice Emitted when an epoch is open
    /// @param epochNonce The nonce of the open epoch
    event EpochOpen(uint256 indexed epochNonce);
    /// @notice Emitted when a remote net-deposit epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of underlying asset being deposited on the remote strategy chain
    event EpochDepositExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a remote net-withdraw epoch is executing
    /// @param epochNonce The nonce of the executing epoch
    /// @param amount The amount of underlying asset to withdraw
    event EpochWithdrawExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);

    /*//////////////////////////////////////////////////////////////
                                EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Settles the current epoch and returns the external action ParentVault must execute
    /// @param $ ParentVault namespaced storage
    /// @param expectedEpochNonce The current epoch nonce expected by the caller
    /// @param tvl The underlying-asset value of the active strategy before settling the current epoch
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor used for bootstrap share allocation
    /// @param minDepositAmount The minimum deposit amount
    /// @param isLocalStrategy Whether this chain currently has the active strategy adapter
    /// @return externalAction The external action, epoch nonce, net amount, and total deposit amount ParentVault
    ///         needs to execute the action and finalize the epoch after settlement
    /// @dev The caller-supplied TVL is trusted and is not validated against onchain strategy state
    /// @dev Reverts if expectedEpochNonce does not match the current epoch nonce
    /// @dev Reverts if a rebalance is in progress
    /// @dev Reverts if the preceding epoch is not claimable
    /// @dev Reverts if the current epoch is not open or has been open for less than MIN_EPOCH_PERIOD
    /// @dev Reverts if the epoch contains neither deposits nor withdraw intents
    /// @dev Reverts if TVL is zero while shares are outstanding or the scaled TVL-to-share ratio is zero
    /// @dev Reverts if shares are submitted for withdrawal while the authoritative share supply is zero
    /// @dev Reverts if deposit settlement would allocate zero shares to a minimum-size deposit
    /// @dev Reverts if totalDepositAmount or totalWithdraw cannot be safely cast to int256
    function closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 expectedEpochNonce,
        uint256 tvl,
        uint256 sharePrecision,
        uint256 assetPrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    ) public returns (CloseEpochExternalAction memory externalAction) {
        externalAction = _closeEpoch(
            $, expectedEpochNonce, tvl, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy
        );
    }

    /// @notice Settles the current epoch and returns the external action ParentVault must execute
    /// @param $ ParentVault namespaced storage
    /// @param expectedEpochNonce The current epoch nonce expected by the caller
    /// @param tvl The underlying-asset value of the active strategy before settling the current epoch
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor used for bootstrap share allocation
    /// @param minDepositAmount The minimum deposit amount
    /// @param isLocalStrategy Whether this chain currently has the active strategy adapter
    /// @return externalAction The external action, epoch nonce, net amount, and total deposit amount ParentVault
    ///         needs to execute the action and finalize the epoch after settlement
    /// @dev The caller-supplied TVL is trusted and is not validated against onchain strategy state
    /// @dev Reverts if expectedEpochNonce does not match the current epoch nonce
    /// @dev Reverts if a rebalance is in progress
    /// @dev Reverts if the preceding epoch is not claimable
    /// @dev Reverts if the current epoch is not open or has been open for less than MIN_EPOCH_PERIOD
    /// @dev Reverts if the epoch contains neither deposits nor withdraw intents
    /// @dev Reverts if TVL is zero while shares are outstanding or the scaled TVL-to-share ratio is zero
    /// @dev Reverts if shares are submitted for withdrawal while the authoritative share supply is zero
    /// @dev Reverts if deposit settlement would allocate zero shares to a minimum-size deposit
    /// @dev Reverts if totalDepositAmount or totalWithdraw cannot be safely cast to int256
    function _closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 expectedEpochNonce,
        uint256 tvl,
        uint256 sharePrecision,
        uint256 assetPrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    ) internal returns (CloseEpochExternalAction memory externalAction) {
        CloseEpochParams memory params = CloseEpochParams({
            expectedEpochNonce: expectedEpochNonce,
            tvl: tvl,
            sharePrecision: sharePrecision,
            assetPrecision: assetPrecision,
            minDepositAmount: minDepositAmount,
            isLocalStrategy: isLocalStrategy
        });
        externalAction = _closeEpoch($, params);
    }

    function _closeEpoch(ParentVaultStore.ParentVaultStorage storage $, CloseEpochParams memory params)
        private
        returns (CloseEpochExternalAction memory externalAction)
    {
        uint256 epochNonce = $.s_epochNonce;
        if (params.expectedEpochNonce != epochNonce) {
            revert IParentVault.ParentVault__InvalidEpochNonce(params.expectedEpochNonce);
        }
        if ($.s_rebalance.state != Types.RebalanceState.NONE) {
            revert IParentVault.ParentVault__RebalanceInProgress();
        }

        uint256 previousEpochNonce = epochNonce - 1;
        if (previousEpochNonce != 0 && $.s_epochs[previousEpochNonce].status != Types.EpochStatus.CLAIMABLE) {
            revert IParentVault.ParentVault__EpochNotClaimable(previousEpochNonce);
        }

        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);
        if (block.timestamp < s_epoch.openedAtTimestamp + MIN_EPOCH_PERIOD) {
            revert IParentVault.ParentVault__EpochTooShort(epochNonce);
        }
        EpochAccounting memory accounting;
        accounting.totalDepositAmount = s_epoch.totalDepositAmount;
        accounting.totalShareBurnAmount = s_epoch.totalShareBurnAmount;
        if (accounting.totalDepositAmount == 0 && accounting.totalShareBurnAmount == 0) {
            revert IParentVault.ParentVault__EmptyEpoch(epochNonce);
        }

        accounting.totalShares = $.s_totalShares;
        if (accounting.totalShares != 0) {
            if (params.tvl == 0) revert IParentVault.ParentVault__ZeroTvlWithOutstandingShares();
            if (ParentVaultMathLib._mulDivDown(params.tvl, params.sharePrecision, accounting.totalShares) == 0) {
                revert IParentVault.ParentVault__ZeroPricePerShare();
            }

            accounting.totalWithdraw =
                ParentVaultMathLib._mulDivDown(accounting.totalShareBurnAmount, params.tvl, accounting.totalShares);
            accounting.newShares =
                ParentVaultMathLib._mulDivDown(accounting.totalDepositAmount, accounting.totalShares, params.tvl);
        } else {
            if (accounting.totalShareBurnAmount != 0) {
                revert IParentVault.ParentVault__ShareBurnWithZeroTotalShares();
            }
            accounting.newShares = ParentVaultMathLib._mulDivDown(
                accounting.totalDepositAmount, params.sharePrecision, params.assetPrecision
            );
        }

        accounting.netFlow = accounting.totalDepositAmount.toInt256() - accounting.totalWithdraw.toInt256();
        if (
            accounting.totalDepositAmount != 0
                && accounting.newShares * params.minDepositAmount < accounting.totalDepositAmount
        ) {
            revert IParentVault.ParentVault__DepositWouldMintZeroShares();
        }
        // This is the sole write to s_totalShares for the epoch and folds in the epoch's
        // deposit allocation and submitted withdrawals.
        $.s_totalShares = accounting.totalShares + accounting.newShares - accounting.totalShareBurnAmount;

        s_epoch.remainingDepositClaimAmount = accounting.totalDepositAmount;
        s_epoch.remainingShareMintAmount = accounting.newShares;
        s_epoch.remainingShareBurnAmount = accounting.totalShareBurnAmount;

        bool isSynchronousLocalWithdraw = params.isLocalStrategy && accounting.netFlow < 0;
        if (!isSynchronousLocalWithdraw) {
            // WITHDRAW_FROM_LOCAL_STRATEGY resolves synchronously within the same
            // transaction via finalizeLocalNetWithdraw, which writes the actual (not
            // theoretical) totalWithdrawClaimAmount/remainingWithdrawClaimAmount once the
            // real adapter withdraw amount is known - writing the theoretical `totalWithdraw`
            // here would just be overwritten moments later. Every other case (both deposit
            // branches, and the remote-withdraw path - which resolves in a later transaction,
            // so the theoretical value must be observable in the meantime) still needs it.
            s_epoch.totalWithdrawClaimAmount = accounting.totalWithdraw;
            s_epoch.remainingWithdrawClaimAmount = accounting.totalWithdraw;
        }

        externalAction.epochNonce = epochNonce;
        externalAction.totalDepositAmount = accounting.totalDepositAmount;
        if (accounting.netFlow >= 0) {
            if (accounting.netFlow == 0 || params.isLocalStrategy) {
                s_epoch.status = Types.EpochStatus.CLAIMABLE;
                emit EpochClaimable(epochNonce);
            } else {
                s_epoch.status = Types.EpochStatus.EXECUTING;
                emit EpochDepositExecuting(epochNonce, uint256(accounting.netFlow));
            }

            if (accounting.netFlow == 0) return externalAction;

            externalAction.amount = uint256(accounting.netFlow);
            if (params.isLocalStrategy) {
                externalAction.action = ExternalAction.DEPOSIT_TO_LOCAL_STRATEGY;
            } else {
                externalAction.action = ExternalAction.SEND_DEPOSIT_TO_REMOTE_STRATEGY;
            }
        } else {
            uint256 netWithdrawAmount = uint256(-accounting.netFlow);
            externalAction.amount = netWithdrawAmount;
            if (params.isLocalStrategy) {
                externalAction.action = ExternalAction.WITHDRAW_FROM_LOCAL_STRATEGY;
            } else {
                externalAction.action = ExternalAction.WAIT_FOR_REMOTE_WITHDRAW;
                s_epoch.status = Types.EpochStatus.EXECUTING;
                emit EpochWithdrawExecuting(epochNonce, netWithdrawAmount);
            }
        }
    }

    /// @notice Completes the most recently closed remote net-deposit epoch
    /// @param $ ParentVault namespaced storage
    /// @param expectedEpochNonce The most recently closed epoch nonce expected by the caller
    /// @dev Reverts if expectedEpochNonce does not match the most recently closed epoch nonce
    /// @dev Reverts if no epoch has completed
    /// @dev Reverts if the preceding epoch is not an executing net-deposit epoch
    function completeEpochDeposit(ParentVaultStore.ParentVaultStorage storage $, uint256 expectedEpochNonce) public {
        _completeEpochDeposit($, expectedEpochNonce);
    }

    /// @notice Completes the most recently closed remote net-deposit epoch
    /// @param $ ParentVault namespaced storage
    /// @param expectedEpochNonce The most recently closed epoch nonce expected by the caller
    /// @dev Reverts if expectedEpochNonce does not match the most recently closed epoch nonce
    /// @dev Reverts if no epoch has completed
    /// @dev Reverts if the preceding epoch is not an executing net-deposit epoch
    function _completeEpochDeposit(ParentVaultStore.ParentVaultStorage storage $, uint256 expectedEpochNonce) internal {
        uint256 currentEpochNonce = $.s_epochNonce;
        uint256 epochNonce = currentEpochNonce - 1;
        if (expectedEpochNonce != epochNonce) {
            revert IParentVault.ParentVault__InvalidEpochNonce(expectedEpochNonce);
        }
        if (currentEpochNonce == 1) revert IParentVault.ParentVault__NoCompletedEpoch();

        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.totalDepositAmount <= s_epoch.totalWithdrawClaimAmount) {
            revert IParentVault.ParentVault__EpochNotNetDeposit(epochNonce);
        }

        _finalizeEpoch(s_epoch, epochNonce);
    }

    /// @notice Finalizes a local net-withdraw epoch after ParentVault receives actual adapter output
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce being finalized
    /// @param totalDepositAmount The epoch's total deposit amount, as already settled by `closeEpoch`
    /// @param amountOut The actual amount withdrawn from the local strategy
    /// @dev Assumes epochNonce identifies the epoch just settled as a local net withdraw; this function does not validate it
    function finalizeLocalNetWithdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 totalDepositAmount,
        uint256 amountOut
    ) public {
        _finalizeLocalNetWithdraw($, epochNonce, totalDepositAmount, amountOut);
    }

    /// @notice Finalizes a local net-withdraw epoch after ParentVault receives actual adapter output
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce being finalized
    /// @param totalDepositAmount The epoch's total deposit amount, as already settled by `closeEpoch`
    /// @param amountOut The actual amount withdrawn from the local strategy
    /// @dev Assumes epochNonce identifies the epoch just settled as a local net withdraw; this function does not validate it
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

    /// @notice Marks an executing epoch as claimable
    /// @param s_epoch The epoch's storage struct
    /// @param epochNonce The nonce of the epoch being finalized
    /// @dev Reverts if the epoch is not executing
    function _finalizeEpoch(Types.Epoch storage s_epoch, uint256 epochNonce) internal {
        if (s_epoch.status != Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochNotExecuting(epochNonce);
        }

        s_epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }

    /// @notice Opens the epoch immediately following epochNonce
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce just closed by `closeEpoch`, as the next nonce is `epochNonce + 1`
    /// @dev Assumes epochNonce identifies the current epoch that was just settled; this function does not validate it
    function openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) public {
        _openNextEpoch($, epochNonce);
    }

    /// @notice Opens the epoch immediately following epochNonce
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce just closed by `closeEpoch`, as the next nonce is `epochNonce + 1`
    /// @dev Assumes epochNonce identifies the current epoch that was just settled; this function does not validate it
    function _openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) internal {
        uint256 nextNonce = epochNonce + 1;
        $.s_epochNonce = nextNonce;
        $.s_epochs[nextNonce].status = Types.EpochStatus.OPEN;
        $.s_epochs[nextNonce].openedAtTimestamp = block.timestamp;
        emit EpochOpen(nextNonce);
    }
}
