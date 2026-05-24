// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {CcipGhosts} from "./CcipGhosts.t.sol";
import {Types} from "../../../../src/libraries/Types.sol";

abstract contract EpochGhosts is CcipGhosts {
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
    mapping(uint256 epochNonce => bool isClaimable) internal ghost_epochIsClaimable;
    uint256[] internal ghost_claimableEpochs;

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

        ghost_epochIsClaimable[epochNonce] = true;
        ghost_totalShareMintedByEpoch[epochNonce] = epoch.remainingShareMintAmount;
        ghost_maxRemainingDepositClaimAmountByEpoch[epochNonce] = epoch.remainingDepositClaimAmount;
        ghost_maxRemainingShareMintAmountByEpoch[epochNonce] = epoch.remainingShareMintAmount;
        ghost_maxRemainingShareBurnAmountByEpoch[epochNonce] = epoch.remainingShareBurnAmount;
        ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce] = epoch.remainingWithdrawClaimAmount;
        ghost_claimableEpochs.push(epochNonce);
    }

    function _recordSharesClaimed(address actor, uint256 epochNonce, uint256 shareMintAmount) internal {
        ghost_depositedByActorByEpoch[actor][epochNonce] = 0;
        ghost_shareBalanceByActor[actor] += shareMintAmount;
    }

    function _checkAndUpdateDepositRemainingCounterMax(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

        if (epoch.remainingDepositClaimAmount > ghost_maxRemainingDepositClaimAmountByEpoch[epochNonce]) {
            revert("EPOCH-007: remaining deposit claims increased");
        }
        if (epoch.remainingShareMintAmount > ghost_maxRemainingShareMintAmountByEpoch[epochNonce]) {
            revert("EPOCH-007: remaining share mints increased");
        }

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

    function _recordUsdcClaimed(address actor, uint256 epochNonce) internal {
        ghost_shareBurnedByActorByEpoch[actor][epochNonce] = 0;
    }

    function _checkAndUpdateWithdrawRemainingCounterMax(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

        if (epoch.remainingShareBurnAmount > ghost_maxRemainingShareBurnAmountByEpoch[epochNonce]) {
            revert("EPOCH-010: remaining share burns increased");
        }
        if (epoch.remainingWithdrawClaimAmount > ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce]) {
            revert("EPOCH-010: remaining withdraw claims increased");
        }

        ghost_maxRemainingShareBurnAmountByEpoch[epochNonce] = epoch.remainingShareBurnAmount;
        ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce] = epoch.remainingWithdrawClaimAmount;
    }

    function _claimableDepositEpoch(address actor, uint256 epochSeed) internal view returns (uint256 epochNonce) {
        uint256 claimableEpochCount = ghost_claimableEpochs.length;
        if (claimableEpochCount == 0) return 0;

        uint256 startIndex = _boundToRange(epochSeed, 0, claimableEpochCount - 1);
        for (uint256 i; i < claimableEpochCount; ++i) {
            uint256 index = (startIndex + i) % claimableEpochCount;
            uint256 candidate = ghost_claimableEpochs[index];
            if (ghost_depositedByActorByEpoch[actor][candidate] != 0) return candidate;
        }

        return 0;
    }

    function _claimableWithdrawEpoch(address actor, uint256 epochSeed) internal view returns (uint256 epochNonce) {
        uint256 claimableEpochCount = ghost_claimableEpochs.length;
        if (claimableEpochCount == 0) return 0;

        uint256 startIndex = _boundToRange(epochSeed, 0, claimableEpochCount - 1);
        for (uint256 i; i < claimableEpochCount; ++i) {
            uint256 index = (startIndex + i) % claimableEpochCount;
            uint256 candidate = ghost_claimableEpochs[index];
            if (ghost_shareBurnedByActorByEpoch[actor][candidate] != 0) return candidate;
        }

        return 0;
    }
}
