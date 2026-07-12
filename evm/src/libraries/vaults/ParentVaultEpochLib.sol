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
    enum ExternalAction {
        NONE,
        DEPOSIT_TO_LOCAL_STRATEGY,
        SEND_DEPOSIT_TO_REMOTE_STRATEGY,
        WITHDRAW_FROM_LOCAL_STRATEGY,
        WAIT_FOR_REMOTE_WITHDRAW
    }

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
    event EpochOpen(uint256 indexed epochNonce);
    event EpochExecuting(uint256 indexed epochNonce, uint256 indexed amount);
    event EpochClaimable(uint256 indexed epochNonce);

    /*//////////////////////////////////////////////////////////////
                                EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Settles the current epoch and returns the external action ParentVault must execute.
    /// @param $ ParentVault namespaced storage
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @param minDepositAmount The minimum deposit amount
    /// @param isLocalStrategy Whether this chain currently has the active strategy adapter
    /// @return externalAction The external action ParentVault should execute after settlement
    function closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 tvl,
        address share,
        uint256 sharePrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    ) public returns (CloseEpochExternalAction memory externalAction) {
        externalAction = _closeEpoch($, tvl, share, sharePrecision, minDepositAmount, isLocalStrategy);
    }

    function _closeEpoch(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 tvl,
        address share,
        uint256 sharePrecision,
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
        uint256 grossPricePerShare = ParentVaultFeesLib._calculatePricePerShare(tvl, totalShares, sharePrecision);
        (uint256 settlementPricePerShare, uint256 feeShares) = ParentVaultFeesLib._collectPerformanceFee(
            $, epochNonce, tvl, grossPricePerShare, totalShares, share, sharePrecision
        );

        uint256 totalWithdraw =
            ParentVaultMathLib._mulDivDown(totalShareBurnAmount, settlementPricePerShare, sharePrecision);
        int256 netFlow = int256(totalDepositAmount) - int256(totalWithdraw);

        uint256 newShares = ParentVaultMathLib._mulDivDown(totalDepositAmount, sharePrecision, settlementPricePerShare);
        if (totalDepositAmount != 0 && newShares * minDepositAmount < totalDepositAmount) {
            revert IParentVault.ParentVault__DepositWouldMintZeroShares();
        }
        /// @dev This is the sole write to s_totalShares for the epoch: totalShares is the pre-fee value
        ///      read above, feeShares folds in any performance-fee dilution _collectPerformanceFee minted
        ///      (without itself writing storage - see its NatSpec), and newShares/totalShareBurnAmount
        ///      fold in this epoch's deposits/withdraws.
        $.s_totalShares = totalShares + feeShares + newShares - totalShareBurnAmount;

        s_epoch.totalWithdrawClaimAmount = totalWithdraw;
        s_epoch.pricePerShare = settlementPricePerShare;
        s_epoch.remainingDepositClaimAmount = totalDepositAmount;
        s_epoch.remainingShareMintAmount = newShares;
        s_epoch.remainingShareBurnAmount = totalShareBurnAmount;
        s_epoch.remainingWithdrawClaimAmount = totalWithdraw;
        s_epoch.closedAtTimestamp = block.timestamp;

        externalAction.epochNonce = epochNonce;
        externalAction.totalDepositAmount = totalDepositAmount;
        if (netFlow >= 0) {
            s_epoch.status = Types.EpochStatus.CLAIMABLE;
            emit EpochClaimable(epochNonce);

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
                emit EpochExecuting(epochNonce, netWithdrawAmount);
            }
        }
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

    /// @notice Opens the next epoch.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce just closed by `closeEpoch`, as the next nonce is `epochNonce + 1`
    function openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) public {
        _openNextEpoch($, epochNonce);
    }

    function _openNextEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) internal {
        uint256 nextNonce = epochNonce + 1;
        $.s_epochNonce = nextNonce;
        $.s_epochs[nextNonce].status = Types.EpochStatus.OPEN;
        $.s_epochs[nextNonce].openedAtTimestamp = block.timestamp;
        emit EpochOpen(nextNonce);
    }
}
