// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultUserEpochLib} from "../../../src/libraries/ParentVaultUserEpochLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ParentVaultUserEpochLibHarness is ParentVaultStore, HelperHarness {
    address internal immutable i_asset;
    address internal immutable i_share;

    constructor(address asset, address share) {
        i_asset = asset;
        i_share = share;
    }

    function deposit(address user, uint256 amount, uint256 minDepositAmount) external returns (uint256 epochNonce) {
        epochNonce = ParentVaultUserEpochLib._deposit(_parentVaultStorage(), i_asset, user, amount, minDepositAmount);
    }

    function withdraw(address user, uint256 shareBurnAmount) external returns (uint256 epochNonce) {
        epochNonce = ParentVaultUserEpochLib._withdraw(_parentVaultStorage(), i_share, user, shareBurnAmount);
    }

    function claimShares(address user, uint256 epochNonce) external returns (uint256 shareMintAmount) {
        shareMintAmount = ParentVaultUserEpochLib._claimShares(_parentVaultStorage(), i_share, user, epochNonce);
    }

    function claimAsset(address user, uint256 epochNonce) external returns (uint256 withdrawAmount) {
        withdrawAmount = ParentVaultUserEpochLib._claimAsset(_parentVaultStorage(), i_share, i_asset, user, epochNonce);
    }

    function cancelDeposit(address user) external {
        ParentVaultUserEpochLib._cancelDeposit(_parentVaultStorage(), i_asset, user);
    }

    function cancelWithdraw(address user) external {
        ParentVaultUserEpochLib._cancelWithdraw(_parentVaultStorage(), i_share, user);
    }

    function proportionalAmount(uint256 userAmount, uint256 remainingNumerator, uint256 remainingDenominator)
        external
        pure
        returns (uint256 amount)
    {
        amount = ParentVaultUserEpochLib._proportionalAmount(userAmount, remainingNumerator, remainingDenominator);
    }

    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    function getShare() external view returns (address share) {
        share = i_share;
    }

    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    function getDeposit(address user, uint256 epochNonce) external view returns (uint256 amount) {
        amount = _parentVaultStorage().s_deposits[user][epochNonce];
    }

    function getWithdraw(address user, uint256 epochNonce) external view returns (uint256 shareBurnAmount) {
        shareBurnAmount = _parentVaultStorage().s_withdraws[user][epochNonce];
    }

    function getEpochTotalDepositAmount(uint256 epochNonce) external view returns (uint256 totalDepositAmount) {
        totalDepositAmount = _parentVaultStorage().s_epochs[epochNonce].totalDepositAmount;
    }

    function getEpochTotalShareBurnAmount(uint256 epochNonce) external view returns (uint256 totalShareBurnAmount) {
        totalShareBurnAmount = _parentVaultStorage().s_epochs[epochNonce].totalShareBurnAmount;
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

    function getEpochStatus(uint256 epochNonce) external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[epochNonce].status;
    }
}
