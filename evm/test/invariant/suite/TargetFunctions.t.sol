// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Properties} from "./Properties.t.sol";
import {Types} from "../../../src/libraries/Types.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    function handler_deposit(uint256 actorSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);
        s_currentActor = actor;

        uint256 amount = _clampDepositAmount(amountSeed);
        uint256 epochNonce = parent.vault.getEpochNonce();

        __before();

        _changePrank(actor);
        parent.vault.deposit(amount);

        __after();

        _recordDeposit(actor, amount);

        eq(_after.epochNonce, epochNonce, "EPOCH-005: deposit changed epoch nonce");
        eq(
            _after.currentEpochTotalDepositAmount,
            _before.currentEpochTotalDepositAmount + amount,
            "EPOCH-005: deposit did not increase current epoch total"
        );
        eq(
            _after.actorCurrentEpochDepositAmount,
            _before.actorCurrentEpochDepositAmount + amount,
            "EPOCH-005: deposit did not increase actor current epoch deposit"
        );
    }

    function handler_cancelDeposit(uint256 actorSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);
        uint256 epochNonce = parent.vault.getEpochNonce();

        if (parent.vault.getDepositAmount(actor, epochNonce) == 0) {
            handler_deposit(actorSeed, amountSeed);
        }

        s_currentActor = actor;
        uint256 amount = parent.vault.getDepositAmount(actor, epochNonce);

        __before();

        _changePrank(actor);
        parent.vault.cancelDeposit();

        __after();

        _recordDepositCancelled(actor, amount);

        eq(_after.epochNonce, epochNonce, "EPOCH-005: cancelDeposit changed epoch nonce");
        eq(
            _after.currentEpochTotalDepositAmount,
            _before.currentEpochTotalDepositAmount - amount,
            "EPOCH-005: cancelDeposit did not decrease current epoch total"
        );
        eq(_after.actorCurrentEpochDepositAmount, 0, "EPOCH-013: cancelDeposit did not clear actor deposit");
        eq(_after.actorUsdcBalance, _before.actorUsdcBalance + amount, "EPOCH-006: cancelDeposit did not refund USDC");
        eq(
            ghost_depositedByActorByEpoch[actor][epochNonce],
            0,
            "EPOCH-013: cancelDeposit did not clear actor deposit ghost"
        );
    }

    function handler_closeEpoch(uint256 tvlSeed) public {
        uint256 epochNonce = parent.vault.getEpochNonce();

        if (
            parent.vault.getEpoch(epochNonce).totalDepositAmount == 0
                && parent.vault.getEpoch(epochNonce).totalShareBurnAmount == 0
        ) {
            handler_deposit(tvlSeed, MIN_DEPOSIT_AMOUNT);
        }

        uint256 tvl = epochNonce == 1 ? 0 : _activeStrategyTvl();
        uint256 settlementPricePerShare = _settlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc =
            parent.vault.getEpoch(epochNonce).totalShareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;

        if (totalWithdrawUsdc > totalDepositAmount && parent.vault.getActiveProtocolAdapter() != address(0)) {
            _setParentActiveProtocolExpectedWithdraw(totalWithdrawUsdc - totalDepositAmount);
        }

        __before();

        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _closeEpochThroughWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl);

        __after();

        _recordEpochClosed(epochNonce);

        eq(_after.epochNonce, epochNonce + 1, "EPOCH-004: closeEpoch did not increment epoch nonce");
        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "EPOCH-004: closeEpoch did not make epoch claimable"
        );
        t(
            parent.vault.getEpoch(epochNonce + 1).status == Types.EpochStatus.OPEN,
            "EPOCH-004: closeEpoch did not open next epoch"
        );
        eq(
            parent.vault.getEpoch(epochNonce).remainingDepositClaimAmount,
            _before.currentEpochTotalDepositAmount,
            "closeEpoch did not initialize remaining deposit claims"
        );
    }

    function handler_claimShares(uint256 actorSeed, uint256 epochSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);
        uint256 claimEpochNonce = _claimableDepositEpoch(actor, epochSeed);

        if (claimEpochNonce == 0) {
            handler_deposit(actorSeed, amountSeed);
            handler_closeEpoch(0);
            claimEpochNonce = _claimableDepositEpoch(actor, epochSeed);
        }

        s_currentActor = actor;
        s_targetEpochNonce = claimEpochNonce;
        uint256 depositAmount = parent.vault.getDepositAmount(actor, claimEpochNonce);

        __before();

        _changePrank(actor);
        uint256 shareMintAmount = parent.vault.claimShares(claimEpochNonce);

        __after();

        _recordSharesClaimed(actor, claimEpochNonce, shareMintAmount);
        _checkAndUpdateDepositRemainingCounterMax(claimEpochNonce);

        eq(_after.epochNonce, _before.epochNonce, "claimShares changed current epoch nonce");
        eq(_after.actorTargetEpochDepositAmount, 0, "EPOCH-013: claimShares did not clear actor deposit");
        eq(
            ghost_depositedByActorByEpoch[actor][claimEpochNonce],
            0,
            "EPOCH-013: claimShares did not clear actor deposit ghost"
        );
        eq(
            _after.targetEpochRemainingDepositClaimAmount,
            _before.targetEpochRemainingDepositClaimAmount - depositAmount,
            "claimShares did not decrease remaining deposit claims"
        );
        eq(
            _after.targetEpochRemainingShareMintAmount,
            _before.targetEpochRemainingShareMintAmount - shareMintAmount,
            "claimShares did not decrease remaining share mints"
        );
        eq(_after.actorShareBalance, _before.actorShareBalance + shareMintAmount, "claimShares did not mint shares");
    }

    function handler_withdraw(uint256 actorSeed, uint256 shareSeed, uint256 epochSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);

        if (parent.share.balanceOf(actor) == 0) {
            handler_claimShares(actorSeed, epochSeed, amountSeed);
        }

        s_currentActor = actor;
        uint256 shareBurnAmount = _clampWithdrawShareBurnAmount(shareSeed, parent.share.balanceOf(actor));

        __before();

        _changePrank(actor);
        parent.vault.withdraw(shareBurnAmount);

        __after();

        _recordWithdraw(actor, shareBurnAmount);

        eq(_after.epochNonce, _before.epochNonce, "EPOCH-005: withdraw changed epoch nonce");
        eq(
            _after.currentEpochTotalShareBurnAmount,
            _before.currentEpochTotalShareBurnAmount + shareBurnAmount,
            "EPOCH-005: withdraw did not increase current epoch share burn total"
        );
        eq(
            _after.actorCurrentEpochWithdrawShareBurnAmount,
            _before.actorCurrentEpochWithdrawShareBurnAmount + shareBurnAmount,
            "EPOCH-005: withdraw did not increase actor current epoch share burn amount"
        );
        eq(_after.actorShareBalance, _before.actorShareBalance - shareBurnAmount, "withdraw did not transfer shares");
    }

    function handler_cancelWithdraw(uint256 actorSeed, uint256 shareSeed, uint256 epochSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);

        if (parent.vault.getWithdrawShareBurnAmount(actor, parent.vault.getEpochNonce()) == 0) {
            handler_withdraw(actorSeed, shareSeed, epochSeed, amountSeed);
        }

        s_currentActor = actor;
        uint256 epochNonce = parent.vault.getEpochNonce();
        uint256 shareBurnAmount = parent.vault.getWithdrawShareBurnAmount(actor, epochNonce);

        __before();

        _changePrank(actor);
        parent.vault.cancelWithdraw();

        __after();

        _recordWithdrawCancelled(actor, shareBurnAmount);

        eq(_after.epochNonce, epochNonce, "EPOCH-005: cancelWithdraw changed epoch nonce");
        eq(
            _after.currentEpochTotalShareBurnAmount,
            _before.currentEpochTotalShareBurnAmount - shareBurnAmount,
            "EPOCH-005: cancelWithdraw did not decrease current epoch share burn total"
        );
        eq(
            _after.actorCurrentEpochWithdrawShareBurnAmount,
            0,
            "EPOCH-013: cancelWithdraw did not clear actor withdraw"
        );
        eq(
            ghost_shareBurnedByActorByEpoch[actor][epochNonce],
            0,
            "EPOCH-013: cancelWithdraw did not clear actor withdraw ghost"
        );
        eq(
            _after.actorShareBalance,
            _before.actorShareBalance + shareBurnAmount,
            "EPOCH-006: cancelWithdraw did not refund shares"
        );
    }

    function handler_claimUsdc(uint256 actorSeed, uint256 epochSeed, uint256 shareSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);
        uint256 claimEpochNonce = _claimableWithdrawEpoch(actor, epochSeed);

        if (claimEpochNonce == 0) {
            handler_withdraw(actorSeed, shareSeed, epochSeed, amountSeed);
            handler_closeEpoch(0);
            claimEpochNonce = _claimableWithdrawEpoch(actor, epochSeed);
        }

        s_currentActor = actor;
        s_targetEpochNonce = claimEpochNonce;
        uint256 shareBurnAmount = parent.vault.getWithdrawShareBurnAmount(actor, claimEpochNonce);

        __before();

        _changePrank(actor);
        uint256 usdcWithdrawAmount = parent.vault.claimUsdc(claimEpochNonce);

        __after();

        _recordUsdcClaimed(actor, claimEpochNonce);
        _checkAndUpdateWithdrawRemainingCounterMax(claimEpochNonce);

        eq(_after.epochNonce, _before.epochNonce, "claimUsdc changed current epoch nonce");
        eq(_after.actorTargetEpochWithdrawShareBurnAmount, 0, "EPOCH-013: claimUsdc did not clear actor withdraw");
        eq(
            ghost_shareBurnedByActorByEpoch[actor][claimEpochNonce],
            0,
            "EPOCH-013: claimUsdc did not clear actor withdraw ghost"
        );
        eq(
            _after.targetEpochRemainingShareBurnAmount,
            _before.targetEpochRemainingShareBurnAmount - shareBurnAmount,
            "claimUsdc did not decrease remaining share burns"
        );
        eq(
            _after.targetEpochRemainingWithdrawClaimAmount,
            _before.targetEpochRemainingWithdrawClaimAmount - usdcWithdrawAmount,
            "claimUsdc did not decrease remaining withdraw claims"
        );
        eq(_after.actorUsdcBalance, _before.actorUsdcBalance + usdcWithdrawAmount, "claimUsdc did not transfer USDC");
    }

    function _settlementPricePerShare(uint256 tvl) internal view returns (uint256 pricePerShare) {
        uint256 totalShares = parent.vault.getTotalShares();
        if (totalShares != 0 && tvl != 0) return tvl * SHARE_PRECISION / totalShares;
        return SHARE_PRECISION;
    }
}
