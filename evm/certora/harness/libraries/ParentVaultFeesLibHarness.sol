// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultFeesLib} from "../../../src/libraries/vaults/ParentVaultFeesLib.sol";

contract ParentVaultFeesLibHarness is ParentVaultStore, HelperHarness {
    address internal immutable i_share;

    constructor(address share) {
        i_share = share;
    }

    function calculatePricePerShare(uint256 tvl, uint256 sharePrecision)
        external
        view
        returns (uint256 pricePerShare)
    {
        pricePerShare = ParentVaultFeesLib._calculatePricePerShare(_parentVaultStorage(), tvl, sharePrecision);
    }

    function collectManagementFee(uint256 rebalanceNonce, uint256 lastRebalanceCompletedTimestamp) external {
        ParentVaultFeesLib._collectManagementFee(
            _parentVaultStorage(), rebalanceNonce, lastRebalanceCompletedTimestamp, i_share
        );
    }

    function collectPerformanceFee(
        uint256 epochNonce,
        uint256 tvl,
        uint256 grossPricePerShare,
        uint256 sharePrecision
    ) external returns (uint256 settlementPricePerShare) {
        settlementPricePerShare = ParentVaultFeesLib._collectPerformanceFee(
            _parentVaultStorage(), epochNonce, tvl, grossPricePerShare, i_share, sharePrecision
        );
    }

    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = _parentVaultStorage().s_totalShares;
    }

    function getPerformanceFeeHighWaterMark() external view returns (uint256 highWaterMark) {
        highWaterMark = _parentVaultStorage().s_performanceFeeHighWaterMark;
    }

    function getTreasury() external view returns (address treasury) {
        treasury = _parentVaultStorage().s_treasury;
    }
}
