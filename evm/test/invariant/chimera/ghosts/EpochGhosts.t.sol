// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ActorGhosts} from "./ActorGhosts.t.sol";
import {Types} from "../../../../src/libraries/Types.sol";

abstract contract EpochGhosts is ActorGhosts {
    enum ClaimKind {
        DEPOSIT,
        WITHDRAW
    }

    uint256 internal ghost_totalDeposited;
    mapping(address actor => uint256 amount) internal ghost_totalDepositedByActor;
    mapping(uint256 epochNonce => uint256 amount) internal ghost_totalDepositedByEpoch;
    mapping(address actor => mapping(uint256 epochNonce => uint256 amount)) internal ghost_depositedByActorByEpoch;
    mapping(address actor => uint256 shares) internal ghost_shareBalanceByActor;
    mapping(uint256 epochNonce => uint256 shares) internal ghost_totalShareBurnedByEpoch;
    mapping(address actor => mapping(uint256 epochNonce => uint256 shares)) internal ghost_shareBurnedByActorByEpoch;
    mapping(uint256 epochNonce => uint256 shares) internal ghost_totalShareMintedByEpoch;
    mapping(uint256 epochNonce => uint256 amount) internal ghost_maxRemainingDepositClaimAmountByEpoch;
    mapping(uint256 epochNonce => uint256 shares) internal ghost_maxRemainingShareMintAmountByEpoch;
    mapping(uint256 epochNonce => uint256 shares) internal ghost_maxRemainingShareBurnAmountByEpoch;
    mapping(uint256 epochNonce => uint256 amount) internal ghost_maxRemainingWithdrawClaimAmountByEpoch;
    uint256 internal ghost_maxPerformanceFeeHighWaterMark;
    mapping(uint256 epochNonce => bool isClaimable) internal ghost_epochIsClaimable;
    uint256[] internal ghost_claimableEpochs;
    mapping(uint256 epochNonce => bool isTracked) internal ghost_epochShareAccountingTracked;
    uint256[] internal ghost_shareAccountingEpochs;
    uint256 internal ghost_claimableWithdrawObligation;
    mapping(address actor => uint256 amount) internal ghost_totalUsdcClaimedByActor;
    mapping(address actor => uint256 amount) internal ghost_feeBurdenByActor;

    function _clampDepositAmount(uint256 amountSeed) internal pure returns (uint256) {
        return _boundToRange(amountSeed, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
    }

    function _clampWithdrawShareBurnAmount(uint256 shareSeed, uint256 maxShareBurnAmount)
        internal
        pure
        returns (uint256)
    {
        return _boundToRange(shareSeed, 1, maxShareBurnAmount);
    }

    function _recordDeposit(address actor, uint256 amount) internal {
        uint256 epochNonce = parent.vault.getEpochNonce();

        ghost_totalDeposited += amount;
        ghost_totalDepositedByActor[actor] += amount;
        ghost_totalDepositedByEpoch[epochNonce] += amount;
        ghost_depositedByActorByEpoch[actor][epochNonce] += amount;
    }

    function _recordDepositCancelled(address actor, uint256 amount) internal {
        uint256 epochNonce = parent.vault.getEpochNonce();

        ghost_totalDeposited -= amount;
        ghost_totalDepositedByActor[actor] -= amount;
        ghost_totalDepositedByEpoch[epochNonce] -= amount;
        ghost_depositedByActorByEpoch[actor][epochNonce] -= amount;
    }

    function _recordEpochClosed(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

        _recordEpochShareAccounting(epochNonce);
        ghost_epochIsClaimable[epochNonce] = true;
        ghost_totalShareMintedByEpoch[epochNonce] = epoch.remainingShareMintAmount;
        ghost_maxRemainingDepositClaimAmountByEpoch[epochNonce] = epoch.remainingDepositClaimAmount;
        ghost_maxRemainingShareMintAmountByEpoch[epochNonce] = epoch.remainingShareMintAmount;
        ghost_maxRemainingShareBurnAmountByEpoch[epochNonce] = epoch.remainingShareBurnAmount;
        ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce] = epoch.remainingWithdrawClaimAmount;
        ghost_claimableWithdrawObligation += epoch.remainingWithdrawClaimAmount;
        ghost_claimableEpochs.push(epochNonce);
    }

    function _recordEpochShareAccounting(uint256 epochNonce) internal {
        if (ghost_epochShareAccountingTracked[epochNonce]) return;

        ghost_epochShareAccountingTracked[epochNonce] = true;
        ghost_shareAccountingEpochs.push(epochNonce);
    }

    function _recordSharesClaimed(address actor, uint256 epochNonce, uint256 shareMintAmount) internal {
        ghost_depositedByActorByEpoch[actor][epochNonce] = 0;
        ghost_shareBalanceByActor[actor] += shareMintAmount;
    }

    function _updateDepositRemainingCounterMax(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
        ghost_maxRemainingDepositClaimAmountByEpoch[epochNonce] = epoch.remainingDepositClaimAmount;
        ghost_maxRemainingShareMintAmountByEpoch[epochNonce] = epoch.remainingShareMintAmount;
    }

    function _recordWithdraw(address actor, uint256 amount) internal {
        uint256 epochNonce = parent.vault.getEpochNonce();

        ghost_shareBalanceByActor[actor] -= amount;
        ghost_totalShareBurnedByEpoch[epochNonce] += amount;
        ghost_shareBurnedByActorByEpoch[actor][epochNonce] += amount;
    }

    function _recordWithdrawCancelled(address actor, uint256 amount) internal {
        uint256 epochNonce = parent.vault.getEpochNonce();

        ghost_shareBalanceByActor[actor] += amount;
        ghost_totalShareBurnedByEpoch[epochNonce] -= amount;
        ghost_shareBurnedByActorByEpoch[actor][epochNonce] -= amount;
    }

    function _recordUsdcClaimed(address actor, uint256 epochNonce, uint256 usdcWithdrawAmount) internal {
        ghost_shareBurnedByActorByEpoch[actor][epochNonce] = 0;
        ghost_claimableWithdrawObligation -= usdcWithdrawAmount;
        ghost_totalUsdcClaimedByActor[actor] += usdcWithdrawAmount;
    }

    function _updateWithdrawRemainingCounterMax(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
        ghost_maxRemainingShareBurnAmountByEpoch[epochNonce] = epoch.remainingShareBurnAmount;
        ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce] = epoch.remainingWithdrawClaimAmount;
    }

    function _claimableDepositEpoch(address actor, uint256 epochSeed) internal view returns (uint256 epochNonce) {
        return _claimableEpoch(actor, epochSeed, ClaimKind.DEPOSIT);
    }

    function _claimableWithdrawEpoch(address actor, uint256 epochSeed) internal view returns (uint256 epochNonce) {
        return _claimableEpoch(actor, epochSeed, ClaimKind.WITHDRAW);
    }

    function _claimableEpoch(address actor, uint256 epochSeed, ClaimKind claimKind)
        internal
        view
        returns (uint256 epochNonce)
    {
        uint256 claimableEpochCount = ghost_claimableEpochs.length;
        if (claimableEpochCount == 0) return 0;

        uint256 startIndex = _boundToRange(epochSeed, 0, claimableEpochCount - 1);
        for (uint256 i; i < claimableEpochCount; ++i) {
            uint256 index = (startIndex + i) % claimableEpochCount;
            uint256 candidate = ghost_claimableEpochs[index];
            if (_claimableAmount(actor, candidate, claimKind) != 0) return candidate;
        }

        return 0;
    }

    function _claimableAmount(address actor, uint256 epochNonce, ClaimKind claimKind) internal view returns (uint256) {
        if (claimKind == ClaimKind.DEPOSIT) return ghost_depositedByActorByEpoch[actor][epochNonce];
        return ghost_shareBurnedByActorByEpoch[actor][epochNonce];
    }

    function _recordFeeBurden(uint256 treasuryShareBalanceBefore, uint256 totalSharesBefore) internal {
        if (totalSharesBefore == 0) return;

        uint256 treasuryShareBalanceAfter = parent.share.balanceOf(parent.vault.getTreasury());
        if (treasuryShareBalanceAfter <= treasuryShareBalanceBefore) return;

        uint256 feeShares = treasuryShareBalanceAfter - treasuryShareBalanceBefore;
        uint256 feeValue = _shareValue(feeShares);
        if (feeValue == 0) return;

        for (uint256 i; i < s_actors.length; ++i) {
            address actor = s_actors[i];
            uint256 feeBearingShares = _feeBearingShares(actor);
            if (feeBearingShares != 0) {
                ghost_feeBurdenByActor[actor] += feeValue * feeBearingShares / totalSharesBefore;
            }
        }
    }

    function _actorRedemptionEntitlement(address actor) internal view returns (uint256 entitlement) {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();

        entitlement += ghost_totalUsdcClaimedByActor[actor];
        entitlement += ghost_depositedByActorByEpoch[actor][currentEpochNonce];
        entitlement += _shareValue(parent.share.balanceOf(actor));
        entitlement += _shareValue(ghost_shareBurnedByActorByEpoch[actor][currentEpochNonce]);

        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            entitlement += _claimableDepositShareValue(actor, epochNonce);
            entitlement += _claimableWithdrawUsdc(actor, epochNonce);
        }
    }

    function _feeBearingShares(address actor) internal view returns (uint256 shares) {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();

        shares += parent.share.balanceOf(actor);
        shares += ghost_shareBurnedByActorByEpoch[actor][currentEpochNonce];

        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            shares += _claimableDepositShares(actor, epochNonce);
            shares += ghost_shareBurnedByActorByEpoch[actor][epochNonce];
        }
    }

    function _claimableDepositShareValue(address actor, uint256 epochNonce) internal view returns (uint256) {
        return _shareValue(_claimableDepositShares(actor, epochNonce));
    }

    function _claimableDepositShares(address actor, uint256 epochNonce) internal view returns (uint256 shares) {
        uint256 depositAmount = ghost_depositedByActorByEpoch[actor][epochNonce];
        if (depositAmount == 0) return 0;

        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
        if (epoch.remainingDepositClaimAmount == 0) return 0;

        if (depositAmount == epoch.remainingDepositClaimAmount) return epoch.remainingShareMintAmount;
        return depositAmount * epoch.remainingShareMintAmount / epoch.remainingDepositClaimAmount;
    }

    function _claimableWithdrawUsdc(address actor, uint256 epochNonce) internal view returns (uint256 usdcAmount) {
        uint256 shareBurnAmount = ghost_shareBurnedByActorByEpoch[actor][epochNonce];
        if (shareBurnAmount == 0) return 0;

        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
        if (epoch.remainingShareBurnAmount == 0) return 0;

        if (shareBurnAmount == epoch.remainingShareBurnAmount) return epoch.remainingWithdrawClaimAmount;
        return shareBurnAmount * epoch.remainingWithdrawClaimAmount / epoch.remainingShareBurnAmount;
    }

    function _shareValue(uint256 shares) internal view returns (uint256) {
        return shares * _currentPricePerShare() / SHARE_PRECISION;
    }

    function _currentPricePerShare() internal view returns (uint256) {
        uint256 totalShares = parent.vault.getTotalShares();
        uint256 tvl = _activeStrategyTvl();

        if (totalShares != 0 && tvl != 0) return tvl * SHARE_PRECISION / totalShares;
        return SHARE_PRECISION;
    }
}
