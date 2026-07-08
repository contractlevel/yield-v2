// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../vaults/ParentVaultStore.sol";
import {IParentVault} from "../interfaces/IParentVault.sol";
import {IShare} from "../interfaces/IShare.sol";

/// @title Yieldcoin v2 ParentVault fee logic library
/// @author @contractlevel
/// @notice Handles ParentVault fee accounting while ParentVault keeps lifecycle orchestration.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultFeesLib {
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
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    event ManagementFeeCollected(uint256 indexed rebalanceNonce, uint256 indexed feeShares);
    event PerformanceFeeCollected(uint256 indexed epochNonce, uint256 indexed feeShares, uint256 indexed highWaterMark);

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates the asset value of a Yieldcoin share token.
    /// @param $ ParentVault namespaced storage
    /// @param tvl The Total Value Locked in the active strategy of the Yieldcoin v2 system
    /// @param sharePrecision The share precision factor
    /// @return pricePerShare Asset value of a Yieldcoin share token
    function calculatePricePerShare(ParentVaultStore.ParentVaultStorage storage $, uint256 tvl, uint256 sharePrecision)
        public
        view
        returns (uint256 pricePerShare)
    {
        pricePerShare = _calculatePricePerShare($, tvl, sharePrecision);
    }

    /// @notice Calculates and collects the management fee based on time elapsed since the last rebalance completed.
    /// @param $ ParentVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance collecting the fee
    /// @param lastRebalanceCompletedTimestamp The timestamp when the rebalance last completed
    /// @param share The Yieldcoin share token
    function collectManagementFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 rebalanceNonce,
        uint256 lastRebalanceCompletedTimestamp,
        address share
    ) public {
        _collectManagementFee($, rebalanceNonce, lastRebalanceCompletedTimestamp, share);
    }

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
        uint256 feeShares = (totalShares * MANAGEMENT_FEE_BPS * elapsed + denominator - 1) / denominator;
        if (feeShares != 0) {
            $.s_totalShares = totalShares + feeShares;
            IShare(share).mint($.s_treasury, feeShares);
            emit ManagementFeeCollected(rebalanceNonce, feeShares);
        }
    }

    /// @notice Collects performance fee when the gross price exceeds the high water mark.
    /// @param $ ParentVault namespaced storage
    /// @param epochNonce The epoch nonce collecting the fee
    /// @param tvl The strategy TVL before current epoch deposits and withdrawals settle
    /// @param grossPricePerShare The epoch price per share before performance fee dilution
    /// @param share The Yieldcoin share token
    /// @param sharePrecision The share precision factor
    /// @return settlementPricePerShare The epoch price per share after performance fee dilution
    function collectPerformanceFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 tvl,
        uint256 grossPricePerShare,
        address share,
        uint256 sharePrecision
    ) public returns (uint256 settlementPricePerShare) {
        settlementPricePerShare = _collectPerformanceFee($, epochNonce, tvl, grossPricePerShare, share, sharePrecision);
    }

    function _collectPerformanceFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 epochNonce,
        uint256 tvl,
        uint256 grossPricePerShare,
        address share,
        uint256 sharePrecision
    ) internal returns (uint256 settlementPricePerShare) {
        uint256 highWaterMark = $.s_performanceFeeHighWaterMark;
        if (grossPricePerShare <= highWaterMark) return grossPricePerShare;

        uint256 totalShares = $.s_totalShares;
        uint256 yieldPerShare = grossPricePerShare - highWaterMark;
        uint256 totalYield = _ceilDiv(yieldPerShare * totalShares, sharePrecision);
        uint256 fee = _ceilDiv(totalYield * PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);

        if (fee >= tvl) {
            return grossPricePerShare;
        }

        uint256 feeShares = _ceilDiv(fee * totalShares, tvl - fee);

        if (feeShares != 0) {
            $.s_totalShares = totalShares + feeShares;
            IShare(share).mint($.s_treasury, feeShares);
        }

        settlementPricePerShare = _calculatePricePerShare($, tvl, sharePrecision);
        /// @dev feeShares rounds up and the settlement price rounds down, so dilution can land the
        ///      settlement price a dust amount below the high water mark; only ever raise it (FEE-003)
        if (settlementPricePerShare > highWaterMark) {
            $.s_performanceFeeHighWaterMark = settlementPricePerShare;
        }

        if (feeShares != 0) emit PerformanceFeeCollected(epochNonce, feeShares, settlementPricePerShare);
    }

    function _calculatePricePerShare(ParentVaultStore.ParentVaultStorage storage $, uint256 tvl, uint256 sharePrecision)
        internal
        view
        returns (uint256 pricePerShare)
    {
        uint256 totalShares = $.s_totalShares;
        if (totalShares != 0 && tvl != 0) {
            pricePerShare = tvl * sharePrecision / totalShares;
            if (pricePerShare == 0) revert IParentVault.ParentVault__ZeroPricePerShare();
        } else if (totalShares == 0) {
            pricePerShare = sharePrecision;
        } else {
            revert IParentVault.ParentVault__ZeroTvlWithOutstandingShares();
        }
    }

    // @review replace with OZ or solady
    function _ceilDiv(uint256 numerator, uint256 denominator) private pure returns (uint256 result) {
        result = numerator == 0 ? 0 : (numerator - 1) / denominator + 1;
    }
}
