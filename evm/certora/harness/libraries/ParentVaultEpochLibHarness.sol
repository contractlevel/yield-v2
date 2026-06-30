// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultEpochLib} from "../../../src/libraries/ParentVaultEpochLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ParentVaultEpochLibHarness is ParentVaultStore, HelperHarness {
    address internal immutable i_share;

    constructor(address share) {
        i_share = share;
    }

    function closeEpoch(uint256 tvl, uint256 sharePrecision, uint256 minDepositAmount, bool isLocalStrategy)
        external
        returns (uint256 epochNonce, uint8 action, uint256 amount)
    {
        ParentVaultEpochLib.CloseEpochExternalAction memory externalAction = ParentVaultEpochLib._closeEpoch(
            _parentVaultStorage(), tvl, i_share, sharePrecision, minDepositAmount, isLocalStrategy
        );
        epochNonce = externalAction.epochNonce;
        action = uint8(externalAction.action);
        amount = externalAction.amount;
    }

    function finalizeLocalNetWithdraw(uint256 epochNonce, uint256 amountOut) external {
        ParentVaultEpochLib._finalizeLocalNetWithdraw(_parentVaultStorage(), epochNonce, amountOut);
    }

    function openNextEpoch() external {
        ParentVaultEpochLib._openNextEpoch(_parentVaultStorage());
    }

    function getMinEpochPeriod() external pure returns (uint256 minEpochPeriod) {
        minEpochPeriod = 1 hours;
    }

    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    function getPreviousEpochNonce() external view returns (uint256 previousEpochNonce) {
        previousEpochNonce = _parentVaultStorage().s_epochNonce - 1;
    }

    function getPreviousEpochStatus() external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[_parentVaultStorage().s_epochNonce - 1].status;
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

    function getRebalanceState() external view returns (Types.RebalanceState state) {
        state = _parentVaultStorage().s_rebalance.state;
    }

    function getEpochTotalDepositAmount(uint256 epochNonce) external view returns (uint256 totalDepositAmount) {
        totalDepositAmount = _parentVaultStorage().s_epochs[epochNonce].totalDepositAmount;
    }

    function getEpochTotalShareBurnAmount(uint256 epochNonce) external view returns (uint256 totalShareBurnAmount) {
        totalShareBurnAmount = _parentVaultStorage().s_epochs[epochNonce].totalShareBurnAmount;
    }

    function getEpochTotalWithdrawClaimAmount(uint256 epochNonce)
        external
        view
        returns (uint256 totalWithdrawClaimAmount)
    {
        totalWithdrawClaimAmount = _parentVaultStorage().s_epochs[epochNonce].totalWithdrawClaimAmount;
    }

    function getEpochPricePerShare(uint256 epochNonce) external view returns (uint256 pricePerShare) {
        pricePerShare = _parentVaultStorage().s_epochs[epochNonce].pricePerShare;
    }

    function getEpochRemainingDepositClaimAmount(uint256 epochNonce)
        external
        view
        returns (uint256 remainingDepositClaimAmount)
    {
        remainingDepositClaimAmount = _parentVaultStorage().s_epochs[epochNonce].remainingDepositClaimAmount;
    }

    function getEpochRemainingShareMintAmount(uint256 epochNonce)
        external
        view
        returns (uint256 remainingShareMintAmount)
    {
        remainingShareMintAmount = _parentVaultStorage().s_epochs[epochNonce].remainingShareMintAmount;
    }

    function getEpochRemainingShareBurnAmount(uint256 epochNonce)
        external
        view
        returns (uint256 remainingShareBurnAmount)
    {
        remainingShareBurnAmount = _parentVaultStorage().s_epochs[epochNonce].remainingShareBurnAmount;
    }

    function getEpochRemainingWithdrawClaimAmount(uint256 epochNonce)
        external
        view
        returns (uint256 remainingWithdrawClaimAmount)
    {
        remainingWithdrawClaimAmount = _parentVaultStorage().s_epochs[epochNonce].remainingWithdrawClaimAmount;
    }

    function getEpochOpenedAtTimestamp(uint256 epochNonce) external view returns (uint256 openedAtTimestamp) {
        openedAtTimestamp = _parentVaultStorage().s_epochs[epochNonce].openedAtTimestamp;
    }

    function getEpochClosedAtTimestamp(uint256 epochNonce) external view returns (uint256 closedAtTimestamp) {
        closedAtTimestamp = _parentVaultStorage().s_epochs[epochNonce].closedAtTimestamp;
    }

    function getEpochStatus(uint256 epochNonce) external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[epochNonce].status;
    }
}
