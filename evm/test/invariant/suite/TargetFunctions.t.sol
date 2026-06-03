// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Properties} from "./Properties.t.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    uint256 internal constant PERFORMANCE_FEE_BPS = 777;
    uint256 internal constant SHARE_BOOTSTRAP_DEPOSIT_AMOUNT = 1_000_000_000_000 * 1e6;
    address internal constant INVALID_CCIP_RECEIVER = address(1);

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

        uint256 tvl = _activeStrategyTvl();
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc =
            parent.vault.getEpoch(epochNonce).totalShareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        uint256 netWithdrawAmount = totalWithdrawUsdc > totalDepositAmount ? totalWithdrawUsdc - totalDepositAmount : 0;

        if (netWithdrawAmount != 0) {
            _setActiveStrategyWithdrawReturn(netWithdrawAmount);
        }

        uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
        uint256 totalSharesBefore = parent.vault.getTotalShares();

        __before();

        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );
        if (parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING) {
            _settleRemoteEpochWithdraw(epochNonce, netWithdrawAmount);
        }

        __after();

        _recordEpochClosed(epochNonce);
        _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);

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

    function handler_initiateRebalance(uint256 pathSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        public
    {
        if (parent.vault.getEpochNonce() == 1 || _activeStrategyTvl() == 0) {
            handler_claimShares(actorSeed, 0, amountSeed);
        }

        Types.Strategy memory target = _rebalanceTarget(pathSeed, protocolSeed);
        uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
        uint256 totalSharesBefore = parent.vault.getTotalShares();

        __before();
        _rebalanceTo(target);
        __after();

        _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);

        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        t(rebalance.activeStrategy.protocolId == target.protocolId, "REBALANCE: active protocol mismatch");
        eq(
            uint256(rebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBALANCE: active chain mismatch"
        );
        t(rebalance.pendingStrategy.protocolId == bytes32(0), "REBALANCE: pending protocol not cleared");
        eq(uint256(rebalance.pendingStrategy.chainSelector), 0, "REBALANCE: pending chain not cleared");
        eq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE), "REBALANCE: state not cleared");
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

    function handler_withdraw(uint256 actorSeed, uint256 shareSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);

        if (parent.share.balanceOf(actor) == 0) {
            _ensureActorHasShares(actorSeed, amountSeed);
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

    function handler_cancelWithdraw(uint256 actorSeed, uint256 shareSeed, uint256 epochSeed, uint256 amountSeed)
        public
    {
        address actor = _actor(actorSeed);

        if (parent.vault.getWithdrawShareBurnAmount(actor, parent.vault.getEpochNonce()) == 0) {
            handler_withdraw(actorSeed, shareSeed, amountSeed);
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
        eq(_after.actorCurrentEpochWithdrawShareBurnAmount, 0, "EPOCH-013: cancelWithdraw did not clear actor withdraw");
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
            handler_withdraw(actorSeed, shareSeed, amountSeed);
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

        _recordUsdcClaimed(actor, claimEpochNonce, usdcWithdrawAmount);
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

    function handler_donate(uint256, uint256 amountSeed) public {
        s_currentActor = i_donateOperator;
        uint256 amount = _clampDepositAmount(amountSeed);
        uint256 tvlBefore = _activeStrategyTvl();
        if (tvlBefore > 1 && amount > MAX_DONATE_AMOUNT_WHEN_FUNDED) amount = MAX_DONATE_AMOUNT_WHEN_FUNDED;
        uint256 totalSharesBefore = parent.vault.getTotalShares();
        uint256 epochNonceBefore = parent.vault.getEpochNonce();

        // @review if epochNonceBefore == 1, then we should not donate and instead advance the state in another way

        _changePrank(i_donateOperator);
        _donateToActiveVault(amount);

        eq(_activeStrategyTvl(), tvlBefore + amount, "DONATE-001: active strategy TVL did not increase");
        eq(parent.vault.getTotalShares(), totalSharesBefore, "DONATE-002: donation minted shares");
        eq(parent.vault.getEpochNonce(), epochNonceBefore, "DONATE-003: donation changed epoch nonce");
    }

    function handler_recoverFailedCcipSend(
        uint256,
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) public {
        ChildVault activeChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActorHasShares(actorSeed, amountSeed);
        _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        address actor = _actor(actorSeed);
        s_currentActor = actor;
        uint256 shareBurnAmount = parent.share.balanceOf(actor);
        uint256 epochNonce = parent.vault.getEpochNonce();
        eq(parent.vault.getEpoch(epochNonce).totalDepositAmount, 0, "CCIP recovery: staged epoch has deposits");
        t(shareBurnAmount != 0, "CCIP recovery: actor has no shares");

        __before();

        _changePrank(actor);
        parent.vault.withdraw(shareBurnAmount);

        __after();

        _recordWithdraw(actor, shareBurnAmount);

        eq(_after.epochNonce, _before.epochNonce, "CCIP recovery: withdraw changed epoch nonce");
        eq(
            _after.currentEpochTotalShareBurnAmount,
            _before.currentEpochTotalShareBurnAmount + shareBurnAmount,
            "CCIP recovery: withdraw did not increase current epoch share burn total"
        );
        eq(
            _after.actorCurrentEpochWithdrawShareBurnAmount,
            _before.actorCurrentEpochWithdrawShareBurnAmount + shareBurnAmount,
            "CCIP recovery: withdraw did not increase actor current epoch share burn amount"
        );
        eq(_after.actorShareBalance, _before.actorShareBalance - shareBurnAmount, "CCIP recovery: shares not escrowed");

        uint256 tvl = _activeStrategyTvl();
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        uint256 netWithdrawAmount = totalWithdrawUsdc - totalDepositAmount;
        t(netWithdrawAmount != 0, "CCIP recovery: net withdraw is zero");

        _setActiveStrategyWithdrawReturn(netWithdrawAmount);

        uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
        uint256 totalSharesBefore = parent.vault.getTotalShares();

        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "CCIP recovery: parent epoch did not enter executing"
        );

        _breakParentDestination(activeChild);
        _executeEpochWithdraw(activeChild, epochNonce, netWithdrawAmount);
        _restoreParentDestination(activeChild);

        _assertPendingCcipSendRecovery(
            activeChild,
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            PARENT_CHAIN_SELECTOR,
            netWithdrawAmount,
            abi.encode(epochNonce)
        );
        lte(
            netWithdrawAmount,
            IERC20(parent.vault.getUsdc()).balanceOf(address(activeChild)),
            "CCIP recovery: pending send is not collateralized"
        );

        activeChild.recoverFailedCcipSend();
        _assertCcipSendRecoveryCleared(activeChild);

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "CCIP recovery: parent epoch not claimable after retry"
        );
        t(!activeChild.getRecoveryExists(), "CCIP recovery: child still has recovery");

        _recordEpochClosed(epochNonce);
        _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);
    }

    function _settlementPricePerShare(uint256 tvl) internal view returns (uint256 pricePerShare) {
        uint256 totalShares = parent.vault.getTotalShares();
        if (totalShares != 0 && tvl != 0) return tvl * SHARE_PRECISION / totalShares;
        return SHARE_PRECISION;
    }

    function _closeEpochSettlementPricePerShare(uint256 tvl) internal view returns (uint256 settlementPricePerShare) {
        uint256 grossPricePerShare = _settlementPricePerShare(tvl);
        uint256 highWaterMark = parent.vault.getPerformanceFeeHighWaterMark();
        if (grossPricePerShare <= highWaterMark) return grossPricePerShare;

        uint256 totalShares = parent.vault.getTotalShares();
        uint256 totalYield = _ceilDiv((grossPricePerShare - highWaterMark) * totalShares, SHARE_PRECISION);
        uint256 feeUsdc = _ceilDiv(totalYield * PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);
        if (feeUsdc >= tvl) return grossPricePerShare;

        uint256 feeShares = _ceilDiv(feeUsdc * totalShares, tvl - feeUsdc);
        return tvl * SHARE_PRECISION / (totalShares + feeShares);
    }

    function _ceilDiv(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return numerator == 0 ? 0 : (numerator - 1) / denominator + 1;
    }

    function _rebalanceTo(Types.Strategy memory target) internal {
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        uint256 tvlBefore = _activeStrategyTvl();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        if (beforeRebalance.activeStrategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            _executeRebalanceThroughWorkflow(
                child.workflowRouter,
                EXECUTE_REBALANCE_WORKFLOW_ID,
                EXECUTE_REBALANCE_WORKFLOW_NAME,
                i_owner,
                beforeRebalance.nonce,
                target
            );
        } else if (beforeRebalance.activeStrategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            _executeRebalanceThroughWorkflow(
                remoteChild.workflowRouter,
                EXECUTE_REBALANCE_WORKFLOW_ID,
                EXECUTE_REBALANCE_WORKFLOW_NAME,
                i_owner,
                beforeRebalance.nonce,
                target
            );
        }

        if (parent.vault.getRebalance().state == Types.RebalanceState.REBALANCING) {
            _completeRebalanceThroughWorkflow(
                parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
            );
        }

        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();

        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBALANCE: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), "REBALANCE: state is not none");
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBALANCE: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBALANCE: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBALANCE: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBALANCE: pending chain still set");
        eq(_activeStrategyTvl(), tvlBefore, "REBALANCE: TVL changed during rebalance");
        _assertActiveAdapterFor(target);
    }

    function _settleRemoteEpochWithdraw(uint256 epochNonce, uint256 amount) internal {
        uint64 chainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        if (chainSelector == CHILD_CHAIN_SELECTOR) {
            _executeEpochWithdrawThroughWorkflow(
                child.workflowRouter,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
                i_owner,
                epochNonce,
                amount
            );
        } else if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            _executeEpochWithdrawThroughWorkflow(
                remoteChild.workflowRouter,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
                i_owner,
                epochNonce,
                amount
            );
        }
    }

    function _ensureActiveStrategyOnChild(ChildVault vault, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
        uint64 selectedChainSelector = _childChainSelector(vault);

        if (parent.vault.getRebalance().activeStrategy.chainSelector == selectedChainSelector) {
            if (_activeStrategyTvl() == 0) handler_donate(actorSeed, amountSeed);
        } else {
            if (parent.vault.getEpochNonce() == 1 || _activeStrategyTvl() == 0) {
                handler_claimShares(actorSeed, 0, amountSeed);
            }

            Types.Strategy memory target = selectedChainSelector == CHILD_CHAIN_SELECTOR
                ? _childStrategy(_protocolId(protocolSeed))
                : _remoteChildStrategy(_protocolId(protocolSeed));
            uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
            uint256 totalSharesBefore = parent.vault.getTotalShares();

            __before();
            _rebalanceTo(target);
            __after();

            _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);
        }
    }

    function _ensureActorHasShares(uint256 actorSeed, uint256 amountSeed) internal {
        address actor = _actor(actorSeed);
        if (parent.share.balanceOf(actor) == 0) {
            handler_claimShares(actorSeed, 0, _shareBootstrapAmount(amountSeed));
        }
        if (parent.share.balanceOf(actor) == 0) {
            _bootstrapActorShares(actor);
        }
    }

    function _closeCurrentEpochIfNotEmpty() internal {
        uint256 epochNonce = parent.vault.getEpochNonce();
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

        if (epoch.totalDepositAmount != 0 || epoch.totalShareBurnAmount != 0) {
            handler_closeEpoch(0);
        }
    }

    function _shareBootstrapAmount(uint256 amountSeed) internal pure returns (uint256 amount) {
        amount = _clampDepositAmount(amountSeed);
        if (amount < MAX_DEPOSIT_AMOUNT) amount = MAX_DEPOSIT_AMOUNT;
    }

    function _bootstrapActorShares(address actor) internal {
        _closeCurrentEpochIfNotEmpty();

        s_currentActor = actor;
        uint256 depositEpochNonce = parent.vault.getEpochNonce();

        _changePrank(actor);
        parent.vault.deposit(SHARE_BOOTSTRAP_DEPOSIT_AMOUNT);
        _recordDeposit(actor, SHARE_BOOTSTRAP_DEPOSIT_AMOUNT);

        handler_closeEpoch(0);

        s_currentActor = actor;
        s_targetEpochNonce = depositEpochNonce;

        _changePrank(actor);
        uint256 shareMintAmount = parent.vault.claimShares(depositEpochNonce);
        _recordSharesClaimed(actor, depositEpochNonce, shareMintAmount);
        _checkAndUpdateDepositRemainingCounterMax(depositEpochNonce);

        t(parent.share.balanceOf(actor) != 0, "CCIP recovery: actor has no shares");
    }

    function _childVaultBySeed(uint256 childSeed) internal view returns (ChildVault vault) {
        vault = childSeed % 2 == 0 ? child.vault : remoteChild.vault;
    }

    function _childChainSelector(ChildVault vault) internal view returns (uint64 chainSelector) {
        if (address(vault) == address(child.vault)) {
            chainSelector = CHILD_CHAIN_SELECTOR;
        } else if (address(vault) == address(remoteChild.vault)) {
            chainSelector = REMOTE_CHILD_CHAIN_SELECTOR;
        }
    }

    function _breakParentDestination(ChildVault vault) internal {
        _setCrosschainVault(vault, PARENT_CHAIN_SELECTOR, INVALID_CCIP_RECEIVER);
    }

    function _restoreParentDestination(ChildVault vault) internal {
        _setCrosschainVault(vault, PARENT_CHAIN_SELECTOR, address(parent.vault));
    }

    function _executeEpochWithdraw(ChildVault vault, uint256 epochNonce, uint256 amount) internal {
        if (address(vault) == address(child.vault)) {
            _executeEpochWithdrawThroughWorkflow(
                child.workflowRouter,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
                i_owner,
                epochNonce,
                amount
            );
        } else {
            _executeEpochWithdrawThroughWorkflow(
                remoteChild.workflowRouter,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
                EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
                i_owner,
                epochNonce,
                amount
            );
        }
    }

    function _assertPendingCcipSendRecovery(
        ChildVault vault,
        Types.CcipTx ccipTxType,
        uint64 destinationChainSelector,
        uint256 amount,
        bytes memory txData
    ) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), uint256(ccipTxType), "CCIP recovery: wrong tx type");
        eq(
            uint256(recovery.destinationChainSelector),
            uint256(destinationChainSelector),
            "CCIP recovery: wrong destination"
        );
        eq(recovery.amount, amount, "CCIP recovery: wrong amount");
        t(keccak256(recovery.txData) == keccak256(txData), "CCIP recovery: wrong tx data");
        t(recovery.createdAt != 0, "CCIP recovery: timestamp not set");
    }

    function _assertCcipSendRecoveryCleared(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), 0, "CCIP recovery: tx type not cleared");
        eq(recovery.amount, 0, "CCIP recovery: amount not cleared");
        eq(uint256(recovery.destinationChainSelector), 0, "CCIP recovery: destination not cleared");
        eq(recovery.txData.length, 0, "CCIP recovery: tx data not cleared");
        eq(recovery.createdAt, 0, "CCIP recovery: timestamp not cleared");
    }

    function _donateToActiveVault(uint256 amount) internal {
        uint64 chainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        if (chainSelector == PARENT_CHAIN_SELECTOR) {
            parent.vault.donate(amount);
        } else if (chainSelector == CHILD_CHAIN_SELECTOR) {
            child.vault.donate(amount);
        } else if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            remoteChild.vault.donate(amount);
        } else {
            t(false, "DONATE-004: active strategy chain is unsupported");
        }
    }

    function _rebalanceTarget(uint256 pathSeed, uint256 protocolSeed)
        internal
        view
        returns (Types.Strategy memory target)
    {
        bytes32 protocolId = _protocolId(protocolSeed);
        uint256 path = pathSeed % 3;

        if (path == 0) {
            target = _parentStrategy(protocolId);
        } else if (path == 1) {
            target = _childStrategy(protocolId);
        } else {
            target = _remoteChildStrategy(protocolId);
        }

        Types.Strategy memory activeStrategy = parent.vault.getRebalance().activeStrategy;
        if (target.protocolId == activeStrategy.protocolId && target.chainSelector == activeStrategy.chainSelector) {
            target.protocolId = _differentProtocol(protocolId);
        }
    }

    function _protocolId(uint256 protocolSeed) internal pure returns (bytes32) {
        uint256 protocol = protocolSeed % 3;
        if (protocol == 0) return AAVE_V3_PROTOCOL_ID;
        if (protocol == 1) return AAVE_V4_PROTOCOL_ID;
        return COMPOUND_V3_PROTOCOL_ID;
    }

    function _differentProtocol(bytes32 protocolId) internal pure returns (bytes32) {
        if (protocolId == AAVE_V3_PROTOCOL_ID) return AAVE_V4_PROTOCOL_ID;
        return AAVE_V3_PROTOCOL_ID;
    }

    function _assertActiveAdapterFor(Types.Strategy memory strategy) internal {
        if (strategy.chainSelector == PARENT_CHAIN_SELECTOR) {
            t(parent.vault.getActiveProtocolAdapter() == _adapterFor(strategy), "REBALANCE: wrong parent adapter");
        } else if (strategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBALANCE: parent adapter is not remote");
            t(child.vault.getActiveProtocolAdapter() == _adapterFor(strategy), "REBALANCE: wrong child adapter");
        } else if (strategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBALANCE: parent adapter is not remote");
            t(
                remoteChild.vault.getActiveProtocolAdapter() == _adapterFor(strategy),
                "REBALANCE: wrong remote child adapter"
            );
        }
    }

    function _adapterFor(Types.Strategy memory strategy) internal view returns (address adapter) {
        if (strategy.chainSelector == PARENT_CHAIN_SELECTOR) {
            return parent.adapterRegistry.getAdapter(strategy.protocolId);
        }
        if (strategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            return child.adapterRegistry.getAdapter(strategy.protocolId);
        }
        if (strategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            return remoteChild.adapterRegistry.getAdapter(strategy.protocolId);
        }
        return address(0);
    }
}
