// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Properties} from "./Properties.t.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../../mocks/MockComet.sol";
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

        _warpPastEpoch(epochNonce);
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
        t(rebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: active protocol mismatch");
        eq(
            uint256(rebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: active chain mismatch"
        );
        t(rebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol not cleared");
        eq(uint256(rebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain not cleared");
        eq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE), "REBAL-004: state not cleared");
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

        uint256 shareBurnAmount = _clampWithdrawShareBurnAmount(shareSeed, parent.share.balanceOf(actor));
        _withdrawAndAssert(actor, shareBurnAmount, "withdraw did not transfer shares");
    }

    function handler_cancelWithdraw(uint256 actorSeed, uint256 shareSeed, uint256 amountSeed) public {
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

    /// @notice The donate() function is intended as an emergency recovery/recapitalization operation.
    ///         The below handling demonstrates intended operational behavior.
    ///         Malicious operator/admin control is acknowledged in ../docs/KNOWN_ISSUES.md and ../docs/THREAT_MODEL.md
    function handler_emergencyDrainAndDonate() public {
        BaseVault activeVault = _activeVault();
        IERC20 usdc = IERC20(parent.vault.getUsdc());
        s_currentActor = i_donateOperator;

        __before();

        _setActiveStrategyWithdrawReturn(_before.tvl);

        _changePrank(i_pauser);
        activeVault.pause();

        vm.warp(block.timestamp + 1 days);

        uint256 receiverBalanceBefore = usdc.balanceOf(i_emergencyReceiver);

        _changePrank(i_emergencyDrainer);
        activeVault.emergencyDrain(true);

        uint256 drainedAmount = usdc.balanceOf(i_emergencyReceiver) - receiverBalanceBefore;
        lte(_before.vaultBalance, drainedAmount, "emergency drain did not recover vault balance");
        uint256 donationAmount = drainedAmount - _before.vaultBalance;

        if (_before.vaultBalance != 0) {
            _changePrank(i_emergencyReceiver);
            usdc.transfer(address(activeVault), _before.vaultBalance);
        }

        if (donationAmount != 0) {
            _changePrank(i_emergencyReceiver);
            usdc.transfer(i_donateOperator, donationAmount);

            _changePrank(i_donateOperator);
            activeVault.donate(donationAmount);
        }

        _changePrank(i_unpauser);
        activeVault.unpause();

        __after();

        eq(_after.tvl, _before.tvl, "DONATE-001: emergency donation did not restore active strategy TVL");
        eq(_after.totalShares, _before.totalShares, "DONATE-002: emergency donation minted shares");
        eq(_after.epochNonce, _before.epochNonce, "DONATE-003: emergency donation changed epoch nonce");
        eq(_after.vaultBalance, _before.vaultBalance, "emergency donation changed vault balance");
    }

    function handler_recoverFailedCcipSend(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) public {
        if (childSeed % 2 == 0) {
            _recoverFailedCcipSendEpochWithdraw(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        } else {
            _recoverFailedCcipSendRebalance(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        }
    }

    /// @notice When the outbound CCIP send message fails for a Types.CcipTx.EPOCH_NET_WITHDRAW
    function _recoverFailedCcipSendEpochWithdraw(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        ChildVault activeChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActorHasShares(actorSeed, amountSeed);
        _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        address actor = _actor(actorSeed);
        uint256 shareBurnAmount = parent.share.balanceOf(actor);
        uint256 epochNonce = parent.vault.getEpochNonce();
        eq(parent.vault.getEpoch(epochNonce).totalDepositAmount, 0, "EPOCH-014: staged epoch has deposits");
        t(shareBurnAmount != 0, "EPOCH-014: recovery actor has no shares");

        _withdrawAndAssert(actor, shareBurnAmount, "EPOCH-005: shares not escrowed");

        uint256 tvl = _activeStrategyTvl();
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        uint256 netWithdrawAmount = totalWithdrawUsdc - totalDepositAmount;
        t(netWithdrawAmount != 0, "EPOCH-014: net withdraw is zero");

        _setActiveStrategyWithdrawReturn(netWithdrawAmount);

        uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
        uint256 totalSharesBefore = parent.vault.getTotalShares();

        _warpPastEpoch(epochNonce);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "EPOCH-014: parent epoch did not enter executing"
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
            "CCIP-005b: pending send is not collateralized"
        );

        activeChild.recoverFailedCcipSend();
        _assertCcipSendRecoveryCleared(activeChild);

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "CCIP-005c: parent epoch not claimable after retry"
        );
        t(!activeChild.getRecoveryExists(), "REC-003: child still has recovery");

        _recordEpochClosed(epochNonce);
        _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);
    }

    /// @notice When the outbound CCIP send message fails for a Types.CcipTx.REBALANCE
    function _recoverFailedCcipSendRebalance(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        ChildVault sourceChild = _childVaultBySeed(childSeed);
        _ensureActiveStrategyOnChild(sourceChild, protocolSeed, actorSeed, amountSeed);

        uint64 destinationChainSelector = _rebalanceRecoveryDestination(sourceChild, protocolSeed);
        address destinationVault = _crosschainVault(destinationChainSelector);
        Types.Strategy memory target = _strategy(destinationChainSelector, _protocolId(protocolSeed / 2));
        uint256 amount = _activeStrategyTvl();
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();

        t(amount != 0, "CCIP-005a: rebalance amount is zero");

        __before();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(pendingRebalance.nonce, beforeRebalance.nonce, "REBAL-005: nonce changed before completion");
        eq(
            uint256(pendingRebalance.state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing"
        );
        t(pendingRebalance.pendingStrategy.protocolId == target.protocolId, "REBAL-004: pending protocol mismatch");
        eq(
            uint256(pendingRebalance.pendingStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-004: pending chain mismatch"
        );

        _setActiveStrategyWithdrawReturn(amount);
        _breakDestination(sourceChild, destinationChainSelector);
        _executeRebalance(sourceChild, pendingRebalance.nonce, target);
        _restoreDestination(sourceChild, destinationChainSelector, destinationVault);

        _assertPendingCcipSendRecovery(
            sourceChild,
            Types.CcipTx.REBALANCE,
            destinationChainSelector,
            amount,
            abi.encode(pendingRebalance.nonce, target.protocolId)
        );
        lte(
            amount,
            IERC20(parent.vault.getUsdc()).balanceOf(address(sourceChild)),
            "CCIP-005b: pending send is not collateralized"
        );

        sourceChild.recoverFailedCcipSend();
        _assertCcipSendRecoveryCleared(sourceChild);

        if (destinationChainSelector != PARENT_CHAIN_SELECTOR) {
            _completeRebalanceThroughWorkflow(
                parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
            );
        }

        __after();

        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();
        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(
            uint256(afterRebalance.state),
            uint256(Types.RebalanceState.NONE),
            "CCIP-005c: parent rebalance not finalized after retry"
        );
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        _assertActiveAdapterFor(target);
        t(!sourceChild.getRecoveryExists(), "REC-003: child still has recovery");

        _recordFeeBurden(_before.treasuryShareBalance, _before.totalShares);
    }

    /// @notice When an epoch deposit to the active strategy fails
    function handler_recoverFailedEpochDeposit(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) public {
        ChildVault activeChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        uint256 epochNonce = parent.vault.getEpochNonce();
        uint256 amount = _clampDepositAmount(amountSeed);

        _setActiveChildDepositReverts(activeChild, true);
        handler_deposit(actorSeed, amountSeed);
        handler_closeEpoch(0);
        _setActiveChildDepositReverts(activeChild, false);

        _assertPendingEpochDepositRecovery(activeChild, epochNonce, amount);
        t(activeChild.getRecoveryExists(), "REC-002: child recovery sentinel not set");
        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "EPOCH-014: remote deposit epoch not claimable"
        );

        __before();

        activeChild.recoverFailedEpochDeposit();

        __after();

        _assertEpochDepositRecoveryCleared(activeChild);
        t(!activeChild.getRecoveryExists(), "REC-003: child still has recovery");
        eq(_after.epochNonce, _before.epochNonce, "REC-008: epoch deposit recovery changed epoch nonce");
        eq(_after.totalShares, _before.totalShares, "REC-008: epoch deposit recovery changed total shares");
        eq(_after.tvl, _before.tvl, "REC-008: epoch deposit recovery changed TVL");
    }

    /// @notice When an epoch withdraw from the active strategy fails
    function handler_recoverFailedEpochWithdraw(
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
        uint256 shareBurnAmount = parent.share.balanceOf(actor);
        uint256 epochNonce = parent.vault.getEpochNonce();
        t(shareBurnAmount != 0, "EPOCH-014: recovery actor has no shares");

        _withdrawAndAssert(actor, shareBurnAmount, "EPOCH-005: shares not escrowed");

        uint256 tvl = _activeStrategyTvl();
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 netWithdrawAmount = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;

        if (netWithdrawAmount == 0) {
            _bootstrapActorShares(actor);
            _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
            _closeCurrentEpochIfNotEmpty();

            shareBurnAmount = parent.share.balanceOf(actor);
            epochNonce = parent.vault.getEpochNonce();
            t(shareBurnAmount != 0, "EPOCH-014: recovery actor has no shares");

            _withdrawAndAssert(actor, shareBurnAmount, "EPOCH-005: shares not escrowed");

            tvl = _activeStrategyTvl();
            settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
            netWithdrawAmount = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        }

        t(netWithdrawAmount != 0, "EPOCH-014: net withdraw is zero");

        uint256 treasuryShareBalanceBefore = parent.share.balanceOf(parent.vault.getTreasury());
        uint256 totalSharesBefore = parent.vault.getTotalShares();

        _warpPastEpoch(epochNonce);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "EPOCH-014: parent epoch did not enter executing"
        );

        _setActiveChildWithdrawReverts(activeChild, true);
        _executeEpochWithdraw(activeChild, epochNonce, netWithdrawAmount);
        _setActiveChildWithdrawReverts(activeChild, false);

        _recordEpochClosed(epochNonce);
        _recordFeeBurden(treasuryShareBalanceBefore, totalSharesBefore);
        _assertPendingEpochWithdrawRecovery(activeChild, epochNonce, netWithdrawAmount);
        t(activeChild.getRecoveryExists(), "REC-002: child recovery sentinel not set");

        _setActiveStrategyWithdrawReturn(netWithdrawAmount);

        __before();

        activeChild.recoverFailedEpochWithdraw();

        __after();

        _assertEpochWithdrawRecoveryCleared(activeChild);
        t(!activeChild.getRecoveryExists(), "REC-003: child still has recovery");
        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "EPOCH-014: parent epoch not claimable after epoch withdraw recovery"
        );
        eq(_after.epochNonce, _before.epochNonce, "REC-008: epoch withdraw recovery changed epoch nonce");
        eq(_after.totalShares, _before.totalShares, "REC-008: epoch withdraw recovery changed total shares");
    }

    function handler_recoverFailedRebalanceDeposit(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) public {
        if (childSeed % 2 == 0) {
            // Even and odd seeds choose the recovery branch; the remaining seed still chooses the source child.
            _recoverFailedRebalanceDepositParent(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        } else {
            _recoverFailedRebalanceDepositChild(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        }
    }

    function _recoverFailedRebalanceDepositParent(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        ChildVault activeChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        Types.Strategy memory target = _parentStrategy(_protocolId(protocolSeed));
        uint256 amount = _activeStrategyTvl();

        t(amount != 0, "REC-005b: rebalance deposit recovery amount is zero");

        __before();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(pendingRebalance.nonce, beforeRebalance.nonce, "REBAL-005: nonce changed before completion");
        eq(
            uint256(pendingRebalance.state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing"
        );
        t(pendingRebalance.pendingStrategy.protocolId == target.protocolId, "REBAL-004: pending protocol mismatch");
        eq(
            uint256(pendingRebalance.pendingStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-004: pending chain mismatch"
        );

        _setActiveStrategyWithdrawReturn(amount);
        _setParentDepositReverts(target, true);
        _executeRebalance(activeChild, pendingRebalance.nonce, target);
        _setParentDepositReverts(target, false);

        _assertPendingRebalanceDepositRecovery(parent.vault, pendingRebalance.nonce, amount);
        t(parent.vault.getRecoveryExists(), "REC-002: parent recovery sentinel not set");
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after deposit failure"
        );

        parent.vault.recoverFailedRebalanceDeposit();

        __after();

        _assertRebalanceDepositRecoveryCleared(parent.vault);

        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();
        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), "REBAL-004: state is not none");
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        _assertActiveAdapterFor(target);

        _recordFeeBurden(_before.treasuryShareBalance, _before.totalShares);
    }

    function _recoverFailedRebalanceDepositChild(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        ChildVault sourceChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActiveStrategyOnChild(sourceChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        uint64 destinationChainSelector =
            address(sourceChild) == address(child.vault) ? REMOTE_CHILD_CHAIN_SELECTOR : CHILD_CHAIN_SELECTOR;
        ChildVault destinationChild = destinationChainSelector == CHILD_CHAIN_SELECTOR ? child.vault : remoteChild.vault;
        Types.Strategy memory target = _strategy(destinationChainSelector, _protocolId(protocolSeed));
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        uint256 amount = _activeStrategyTvl();

        t(amount != 0, "REC-005b: rebalance deposit recovery amount is zero");

        __before();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(pendingRebalance.nonce, beforeRebalance.nonce, "REBAL-005: nonce changed before completion");
        eq(
            uint256(pendingRebalance.state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing"
        );
        t(pendingRebalance.pendingStrategy.protocolId == target.protocolId, "REBAL-004: pending protocol mismatch");
        eq(
            uint256(pendingRebalance.pendingStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-004: pending chain mismatch"
        );

        _setActiveStrategyWithdrawReturn(amount);
        _setChildDepositReverts(destinationChild, target, true);
        _executeRebalance(sourceChild, pendingRebalance.nonce, target);
        _setChildDepositReverts(destinationChild, target, false);

        _assertPendingRebalanceDepositRecovery(destinationChild, pendingRebalance.nonce, amount);
        t(destinationChild.getRecoveryExists(), "REC-002: child recovery sentinel not set");
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after deposit failure"
        );

        destinationChild.recoverFailedRebalanceDeposit();

        _assertRebalanceDepositRecoveryCleared(destinationChild);
        t(!destinationChild.getRecoveryExists(), "REC-003: child still has recovery");

        _completeRebalanceThroughWorkflow(
            parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
        );

        __after();

        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();
        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), "REBAL-004: state is not none");
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        _assertActiveAdapterFor(target);

        _recordFeeBurden(_before.treasuryShareBalance, _before.totalShares);
    }

    /// @notice When a rebalance withdraw from the active Child strategy fails
    function handler_recoverFailedRebalanceWithdraw(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) public {
        ChildVault sourceChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActiveStrategyOnChild(sourceChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        uint64 destinationChainSelector = _rebalanceRecoveryDestination(sourceChild, protocolSeed);
        Types.Strategy memory target = _strategy(destinationChainSelector, _protocolId(protocolSeed / 2));
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        uint256 amount = _activeStrategyTvl();

        t(amount != 0, "REC-008: rebalance withdraw recovery amount is zero");

        __before();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(pendingRebalance.nonce, beforeRebalance.nonce, "REBAL-005: nonce changed before completion");
        eq(
            uint256(pendingRebalance.state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing"
        );
        t(pendingRebalance.pendingStrategy.protocolId == target.protocolId, "REBAL-004: pending protocol mismatch");
        eq(
            uint256(pendingRebalance.pendingStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-004: pending chain mismatch"
        );

        _setActiveChildWithdrawReverts(sourceChild, true);
        _executeRebalance(sourceChild, pendingRebalance.nonce, target);
        _setActiveChildWithdrawReverts(sourceChild, false);

        _assertPendingRebalanceWithdrawRecovery(sourceChild, pendingRebalance.nonce, target);
        t(sourceChild.getRecoveryExists(), "REC-002: child recovery sentinel not set");
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after withdraw failure"
        );

        _setActiveStrategyWithdrawReturn(amount);
        sourceChild.recoverFailedRebalanceWithdraw();
        _assertRebalanceWithdrawRecoveryCleared(sourceChild);
        t(!sourceChild.getRecoveryExists(), "REC-003: child still has recovery");

        if (destinationChainSelector != PARENT_CHAIN_SELECTOR) {
            _completeRebalanceThroughWorkflow(
                parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
            );
        }

        __after();

        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();
        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), "REBAL-004: state is not none");
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        _assertActiveAdapterFor(target);

        _recordFeeBurden(_before.treasuryShareBalance, _before.totalShares);
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

        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), "REBAL-004: state is not none");
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        eq(_activeStrategyTvl(), tvlBefore, "REBAL-006: TVL changed during rebalance");
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

    function _withdrawAndAssert(address actor, uint256 shareBurnAmount, string memory shareBalanceMessage) internal {
        s_currentActor = actor;

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
        eq(_after.actorShareBalance, _before.actorShareBalance - shareBurnAmount, shareBalanceMessage);
    }

    function _ensureActiveStrategyOnChild(ChildVault vault, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
        uint64 selectedChainSelector = _childChainSelector(vault);

        if (parent.vault.getRebalance().activeStrategy.chainSelector == selectedChainSelector) {
            if (_activeStrategyTvl() == 0) handler_claimShares(actorSeed, 0, amountSeed);
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

    function _warpPastEpoch(uint256 epochNonce) internal {
        uint256 targetTimestamp = parent.vault.getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD + 1;
        if (block.timestamp < targetTimestamp) vm.warp(targetTimestamp);
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

        t(parent.share.balanceOf(actor) != 0, "EPOCH-014: recovery actor has no shares");
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

    function _rebalanceRecoveryDestination(ChildVault sourceChild, uint256 destinationSeed)
        internal
        view
        returns (uint64 chainSelector)
    {
        if (destinationSeed % 2 == 0) return PARENT_CHAIN_SELECTOR;
        if (address(sourceChild) == address(child.vault)) return REMOTE_CHILD_CHAIN_SELECTOR;
        return CHILD_CHAIN_SELECTOR;
    }

    function _crosschainVault(uint64 chainSelector) internal view returns (address vault) {
        if (chainSelector == PARENT_CHAIN_SELECTOR) return address(parent.vault);
        if (chainSelector == CHILD_CHAIN_SELECTOR) return address(child.vault);
        if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) return address(remoteChild.vault);
        return address(0);
    }

    function _strategy(uint64 chainSelector, bytes32 protocolId)
        internal
        pure
        returns (Types.Strategy memory strategy)
    {
        if (chainSelector == PARENT_CHAIN_SELECTOR) {
            return _parentStrategy(protocolId);
        }
        if (chainSelector == CHILD_CHAIN_SELECTOR) return _childStrategy(protocolId);
        return _remoteChildStrategy(protocolId);
    }

    function _breakParentDestination(ChildVault vault) internal {
        _breakDestination(vault, PARENT_CHAIN_SELECTOR);
    }

    function _restoreParentDestination(ChildVault vault) internal {
        _restoreDestination(vault, PARENT_CHAIN_SELECTOR, address(parent.vault));
    }

    function _breakDestination(ChildVault vault, uint64 chainSelector) internal {
        _setCrosschainVault(vault, chainSelector, INVALID_CCIP_RECEIVER);
    }

    function _restoreDestination(ChildVault vault, uint64 chainSelector, address destination) internal {
        _setCrosschainVault(vault, chainSelector, destination);
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

    function _executeRebalance(ChildVault vault, uint256 rebalanceNonce, Types.Strategy memory target) internal {
        if (address(vault) == address(child.vault)) {
            _executeRebalanceThroughWorkflow(
                child.workflowRouter,
                EXECUTE_REBALANCE_WORKFLOW_ID,
                EXECUTE_REBALANCE_WORKFLOW_NAME,
                i_owner,
                rebalanceNonce,
                target
            );
        } else {
            _executeRebalanceThroughWorkflow(
                remoteChild.workflowRouter,
                EXECUTE_REBALANCE_WORKFLOW_ID,
                EXECUTE_REBALANCE_WORKFLOW_NAME,
                i_owner,
                rebalanceNonce,
                target
            );
        }
    }

    function _setActiveChildDepositReverts(ChildVault vault, bool reverts) internal {
        address activeAdapter = vault.getActiveProtocolAdapter();

        if (address(vault) == address(child.vault)) {
            _setProtocolDepositReverts(
                activeAdapter,
                address(child.aaveV3Adapter),
                address(child.aaveV4Adapter),
                address(child.compoundV3Adapter),
                child.aaveV3Adapter.getProtocolPool(),
                child.aaveV4Adapter.getProtocolPool(),
                child.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        } else {
            _setProtocolDepositReverts(
                activeAdapter,
                address(remoteChild.aaveV3Adapter),
                address(remoteChild.aaveV4Adapter),
                address(remoteChild.compoundV3Adapter),
                remoteChild.aaveV3Adapter.getProtocolPool(),
                remoteChild.aaveV4Adapter.getProtocolPool(),
                remoteChild.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        }
    }

    function _setActiveChildWithdrawReverts(ChildVault vault, bool reverts) internal {
        address activeAdapter = vault.getActiveProtocolAdapter();

        if (address(vault) == address(child.vault)) {
            _setProtocolWithdrawReverts(
                activeAdapter,
                address(child.aaveV3Adapter),
                address(child.aaveV4Adapter),
                address(child.compoundV3Adapter),
                child.aaveV3Adapter.getProtocolPool(),
                child.aaveV4Adapter.getProtocolPool(),
                child.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        } else {
            _setProtocolWithdrawReverts(
                activeAdapter,
                address(remoteChild.aaveV3Adapter),
                address(remoteChild.aaveV4Adapter),
                address(remoteChild.compoundV3Adapter),
                remoteChild.aaveV3Adapter.getProtocolPool(),
                remoteChild.aaveV4Adapter.getProtocolPool(),
                remoteChild.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        }
    }

    function _setProtocolDepositReverts(
        address activeAdapter,
        address aaveV3Adapter,
        address aaveV4Adapter,
        address compoundV3Adapter,
        address aaveV3Pool,
        address aaveV4Spoke,
        address comet,
        bool reverts
    ) internal {
        if (activeAdapter == aaveV3Adapter) {
            MockAaveV3Pool(aaveV3Pool).setSupplyReverts(reverts);
        } else if (activeAdapter == aaveV4Adapter) {
            MockAaveV4Spoke(aaveV4Spoke).setSupplyReverts(reverts);
        } else if (activeAdapter == compoundV3Adapter) {
            MockComet(comet).setSupplyReverts(reverts);
        }
    }

    function _setProtocolWithdrawReverts(
        address activeAdapter,
        address aaveV3Adapter,
        address aaveV4Adapter,
        address compoundV3Adapter,
        address aaveV3Pool,
        address aaveV4Spoke,
        address comet,
        bool reverts
    ) internal {
        if (activeAdapter == aaveV3Adapter) {
            MockAaveV3Pool(aaveV3Pool).setWithdrawReverts(reverts);
        } else if (activeAdapter == aaveV4Adapter) {
            MockAaveV4Spoke(aaveV4Spoke).setWithdrawReverts(reverts);
        } else if (activeAdapter == compoundV3Adapter) {
            MockComet(comet).setWithdrawReverts(reverts);
        }
    }

    function _setParentDepositReverts(Types.Strategy memory strategy, bool reverts) internal {
        address activeAdapter = _adapterFor(strategy);

        _setProtocolDepositReverts(
            activeAdapter,
            address(parent.aaveV3Adapter),
            address(parent.aaveV4Adapter),
            address(parent.compoundV3Adapter),
            parent.aaveV3Adapter.getProtocolPool(),
            parent.aaveV4Adapter.getProtocolPool(),
            parent.compoundV3Adapter.getProtocolPool(),
            reverts
        );
    }

    function _setChildDepositReverts(ChildVault vault, Types.Strategy memory strategy, bool reverts) internal {
        address adapter = _adapterFor(strategy);

        if (address(vault) == address(child.vault)) {
            _setProtocolDepositReverts(
                adapter,
                address(child.aaveV3Adapter),
                address(child.aaveV4Adapter),
                address(child.compoundV3Adapter),
                child.aaveV3Adapter.getProtocolPool(),
                child.aaveV4Adapter.getProtocolPool(),
                child.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        } else {
            _setProtocolDepositReverts(
                adapter,
                address(remoteChild.aaveV3Adapter),
                address(remoteChild.aaveV4Adapter),
                address(remoteChild.compoundV3Adapter),
                remoteChild.aaveV3Adapter.getProtocolPool(),
                remoteChild.aaveV4Adapter.getProtocolPool(),
                remoteChild.compoundV3Adapter.getProtocolPool(),
                reverts
            );
        }
    }

    function _assertPendingEpochDepositRecovery(ChildVault vault, uint256 epochNonce, uint256 amount) internal {
        Types.EpochRecovery memory recovery = vault.getEpochDepositRecovery();

        eq(recovery.epochNonce, epochNonce, "REC-002: wrong epoch deposit recovery nonce");
        eq(recovery.amount, amount, "REC-002: wrong epoch deposit recovery amount");
        t(recovery.createdAt != 0, "REC-002: epoch deposit recovery timestamp not set");
    }

    function _assertEpochDepositRecoveryCleared(ChildVault vault) internal {
        Types.EpochRecovery memory recovery = vault.getEpochDepositRecovery();

        eq(recovery.epochNonce, 0, "REC-003: epoch deposit recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-003: epoch deposit recovery amount not cleared");
        eq(recovery.createdAt, 0, "REC-003: epoch deposit recovery timestamp not cleared");
    }

    function _assertPendingEpochWithdrawRecovery(ChildVault vault, uint256 epochNonce, uint256 amount) internal {
        Types.EpochRecovery memory recovery = vault.getEpochWithdrawRecovery();

        eq(recovery.epochNonce, epochNonce, "REC-002: wrong epoch withdraw recovery nonce");
        eq(recovery.amount, amount, "REC-002: wrong epoch withdraw recovery amount");
        t(recovery.createdAt != 0, "REC-002: epoch withdraw recovery timestamp not set");
    }

    function _assertEpochWithdrawRecoveryCleared(ChildVault vault) internal {
        Types.EpochRecovery memory recovery = vault.getEpochWithdrawRecovery();

        eq(recovery.epochNonce, 0, "REC-003: epoch withdraw recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-003: epoch withdraw recovery amount not cleared");
        eq(recovery.createdAt, 0, "REC-003: epoch withdraw recovery timestamp not cleared");
    }

    function _assertPendingRebalanceDepositRecovery(BaseVault vault, uint256 rebalanceNonce, uint256 amount) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();

        eq(recovery.rebalanceNonce, rebalanceNonce, "REC-005a: wrong rebalance deposit recovery nonce");
        eq(recovery.amount, amount, "REC-005b: wrong rebalance deposit recovery amount");
        t(recovery.createdAt != 0, "REC-002: rebalance deposit recovery timestamp not set");
    }

    function _assertRebalanceDepositRecoveryCleared(BaseVault vault) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();

        eq(recovery.rebalanceNonce, 0, "REC-003: rebalance deposit recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-003: rebalance deposit recovery amount not cleared");
        eq(recovery.createdAt, 0, "REC-003: rebalance deposit recovery timestamp not cleared");
    }

    function _assertPendingRebalanceWithdrawRecovery(
        ChildVault vault,
        uint256 rebalanceNonce,
        Types.Strategy memory strategy
    ) internal {
        Types.RebalanceWithdrawRecovery memory recovery = vault.getRebalanceWithdrawRecovery();

        eq(recovery.rebalanceNonce, rebalanceNonce, "REC-002: wrong rebalance withdraw recovery nonce");
        t(recovery.strategy.protocolId == strategy.protocolId, "REC-002: wrong rebalance withdraw recovery protocol");
        eq(
            uint256(recovery.strategy.chainSelector),
            uint256(strategy.chainSelector),
            "REC-002: wrong rebalance withdraw recovery chain"
        );
        t(recovery.createdAt != 0, "REC-002: rebalance withdraw recovery timestamp not set");
    }

    function _assertRebalanceWithdrawRecoveryCleared(ChildVault vault) internal {
        Types.RebalanceWithdrawRecovery memory recovery = vault.getRebalanceWithdrawRecovery();

        eq(recovery.rebalanceNonce, 0, "REC-003: rebalance withdraw recovery nonce not cleared");
        t(recovery.strategy.protocolId == bytes32(0), "REC-003: rebalance withdraw recovery protocol not cleared");
        eq(uint256(recovery.strategy.chainSelector), 0, "REC-003: rebalance withdraw recovery chain not cleared");
        eq(recovery.createdAt, 0, "REC-003: rebalance withdraw recovery timestamp not cleared");
    }

    function _assertPendingCcipSendRecovery(
        ChildVault vault,
        Types.CcipTx ccipTxType,
        uint64 destinationChainSelector,
        uint256 amount,
        bytes memory txData
    ) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), uint256(ccipTxType), "CCIP-005a: wrong recovery tx type");
        eq(
            uint256(recovery.destinationChainSelector),
            uint256(destinationChainSelector),
            "CCIP-005a: wrong recovery destination"
        );
        eq(recovery.amount, amount, "CCIP-005a: wrong recovery amount");
        t(keccak256(recovery.txData) == keccak256(txData), "CCIP-005a: wrong recovery tx data");
        t(recovery.createdAt != 0, "CCIP-005a: recovery timestamp not set");
    }

    function _assertCcipSendRecoveryCleared(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), 0, "REC-003: recovery tx type not cleared");
        eq(recovery.amount, 0, "REC-003: recovery amount not cleared");
        eq(uint256(recovery.destinationChainSelector), 0, "REC-003: recovery destination not cleared");
        eq(recovery.txData.length, 0, "REC-003: recovery tx data not cleared");
        eq(recovery.createdAt, 0, "REC-003: recovery timestamp not cleared");
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
            t(parent.vault.getActiveProtocolAdapter() == _adapterFor(strategy), "REBAL-006: wrong parent adapter");
        } else if (strategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter is not remote");
            t(child.vault.getActiveProtocolAdapter() == _adapterFor(strategy), "REBAL-006: wrong child adapter");
        } else if (strategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter is not remote");
            t(
                remoteChild.vault.getActiveProtocolAdapter() == _adapterFor(strategy),
                "REBAL-006: wrong remote child adapter"
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
