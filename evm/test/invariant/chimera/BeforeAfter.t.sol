// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {EpochGhosts} from "./ghosts/EpochGhosts.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BeforeAfter is EpochGhosts {
    struct Vars {
        uint256 epochNonce;
        uint256 rebalanceNonce;
        uint256 childEpochNonce;
        uint256 childRebalanceNonce;
        uint256 remoteChildEpochNonce;
        uint256 remoteChildRebalanceNonce;
        uint256 totalShares;
        uint256 treasuryShareBalance;
        uint256 performanceFeeHighWaterMark;
        uint256 tvl;
        uint256 vaultBalance;
        uint256 currentEpochTotalDepositAmount;
        uint256 actorCurrentEpochDepositAmount;
        uint256 currentEpochTotalShareBurnAmount;
        uint256 actorCurrentEpochWithdrawShareBurnAmount;
        uint256 actorUsdcBalance;
        uint256 actorShareBalance;
        uint256 targetEpochRemainingDepositClaimAmount;
        uint256 targetEpochRemainingShareMintAmount;
        uint256 targetEpochRemainingShareBurnAmount;
        uint256 targetEpochRemainingWithdrawClaimAmount;
        uint256 actorTargetEpochDepositAmount;
        uint256 actorTargetEpochWithdrawShareBurnAmount;
    }

    Vars internal _before;
    Vars internal _after;
    uint256 internal s_targetEpochNonce;

    function __before() internal {
        uint256 epochNonce = parent.vault.getEpochNonce();
        _before.epochNonce = epochNonce;
        _before.rebalanceNonce = parent.vault.getRebalance().nonce;
        _before.childEpochNonce = child.vault.getLastHandledEpochNonce();
        _before.childRebalanceNonce = child.vault.getLastHandledRebalanceNonce();
        _before.remoteChildEpochNonce = remoteChild.vault.getLastHandledEpochNonce();
        _before.remoteChildRebalanceNonce = remoteChild.vault.getLastHandledRebalanceNonce();
        _before.totalShares = parent.vault.getTotalShares();
        _before.treasuryShareBalance = parent.share.balanceOf(parent.vault.getTreasury());
        _before.performanceFeeHighWaterMark = parent.vault.getPerformanceFeeHighWaterMark();
        _before.tvl = _activeStrategyTvl();
        _before.vaultBalance = IERC20(parent.vault.getAsset()).balanceOf(address(_activeVault()));
        _before.currentEpochTotalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        _before.actorCurrentEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, epochNonce);
        _before.currentEpochTotalShareBurnAmount = parent.vault.getEpoch(epochNonce).totalShareBurnAmount;
        _before.actorCurrentEpochWithdrawShareBurnAmount =
            parent.vault.getWithdrawShareBurnAmount(s_currentActor, epochNonce);
        _before.actorUsdcBalance = IERC20(parent.vault.getAsset()).balanceOf(s_currentActor);
        _before.actorShareBalance = parent.share.balanceOf(s_currentActor);
        _before.targetEpochRemainingDepositClaimAmount =
        parent.vault.getEpoch(s_targetEpochNonce).remainingDepositClaimAmount;
        _before.targetEpochRemainingShareMintAmount = parent.vault.getEpoch(s_targetEpochNonce).remainingShareMintAmount;
        _before.targetEpochRemainingShareBurnAmount = parent.vault.getEpoch(s_targetEpochNonce).remainingShareBurnAmount;
        _before.targetEpochRemainingWithdrawClaimAmount =
        parent.vault.getEpoch(s_targetEpochNonce).remainingWithdrawClaimAmount;
        _before.actorTargetEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, s_targetEpochNonce);
        _before.actorTargetEpochWithdrawShareBurnAmount =
            parent.vault.getWithdrawShareBurnAmount(s_currentActor, s_targetEpochNonce);
    }

    function __after() internal {
        uint256 epochNonce = parent.vault.getEpochNonce();
        _after.epochNonce = epochNonce;
        _after.rebalanceNonce = parent.vault.getRebalance().nonce;
        _after.childEpochNonce = child.vault.getLastHandledEpochNonce();
        _after.childRebalanceNonce = child.vault.getLastHandledRebalanceNonce();
        _after.remoteChildEpochNonce = remoteChild.vault.getLastHandledEpochNonce();
        _after.remoteChildRebalanceNonce = remoteChild.vault.getLastHandledRebalanceNonce();
        _after.totalShares = parent.vault.getTotalShares();
        _after.treasuryShareBalance = parent.share.balanceOf(parent.vault.getTreasury());
        _after.performanceFeeHighWaterMark = parent.vault.getPerformanceFeeHighWaterMark();
        if (_after.performanceFeeHighWaterMark > ghost_maxPerformanceFeeHighWaterMark) {
            ghost_maxPerformanceFeeHighWaterMark = _after.performanceFeeHighWaterMark;
        }
        _after.tvl = _activeStrategyTvl();
        _after.vaultBalance = IERC20(parent.vault.getAsset()).balanceOf(address(_activeVault()));
        _after.currentEpochTotalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        _after.actorCurrentEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, epochNonce);
        _after.currentEpochTotalShareBurnAmount = parent.vault.getEpoch(epochNonce).totalShareBurnAmount;
        _after.actorCurrentEpochWithdrawShareBurnAmount =
            parent.vault.getWithdrawShareBurnAmount(s_currentActor, epochNonce);
        _after.actorUsdcBalance = IERC20(parent.vault.getAsset()).balanceOf(s_currentActor);
        _after.actorShareBalance = parent.share.balanceOf(s_currentActor);
        _after.targetEpochRemainingDepositClaimAmount =
        parent.vault.getEpoch(s_targetEpochNonce).remainingDepositClaimAmount;
        _after.targetEpochRemainingShareMintAmount = parent.vault.getEpoch(s_targetEpochNonce).remainingShareMintAmount;
        _after.targetEpochRemainingShareBurnAmount = parent.vault.getEpoch(s_targetEpochNonce).remainingShareBurnAmount;
        _after.targetEpochRemainingWithdrawClaimAmount =
        parent.vault.getEpoch(s_targetEpochNonce).remainingWithdrawClaimAmount;
        _after.actorTargetEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, s_targetEpochNonce);
        _after.actorTargetEpochWithdrawShareBurnAmount =
            parent.vault.getWithdrawShareBurnAmount(s_currentActor, s_targetEpochNonce);

        ghost_maxParentEpochNonce = _max(ghost_maxParentEpochNonce, _after.epochNonce);
        ghost_maxParentRebalanceNonce = _max(ghost_maxParentRebalanceNonce, _after.rebalanceNonce);
        ghost_maxChildEpochNonce = _max(ghost_maxChildEpochNonce, _after.childEpochNonce);
        ghost_maxChildRebalanceNonce = _max(ghost_maxChildRebalanceNonce, _after.childRebalanceNonce);
        ghost_maxRemoteChildEpochNonce = _max(ghost_maxRemoteChildEpochNonce, _after.remoteChildEpochNonce);
        ghost_maxRemoteChildRebalanceNonce = _max(ghost_maxRemoteChildRebalanceNonce, _after.remoteChildRebalanceNonce);
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
