// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultEpochLib} from "../../../src/libraries/vaults/ParentVaultEpochLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ParentVaultEpochLibHarness is ParentVaultStore, HelperHarness {

    function closeEpoch(
        uint256 expectedEpochNonce,
        uint256 tvl,
        uint256 sharePrecision,
        uint256 assetPrecision,
        uint256 minDepositAmount,
        bool isLocalStrategy
    )
        external
        returns (uint256 epochNonce, uint8 action, uint256 amount, uint256 totalDepositAmount)
    {
        ParentVaultEpochLib.CloseEpochExternalAction memory externalAction = ParentVaultEpochLib.closeEpoch(
            _parentVaultStorage(),
            expectedEpochNonce,
            tvl,
            sharePrecision,
            assetPrecision,
            minDepositAmount,
            isLocalStrategy
        );
        epochNonce = externalAction.epochNonce;
        action = uint8(externalAction.action);
        amount = externalAction.amount;
        totalDepositAmount = externalAction.totalDepositAmount;
    }

    function completeEpochDeposit(uint256 expectedEpochNonce) external {
        ParentVaultEpochLib.completeEpochDeposit(_parentVaultStorage(), expectedEpochNonce);
    }

    function finalizeLocalNetWithdraw(uint256 epochNonce, uint256 totalDepositAmount, uint256 amountOut) external {
        ParentVaultEpochLib.finalizeLocalNetWithdraw(
            _parentVaultStorage(), epochNonce, totalDepositAmount, amountOut
        );
    }

    function openNextEpoch(uint256 epochNonce) external {
        ParentVaultEpochLib.openNextEpoch(_parentVaultStorage(), epochNonce);
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

    function getEpochStatus(uint256 epochNonce) external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[epochNonce].status;
    }
}
