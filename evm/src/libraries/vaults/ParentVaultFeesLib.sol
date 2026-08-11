// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {IShare} from "../../interfaces/token/IShare.sol";
import {ParentVaultMathLib} from "./ParentVaultMathLib.sol";

/// @title Yieldcoin v2 ParentVault fee logic library
/// @author @contractlevel
/// @notice Handles ParentVault fee accounting while ParentVault keeps lifecycle orchestration
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context
library ParentVaultFeesLib {
    struct PerformanceFeeParams {
        uint256 epochNonce;
        uint256 tvl;
        uint256 grossPricePerShare;
        uint256 totalShares;
        address share;
        uint256 sharePrecision;
        uint256 assetPrecision;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Basis points denominator (100% = 10_000 bps)
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    /// @dev Performance fee rate (7.77%)
    uint256 internal constant PERFORMANCE_FEE_BPS = 777;
    /// @dev Annual management fee rate (1%)
    uint256 internal constant MANAGEMENT_FEE_BPS = 100;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL
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

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates the underlying-asset value of one Yieldcoin share
    /// @param $ ParentVault namespaced storage
    /// @param tvl The Total Value Locked in the active strategy, denominated in the underlying asset
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @return pricePerShare The underlying-asset value of one share
    /// @dev Bootstrap pricing: when totalShares == 0, pricePerShare is always assetPrecision (par),
    ///      regardless of tvl. Any residual tvl at that point (e.g. dust left behind after a full
    ///      exit) is captured by the next depositor's shares rather than the prior shareholders.
    ///      See KI-010 in docs/KNOWN_ISSUES.md.
    /// @dev Reverts if TVL is zero while shares are outstanding or the calculated price rounds down to zero
    function calculatePricePerShare(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 tvl,
        uint256 sharePrecision,
        uint256 assetPrecision
    ) public view returns (uint256 pricePerShare) {
        pricePerShare = _calculatePricePerShare(tvl, $.s_totalShares, sharePrecision, assetPrecision);
    }

    /// @notice Calculates the underlying-asset value of one Yieldcoin share
    /// @param tvl The Total Value Locked in the active strategy, denominated in the underlying asset
    /// @param totalShares The total outstanding Yieldcoin shares (caller-supplied to avoid a redundant SLOAD)
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @return pricePerShare The underlying-asset value of one share
    /// @dev Bootstrap pricing: when totalShares == 0, pricePerShare is always assetPrecision (par), regardless
    ///      of tvl. Any residual tvl at that point (e.g. dust left behind after a full exit) is captured by the
    ///      next depositor's shares rather than the prior shareholders. See KI-010 in docs/KNOWN_ISSUES.md.
    /// @dev Reverts if TVL is zero while shares are outstanding or the calculated price rounds down to zero
    function _calculatePricePerShare(uint256 tvl, uint256 totalShares, uint256 sharePrecision, uint256 assetPrecision)
        internal
        pure
        returns (uint256 pricePerShare)
    {
        if (totalShares != 0 && tvl != 0) {
            pricePerShare = ParentVaultMathLib._mulDivDown(tvl, sharePrecision, totalShares);
            if (pricePerShare == 0) revert IParentVault.ParentVault__ZeroPricePerShare();
        } else if (totalShares == 0) {
            pricePerShare = assetPrecision;
        } else {
            revert IParentVault.ParentVault__ZeroTvlWithOutstandingShares();
        }
    }

    /// @notice Calculates deposit shares directly from TVL and the post-fee share supply
    /// @param tvl The Total Value Locked in the active strategy, denominated in the underlying asset
    /// @param depositAmount The deposit amount being converted to shares
    /// @param totalShares The total shares after performance-fee dilution
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor used for bootstrap pricing
    /// @return newShares The number of shares to mint
    /// @dev Avoids using a floored price-per-share as a divisor, which can compound rounding
    ///      error and over-mint shares when the share price is small.
    /// @dev Reverts if TVL is zero while shares are outstanding
    function _calculateNewShares(
        uint256 tvl,
        uint256 depositAmount,
        uint256 totalShares,
        uint256 sharePrecision,
        uint256 assetPrecision
    ) internal pure returns (uint256 newShares) {
        if (totalShares != 0 && tvl != 0) {
            newShares = ParentVaultMathLib._mulDivDown(depositAmount, totalShares, tvl);
        } else if (totalShares == 0) {
            newShares = ParentVaultMathLib._mulDivDown(depositAmount, sharePrecision, assetPrecision);
        } else {
            revert IParentVault.ParentVault__ZeroTvlWithOutstandingShares();
        }
    }

    /// @notice Calculates and collects management fees for time elapsed since the preceding rebalance completed
    /// @param $ ParentVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance collecting the fee
    /// @param lastRebalanceCompletedTimestamp The timestamp when the rebalance last completed
    /// @param share The Yieldcoin share token
    /// @dev Caps elapsed time at 365 days
    /// @dev Reverts if lastRebalanceCompletedTimestamp is in the future
    function collectManagementFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 rebalanceNonce,
        uint256 lastRebalanceCompletedTimestamp,
        address share
    ) public {
        _collectManagementFee($, rebalanceNonce, lastRebalanceCompletedTimestamp, share);
    }

    /// @notice Calculates and collects management fees for time elapsed since the preceding rebalance completed
    /// @param $ ParentVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance collecting the fee
    /// @param lastRebalanceCompletedTimestamp The timestamp when the rebalance last completed
    /// @param share The Yieldcoin share token
    /// @dev Caps elapsed time at 365 days
    /// @dev Reverts if lastRebalanceCompletedTimestamp is in the future
    function _collectManagementFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 rebalanceNonce,
        uint256 lastRebalanceCompletedTimestamp,
        address share
    ) internal {
        uint256 elapsed = block.timestamp - lastRebalanceCompletedTimestamp;
        if (elapsed > 365 days) elapsed = 365 days;

        uint256 totalShares = $.s_totalShares;
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        uint256 feeShares = ParentVaultMathLib._mulDivUp(totalShares, MANAGEMENT_FEE_BPS * elapsed, denominator);
        if (feeShares != 0) {
            $.s_totalShares = totalShares + feeShares;
            IShare(share).mint($.s_treasury, feeShares);
            emit ManagementFeeCollected(rebalanceNonce, feeShares);
        }
    }

    /// @notice Collects performance fees when the gross price exceeds the high water mark
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce collecting the fee
    /// @param tvl The strategy TVL before current epoch deposits and withdrawals settle, denominated in the underlying asset
    /// @param grossPricePerShare The epoch price per share before performance fee dilution
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @return settlementPricePerShare The epoch price per share after performance fee dilution
    /// @dev Returns grossPricePerShare without minting when it does not exceed the high water mark or the fee is not collectible
    /// @dev Mints fee shares but does not update s_totalShares; the epoch-settlement caller performs the ledger update
    function collectPerformanceFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 tvl,
        uint256 grossPricePerShare,
        address share,
        uint256 sharePrecision,
        uint256 assetPrecision
    ) public returns (uint256 settlementPricePerShare) {
        (settlementPricePerShare,) = _collectPerformanceFee(
            $, epochNonce, tvl, grossPricePerShare, $.s_totalShares, share, sharePrecision, assetPrecision
        );
    }

    /// @notice Collects performance fees when the gross price exceeds the high water mark
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce collecting the fee
    /// @param tvl The strategy TVL before current epoch deposits and withdrawals settle, denominated in the underlying asset
    /// @param grossPricePerShare The epoch price per share before performance fee dilution
    /// @param totalShares The total outstanding Yieldcoin shares (caller-supplied to avoid a redundant SLOAD)
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @param assetPrecision The underlying asset precision factor, used as the bootstrap price per share
    /// @return settlementPricePerShare The epoch price per share after performance fee dilution
    /// @return feeShares The number of shares minted as a performance fee, or zero if none were minted
    /// @dev Returns grossPricePerShare without minting when it does not exceed the high water mark or the fee is not collectible
    /// @dev This function mints feeShares but deliberately does NOT write `s_totalShares` - the caller
    ///      is the sole writer of that ledger, computing `totalShares + feeShares` (plus its own epoch
    ///      deposit/withdraw deltas) in a single write, instead of this function writing an intermediate
    ///      value that the caller would immediately overwrite.
    function _collectPerformanceFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 tvl,
        uint256 grossPricePerShare,
        uint256 totalShares,
        address share,
        uint256 sharePrecision,
        uint256 assetPrecision
    ) internal returns (uint256 settlementPricePerShare, uint256 feeShares) {
        PerformanceFeeParams memory params = PerformanceFeeParams({
            epochNonce: epochNonce,
            tvl: tvl,
            grossPricePerShare: grossPricePerShare,
            totalShares: totalShares,
            share: share,
            sharePrecision: sharePrecision,
            assetPrecision: assetPrecision
        });
        return _collectPerformanceFee($, params);
    }

    function _collectPerformanceFee(ParentVaultStore.ParentVaultStorage storage $, PerformanceFeeParams memory params)
        internal
        returns (uint256 settlementPricePerShare, uint256 feeShares)
    {
        uint256 highWaterMark = $.s_performanceFeeHighWaterMark;
        if (params.grossPricePerShare <= highWaterMark) return (params.grossPricePerShare, 0);

        uint256 yieldPerShare = params.grossPricePerShare - highWaterMark;
        uint256 totalYield = ParentVaultMathLib._mulDivUp(yieldPerShare, params.totalShares, params.sharePrecision);
        uint256 fee = ParentVaultMathLib._mulDivUp(totalYield, PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);

        if (fee >= params.tvl) {
            return (params.grossPricePerShare, 0);
        }

        feeShares = ParentVaultMathLib._mulDivUp(fee, params.totalShares, params.tvl - fee);

        uint256 newTotalShares = params.totalShares + feeShares;

        settlementPricePerShare =
            _calculatePricePerShare(params.tvl, newTotalShares, params.sharePrecision, params.assetPrecision);
        // feeShares rounds up and the settlement price rounds down, so dilution can land the
        // settlement price a dust amount below the high water mark; only ever raise it (FEE-003)
        if (settlementPricePerShare > highWaterMark) {
            $.s_performanceFeeHighWaterMark = settlementPricePerShare;
        }

        if (feeShares != 0) {
            emit PerformanceFeeCollected(params.epochNonce, feeShares, settlementPricePerShare);
            IShare(params.share).mint($.s_treasury, feeShares);
        }
    }
}
