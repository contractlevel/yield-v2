// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {Properties} from "./Properties.t.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {ParentVault} from "../../../src/vaults/ParentVault.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../../mocks/MockComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {IAdapterRegistry} from "../../../src/interfaces/modules/IAdapterRegistry.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    uint256 internal constant PERFORMANCE_FEE_BPS = 777;
    uint256 internal constant MANAGEMENT_FEE_BPS = 100;
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
        eq(_after.actorCurrentEpochDepositAmount, 0, "EPOCH-006a: cancelDeposit did not clear actor deposit");
        eq(_after.actorUsdcBalance, _before.actorUsdcBalance + amount, "EPOCH-006a: cancelDeposit did not refund USDC");
        eq(
            ghost_depositedByActorByEpoch[actor][epochNonce],
            0,
            "EPOCH-006a: cancelDeposit did not clear actor deposit ghost"
        );
    }

    function handler_forceCancelDeposit(uint256 actorSeed, uint256 amountSeed) public {
        address actor = _actor(actorSeed);
        uint256 epochNonce = parent.vault.getEpochNonce();

        if (parent.vault.getDepositAmount(actor, epochNonce) == 0) {
            handler_deposit(actorSeed, amountSeed);
        }

        s_currentActor = actor;
        uint256 amount = parent.vault.getDepositAmount(actor, epochNonce);

        __before();

        _changePrank(i_cancelDepositOperator);
        parent.vault.forceCancelDeposit(actor);

        __after();

        _recordDepositCancelled(actor, amount);

        eq(_after.epochNonce, epochNonce, "EPOCH-005: forceCancelDeposit changed epoch nonce");
        eq(
            _after.currentEpochTotalDepositAmount,
            _before.currentEpochTotalDepositAmount - amount,
            "EPOCH-005: forceCancelDeposit did not decrease current epoch total"
        );
        eq(_after.actorCurrentEpochDepositAmount, 0, "EPOCH-006a: forceCancelDeposit did not clear actor deposit");
        eq(
            _after.actorUsdcBalance,
            _before.actorUsdcBalance + amount,
            "EPOCH-006a: forceCancelDeposit did not refund USDC"
        );
        eq(
            ghost_depositedByActorByEpoch[actor][epochNonce],
            0,
            "EPOCH-006a: forceCancelDeposit did not clear actor deposit ghost"
        );
    }

    function handler_closeEpoch(uint256 tvlSeed) public {
        if (_recoveryModeExists()) {
            _resolvePendingRecovery();
        }

        uint256 epochNonce = parent.vault.getEpochNonce();

        if (
            parent.vault.getEpoch(epochNonce).totalDepositAmount == 0
                && parent.vault.getEpoch(epochNonce).totalShareBurnAmount == 0
        ) {
            handler_deposit(tvlSeed, MIN_DEPOSIT_AMOUNT);
        }

        uint256 tvl = _activeStrategyTvl();
        uint256 grossPricePerShare = _settlementPricePerShare(tvl);
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc =
            parent.vault.getEpoch(epochNonce).totalShareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        uint256 netWithdrawAmount = totalWithdrawUsdc > totalDepositAmount ? totalWithdrawUsdc - totalDepositAmount : 0;

        if (netWithdrawAmount != 0) {
            _setActiveStrategyWithdrawReturn(netWithdrawAmount);
        }

        FeeSnapshot memory feeSnapshot = _feeSnapshot();

        __before();

        _warpPastEpoch(epochNonce);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );
        _assertEpochTransition(epochNonce, Types.EpochStatus.OPEN, parent.vault.getEpoch(epochNonce).status);
        if (parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING) {
            if (netWithdrawAmount == 0) {
                if (!_recoveryModeExists()) {
                    _completeEpochDepositThroughWorkflow(
                        parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner
                    );
                }
            } else {
                _settleRemoteEpochWithdraw(epochNonce, netWithdrawAmount);
            }
            _assertEpochTransition(epochNonce, Types.EpochStatus.EXECUTING, parent.vault.getEpoch(epochNonce).status);
        }

        __after();

        _recordEpochClosed(epochNonce);
        _recordPerformanceFeeBurden(feeSnapshot, grossPricePerShare, parent.vault.getEpoch(epochNonce).pricePerShare);
        _assertCloseEpochShareAccounting(epochNonce);
        _assertPerformanceFeeMintedToTreasury();
        _assertPerformanceFeeConditions(tvl, grossPricePerShare);
        _assertPerformanceFeeHighWaterMarkNotDecreased();

        eq(_after.epochNonce, epochNonce + 1, "EPOCH-004/NONCE-010: closeEpoch did not increment epoch nonce");
        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE || _recoveryModeExists(),
            "EPOCH-004: closeEpoch did not settle or store recovery"
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
        if (_recoveryModeExists()) {
            _resolvePendingRecovery();
        }

        if (parent.vault.getEpochNonce() == 1 || _activeStrategyTvl() == 0) {
            handler_claimShares(actorSeed, 0, amountSeed);
        }

        Types.Strategy memory target = _rebalanceTarget(pathSeed, protocolSeed);
        FeeSnapshot memory feeSnapshot = _feeSnapshot();
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();

        t(beforeRebalance.state == Types.RebalanceState.NONE, "REBAL-002: rebalance did not start from NONE");
        t(parent.vault.getEpochNonce() > 1, "REBAL-010: rebalance began before an epoch completed");
        t(parent.vault.getSupportedProtocol(target.protocolId), "REBAL-003: target protocol is unsupported");
        t(
            target.chainSelector == PARENT_CHAIN_SELECTOR
                || parent.vault.getCrosschainVault(target.chainSelector) != address(0),
            "REBAL-003: target chain is unsupported"
        );
        t(
            target.protocolId != beforeRebalance.activeStrategy.protocolId
                || target.chainSelector != beforeRebalance.activeStrategy.chainSelector,
            "REBAL-002: target equals active strategy"
        );

        __before();
        _rebalanceTo(target);
        __after();

        _recordManagementFeeBurden(feeSnapshot);
        _assertManagementFeeMintedToTreasury();
        _assertManagementFeeAmount();
        _assertPerformanceFeeHighWaterMarkNotDecreased();

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

    function handler_replaceActiveAdapterRegistryEntry() public {
        if (_recoveryModeExists() || parent.vault.getRebalance().state != Types.RebalanceState.NONE) return;

        Types.Strategy memory strategy = parent.vault.getRebalance().activeStrategy;
        BaseVault vault = _activeVault();
        IAdapterRegistry registry = _activeAdapterRegistry(strategy.chainSelector);
        address storedAdapter = vault.getActiveProtocolAdapter();
        if (storedAdapter == address(0)) return;
        uint256 tvlBefore = vault.getTVL();

        _changePrank(i_configOperator);
        registry.setAdapter(strategy.protocolId, address(0));

        t(vault.getActiveProtocolAdapter() == storedAdapter, "REBAL-007: registry change replaced active adapter");
        eq(vault.getTVL(), tvlBefore, "ADAPTER-003: registry change affected active adapter TVL");

        _changePrank(i_configOperator);
        registry.setAdapter(strategy.protocolId, storedAdapter);

        if (
            strategy.chainSelector == PARENT_CHAIN_SELECTOR && parent.vault.getEpochNonce() > 1
                && !_recoveryModeExists()
        ) {
            _assertLocalAdapterFailureCreatesNoRecovery(strategy, tvlBefore);
        }
    }

    function _assertLocalAdapterFailureCreatesNoRecovery(Types.Strategy memory activeStrategy, uint256 tvlBefore)
        internal
    {
        Types.Strategy memory target = _parentStrategy(_differentProtocol(activeStrategy.protocolId));

        _markParentRebalanceCooldownElapsed();
        Types.Rebalance memory rebalanceBefore = parent.vault.getRebalance();
        _setParentActiveWithdrawReverts(true);
        _changePrank(address(parent.workflowRouter));
        (bool success,) =
            address(parent.vault).call(abi.encodeWithSelector(ParentVault.initiateRebalance.selector, target));
        _setParentActiveWithdrawReverts(false);

        t(!success, "REC-009: synchronous local adapter failure succeeded");
        t(parent.vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-009: local failure created recovery");
        t(
            keccak256(abi.encode(parent.vault.getRebalance())) == keccak256(abi.encode(rebalanceBefore)),
            "REC-009: local failure changed rebalance state"
        );
        eq(parent.vault.getTVL(), tvlBefore, "REC-009: local failure changed TVL");
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
        lte(
            _after.targetEpochRemainingDepositClaimAmount,
            ghost_maxRemainingDepositClaimAmountByEpoch[claimEpochNonce],
            "EPOCH-007: remaining deposit claims increased"
        );
        lte(
            _after.targetEpochRemainingShareMintAmount,
            ghost_maxRemainingShareMintAmountByEpoch[claimEpochNonce],
            "EPOCH-007: remaining share mints increased"
        );
        _updateDepositRemainingCounterMax(claimEpochNonce);

        eq(_after.epochNonce, _before.epochNonce, "claimShares changed current epoch nonce");
        eq(_after.actorTargetEpochDepositAmount, 0, "EPOCH-009: claimShares did not clear actor deposit");
        eq(
            ghost_depositedByActorByEpoch[actor][claimEpochNonce],
            0,
            "EPOCH-009: claimShares did not clear actor deposit ghost"
        );
        eq(
            _after.targetEpochRemainingDepositClaimAmount,
            _before.targetEpochRemainingDepositClaimAmount - depositAmount,
            "EPOCH-009: claimShares did not decrease remaining deposit claims"
        );
        eq(
            _after.targetEpochRemainingShareMintAmount,
            _before.targetEpochRemainingShareMintAmount - shareMintAmount,
            "EPOCH-009: claimShares did not decrease remaining share mints"
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
        eq(
            _after.actorCurrentEpochWithdrawShareBurnAmount,
            0,
            "EPOCH-006b: cancelWithdraw did not clear actor withdraw"
        );
        eq(
            ghost_shareBurnedByActorByEpoch[actor][epochNonce],
            0,
            "EPOCH-006b: cancelWithdraw did not clear actor withdraw ghost"
        );
        eq(
            _after.actorShareBalance,
            _before.actorShareBalance + shareBurnAmount,
            "EPOCH-006b: cancelWithdraw did not refund shares"
        );
    }

    function handler_claimAsset(uint256 actorSeed, uint256 epochSeed, uint256 shareSeed, uint256 amountSeed) public {
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
        uint256 usdcWithdrawAmount = parent.vault.claimAsset(claimEpochNonce);

        __after();

        _recordUsdcClaimed(actor, claimEpochNonce, usdcWithdrawAmount);
        lte(
            _after.targetEpochRemainingShareBurnAmount,
            ghost_maxRemainingShareBurnAmountByEpoch[claimEpochNonce],
            "EPOCH-010: remaining share burns increased"
        );
        lte(
            _after.targetEpochRemainingWithdrawClaimAmount,
            ghost_maxRemainingWithdrawClaimAmountByEpoch[claimEpochNonce],
            "EPOCH-010: remaining withdraw claims increased"
        );
        _updateWithdrawRemainingCounterMax(claimEpochNonce);

        eq(_after.epochNonce, _before.epochNonce, "claimAsset changed current epoch nonce");
        eq(_after.actorTargetEpochWithdrawShareBurnAmount, 0, "EPOCH-012: claimAsset did not clear actor withdraw");
        eq(
            ghost_shareBurnedByActorByEpoch[actor][claimEpochNonce],
            0,
            "EPOCH-012: claimAsset did not clear actor withdraw ghost"
        );
        eq(
            _after.targetEpochRemainingShareBurnAmount,
            _before.targetEpochRemainingShareBurnAmount - shareBurnAmount,
            "EPOCH-012: claimAsset did not decrease remaining share burns"
        );
        eq(
            _after.targetEpochRemainingWithdrawClaimAmount,
            _before.targetEpochRemainingWithdrawClaimAmount - usdcWithdrawAmount,
            "EPOCH-012: claimAsset did not decrease remaining withdraw claims"
        );
        eq(
            _after.actorUsdcBalance,
            _before.actorUsdcBalance + usdcWithdrawAmount,
            "EPOCH-012: claimAsset did not transfer USDC"
        );
    }

    /*//////////////////////////////////////////////////////////////
                             RECOVERY MODES
    //////////////////////////////////////////////////////////////*/
    function handler_executeRecovery(uint256 scenarioSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        public
    {
        if (_recoveryModeExists()) {
            ChildVault pendingChild =
                child.vault.getRecoveryMode() != Types.RecoveryMode.NONE ? child.vault : remoteChild.vault;
            Types.RecoveryMode pendingMode = pendingChild.getRecoveryMode();
            uint256 handledNonce = _pendingChildRecoveryNonce(pendingChild, pendingMode);
            bool rebalanceDomain = pendingMode == Types.RecoveryMode.REBALANCE_DEPOSIT
                || pendingMode == Types.RecoveryMode.REBALANCE_WITHDRAW
                || (pendingMode == Types.RecoveryMode.CCIP_SEND
                    && pendingChild.getCcipSendRecovery().ccipTxType == Types.CcipTx.REBALANCE);
            _resolvePendingRecovery();
            if (pendingMode != Types.RecoveryMode.NONE) {
                _assertHandledChildNonceCannotBeReplayed(pendingChild, rebalanceDomain, handledNonce);
            }
        } else {
            _stageRecovery(scenarioSeed, protocolSeed, actorSeed, amountSeed);
            _assertEpochCloseBlockedByActiveLifecycle();
            _assertPendingRecoveryCannotBeOverwritten();
            _assertFailedRecoveryRetryPreservesState();
        }
    }

    function _assertHandledChildNonceCannotBeReplayed(ChildVault vault, bool rebalanceDomain, uint256 handledNonce)
        internal
    {
        Types.CcipTx ccipTxType = rebalanceDomain ? Types.CcipTx.REBALANCE : Types.CcipTx.EPOCH_NET_DEPOSIT;
        bytes memory payload = rebalanceDomain
            ? abi.encode(handledNonce, parent.vault.getRebalance().activeStrategy.protocolId)
            : abi.encode(handledNonce);
        Client.EVMTokenAmount[] memory amounts = new Client.EVMTokenAmount[](1);
        amounts[0] = Client.EVMTokenAmount({token: parent.vault.getAsset(), amount: 1});
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: PARENT_CHAIN_SELECTOR,
            sender: abi.encode(address(parent.vault)),
            data: abi.encode(ccipTxType, payload),
            destTokenAmounts: amounts
        });
        bytes32 stateHash = _childRecoveryHash(vault);
        _changePrank(address(local.mockCcipRouter));
        (bool success,) =
            address(vault).call(abi.encodeWithSelector(IAny2EVMMessageReceiver.ccipReceive.selector, message));

        t(!success, "CCIP-004/NONCE-004/NONCE-005: handled nonce replay succeeded");
        t(_childRecoveryHash(vault) == stateHash, "CCIP-004: invalid replay changed child lifecycle state");
    }

    function _pendingChildRecoveryNonce(ChildVault vault, Types.RecoveryMode mode)
        internal
        view
        returns (uint256 nonce)
    {
        if (mode == Types.RecoveryMode.EPOCH_DEPOSIT) {
            return vault.getEpochDepositRecovery().epochNonce;
        }
        if (mode == Types.RecoveryMode.EPOCH_WITHDRAW) return vault.getEpochWithdrawRecovery().epochNonce;
        if (mode == Types.RecoveryMode.REBALANCE_DEPOSIT) return vault.getRebalanceDepositRecovery().rebalanceNonce;
        if (mode == Types.RecoveryMode.REBALANCE_WITHDRAW) return vault.getRebalanceWithdrawRecovery().rebalanceNonce;
        if (mode == Types.RecoveryMode.CCIP_SEND) return vault.getCcipSendRecovery().nonce;
    }

    function _assertEpochCloseBlockedByActiveLifecycle() internal {
        uint256 currentNonce = parent.vault.getEpochNonce();
        Types.RebalanceState rebalanceState = parent.vault.getRebalance().state;
        Types.EpochStatus previousStatus =
            currentNonce > 1 ? parent.vault.getEpoch(currentNonce - 1).status : Types.EpochStatus.NONE;
        if (rebalanceState != Types.RebalanceState.REBALANCING && previousStatus != Types.EpochStatus.EXECUTING) {
            return;
        }

        _changePrank(address(parent.workflowRouter));
        (bool success,) = address(parent.vault).call(abi.encodeWithSelector(ParentVault.closeEpoch.selector, 0));

        t(!success, "EPOCH-003: closeEpoch succeeded during an active lifecycle");
        eq(parent.vault.getEpochNonce(), currentNonce, "EPOCH-003: failed closeEpoch changed nonce");
    }

    function _assertPendingRecoveryCannotBeOverwritten() internal {
        if (parent.vault.getRecoveryMode() != Types.RecoveryMode.NONE) {
            bytes32 recoveryHash = keccak256(abi.encode(parent.vault.getRebalanceDepositRecovery()));
            _changePrank(address(parent.workflowRouter));
            (bool success,) = address(parent.vault)
                .call(
                    abi.encodeWithSelector(
                        ParentVault.initiateRebalance.selector, parent.vault.getRebalance().activeStrategy
                    )
                );

            t(!success, "REC-003: operation succeeded while parent recovery was pending");
            t(
                keccak256(abi.encode(parent.vault.getRebalanceDepositRecovery())) == recoveryHash,
                "REC-003: parent recovery was overwritten"
            );
            return;
        }

        ChildVault vault = child.vault.getRecoveryMode() != Types.RecoveryMode.NONE ? child.vault : remoteChild.vault;
        bytes32 recoveryHash = _childRecoveryHash(vault);
        address workflowRouter = address(vault) == address(child.vault)
            ? address(child.workflowRouter)
            : address(remoteChild.workflowRouter);

        _changePrank(workflowRouter);
        (bool success,) = address(vault)
            .call(
                abi.encodeWithSelector(
                    ChildVault.executeEpochWithdraw.selector, vault.getLastHandledEpochNonce() + 1, 1
                )
            );

        t(!success, "REC-003: operation succeeded while child recovery was pending");
        t(_childRecoveryHash(vault) == recoveryHash, "REC-003: child recovery was overwritten");
    }

    function _assertFailedRecoveryRetryPreservesState() internal {
        if (parent.vault.getRecoveryMode() != Types.RecoveryMode.NONE) {
            Types.Strategy memory target = parent.vault.getRebalance().pendingStrategy;
            bytes32 recoveryHash = keccak256(abi.encode(parent.vault.getRebalanceDepositRecovery()));
            uint256 balance = IERC20(parent.vault.getAsset()).balanceOf(address(parent.vault));

            _setParentDepositReverts(target, true);
            (bool success,) = address(parent.vault).call(abi.encodeWithSelector(BaseVault.executeRecovery.selector));
            _setParentDepositReverts(target, false);

            t(!success, "REC-005: failed parent retry succeeded");
            t(
                keccak256(abi.encode(parent.vault.getRebalanceDepositRecovery())) == recoveryHash,
                "REC-005: failed parent retry changed recovery"
            );
            eq(
                IERC20(parent.vault.getAsset()).balanceOf(address(parent.vault)),
                balance,
                "REC-005: failed parent retry changed attributable funds"
            );
            return;
        }

        ChildVault vault = child.vault.getRecoveryMode() != Types.RecoveryMode.NONE ? child.vault : remoteChild.vault;
        Types.RecoveryMode mode = vault.getRecoveryMode();
        bytes32 recoveryHash = _childRecoveryHash(vault);
        uint256 balance = IERC20(parent.vault.getAsset()).balanceOf(address(vault));

        _setChildRetryFailure(vault, mode, true);
        (bool success,) = address(vault).call(abi.encodeWithSelector(BaseVault.executeRecovery.selector));
        _setChildRetryFailure(vault, mode, false);

        t(!success, "REC-005: failed child retry succeeded");
        t(_childRecoveryHash(vault) == recoveryHash, "REC-005: failed child retry changed recovery or nonce");
        eq(
            IERC20(parent.vault.getAsset()).balanceOf(address(vault)),
            balance,
            "REC-005: failed child retry changed attributable funds"
        );
    }

    function _setChildRetryFailure(ChildVault vault, Types.RecoveryMode mode, bool reverts) internal {
        if (mode == Types.RecoveryMode.EPOCH_DEPOSIT) {
            _setActiveChildDepositReverts(vault, reverts);
        } else if (mode == Types.RecoveryMode.EPOCH_WITHDRAW || mode == Types.RecoveryMode.REBALANCE_WITHDRAW) {
            _setActiveChildWithdrawReverts(vault, reverts);
        } else if (mode == Types.RecoveryMode.REBALANCE_DEPOSIT) {
            _setChildDepositReverts(vault, parent.vault.getRebalance().pendingStrategy, reverts);
        } else if (mode == Types.RecoveryMode.CCIP_SEND) {
            Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();
            address destination = _crosschainVault(recovery.destinationChainSelector);
            if (reverts) {
                _breakDestination(vault, recovery.destinationChainSelector);
            } else {
                _restoreDestination(vault, recovery.destinationChainSelector, destination);
            }
        }
    }

    function _stageRecovery(uint256 scenarioSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
        uint256 scenario = scenarioSeed % 8;

        if (scenario < 2) {
            _stageFailedCcipSend(scenario, protocolSeed, actorSeed, amountSeed);
        } else if (scenario == 2) {
            _stageFailedEpochDeposit(0, protocolSeed, actorSeed, amountSeed);
        } else if (scenario == 3) {
            _stageFailedEpochWithdraw(0, protocolSeed, actorSeed, amountSeed);
        } else if (scenario < 6) {
            _stageFailedRebalanceDeposit(scenario - 4, protocolSeed, actorSeed, amountSeed);
        } else {
            _stageFailedRebalanceWithdraw(scenario - 6, protocolSeed, actorSeed, amountSeed);
        }
    }

    function _resolvePendingRecovery() internal {
        eq(_recoveryModeCount(), 1, "REC-010: expected one pending recovery");

        if (_rebalanceDepositRecoveryPending(parent.vault.getRebalanceDepositRecovery())) {
            _recoverFailedRebalanceDeposit(parent.vault);
            return;
        }

        if (_resolveChildPendingRecovery(child.vault)) return;
        if (_resolveChildPendingRecovery(remoteChild.vault)) return;

        t(false, "REC-010: pending recovery not found");
    }

    function _resolveChildPendingRecovery(ChildVault vault) internal returns (bool recovered) {
        if (_rebalanceDepositRecoveryPending(vault.getRebalanceDepositRecovery())) {
            _recoverFailedRebalanceDeposit(vault);
            return true;
        }
        if (_epochRecoveryPending(vault.getEpochDepositRecovery())) {
            _recoverFailedEpochDeposit(vault);
            return true;
        }
        if (_epochRecoveryPending(vault.getEpochWithdrawRecovery())) {
            _recoverFailedEpochWithdraw(vault);
            return true;
        }
        if (_rebalanceWithdrawRecoveryPending(vault.getRebalanceWithdrawRecovery())) {
            _recoverFailedRebalanceWithdraw(vault);
            return true;
        }
        if (_ccipSendRecoveryPending(vault.getCcipSendRecovery())) {
            _recoverFailedCcipSend(vault);
            return true;
        }
    }

    function _stageFailedCcipSend(uint256 childSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
        if (childSeed % 2 == 0) {
            _stageFailedCcipSendEpochWithdraw(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        } else {
            _stageFailedCcipSendRebalance(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        }
    }

    /// @notice When the outbound CCIP send message fails for a Types.CcipTx.EPOCH_NET_WITHDRAW
    function _stageFailedCcipSendEpochWithdraw(
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
        eq(parent.vault.getEpoch(epochNonce).totalDepositAmount, 0, "recovery setup: staged epoch has deposits");
        t(shareBurnAmount != 0, "recovery setup: actor has no shares");

        _withdrawAndAssert(actor, shareBurnAmount, "recovery setup: shares not escrowed");

        uint256 tvl = _activeStrategyTvl();
        uint256 grossPricePerShare = _settlementPricePerShare(tvl);
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 totalWithdrawUsdc = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        uint256 totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        uint256 netWithdrawAmount = totalWithdrawUsdc - totalDepositAmount;

        if (netWithdrawAmount == 0) {
            _bootstrapActorShares(actor);
            _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
            _closeCurrentEpochIfNotEmpty();

            shareBurnAmount = parent.share.balanceOf(actor);
            epochNonce = parent.vault.getEpochNonce();
            eq(parent.vault.getEpoch(epochNonce).totalDepositAmount, 0, "recovery setup: staged epoch has deposits");
            t(shareBurnAmount != 0, "recovery setup: actor has no shares");

            _withdrawAndAssert(actor, shareBurnAmount, "recovery setup: shares not escrowed");

            tvl = _activeStrategyTvl();
            grossPricePerShare = _settlementPricePerShare(tvl);
            settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
            totalWithdrawUsdc = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
            totalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
            netWithdrawAmount = totalWithdrawUsdc - totalDepositAmount;
        }

        t(netWithdrawAmount != 0, "recovery setup: net withdraw is zero");

        _setActiveStrategyWithdrawReturn(netWithdrawAmount);

        FeeSnapshot memory feeSnapshot = _feeSnapshot();

        __before();

        _warpPastEpoch(epochNonce);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );
        _assertEpochTransition(epochNonce, Types.EpochStatus.OPEN, parent.vault.getEpoch(epochNonce).status);

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "EPOCH-014: parent epoch did not enter executing"
        );

        __after();

        _assertCloseEpochShareAccounting(epochNonce);
        _assertPerformanceFeeMintedToTreasury();
        _assertPerformanceFeeHighWaterMarkNotDecreased();

        _breakParentDestination(activeChild);
        _executeEpochWithdraw(activeChild, epochNonce, netWithdrawAmount);
        _restoreParentDestination(activeChild);

        _assertPendingCcipSendRecovery(
            activeChild,
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            PARENT_CHAIN_SELECTOR,
            netWithdrawAmount,
            epochNonce,
            bytes32(0)
        );
        lte(
            netWithdrawAmount,
            IERC20(parent.vault.getAsset()).balanceOf(address(activeChild)),
            "CCIP-006: pending send is not collateralized"
        );

        _recordEpochShareAccounting(epochNonce);
        _recordPerformanceFeeBurden(feeSnapshot, grossPricePerShare, parent.vault.getEpoch(epochNonce).pricePerShare);
    }

    /// @notice When the outbound CCIP send message fails for a Types.CcipTx.REBALANCE
    function _stageFailedCcipSendRebalance(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        /// @dev ccip send rebalance fails are only stored on Child because we atomic revert on Parent
        ChildVault sourceChild = _childVaultBySeed(childSeed);
        _ensureActiveStrategyOnChild(sourceChild, protocolSeed, actorSeed, amountSeed);

        uint64 destinationChainSelector = _rebalanceRecoveryDestination(sourceChild, protocolSeed);
        address destinationVault = _crosschainVault(destinationChainSelector);
        Types.Strategy memory target = _strategy(destinationChainSelector, _protocolId(protocolSeed / 2));
        uint256 amount = _activeStrategyTvl();
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();

        t(amount != 0, "recovery setup: rebalance amount is zero");

        __before();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(
            pendingRebalance.nonce,
            beforeRebalance.nonce,
            "CCIP send rebalance: REBAL-005 nonce changed before completion"
        );
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
            pendingRebalance.nonce,
            target.protocolId
        );
        lte(
            amount,
            IERC20(parent.vault.getAsset()).balanceOf(address(sourceChild)),
            "CCIP-006: pending send is not collateralized"
        );
    }

    function _recoverFailedCcipSend(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        if (recovery.ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW) {
            uint256 epochNonce = recovery.nonce;

            vault.executeRecovery();
            _assertCcipSendRecoveryCleared(vault);

            _assertEpochTransition(epochNonce, Types.EpochStatus.EXECUTING, parent.vault.getEpoch(epochNonce).status);
            t(
                parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE,
                "CCIP-007: parent epoch not claimable after retry"
            );
            _recordEpochClosed(epochNonce);
        } else if (recovery.ccipTxType == Types.CcipTx.REBALANCE) {
            Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
            Types.Strategy memory target = beforeRebalance.pendingStrategy;

            FeeSnapshot memory feeSnapshot = _feeSnapshot();
            __before();

            vault.executeRecovery();
            _assertCcipSendRecoveryCleared(vault);

            if (recovery.destinationChainSelector != PARENT_CHAIN_SELECTOR) {
                _completeRebalanceThroughWorkflow(
                    parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
                );
            }

            __after();

            _assertRebalanceFinalized(beforeRebalance, target, "CCIP-007: parent rebalance not finalized after retry");
            _recordManagementFeeBurden(feeSnapshot);
            _assertManagementFeeMintedToTreasury();
            _assertManagementFeeAmount();
            _assertPerformanceFeeHighWaterMarkNotDecreased();
        } else {
            t(false, "REC-002: invalid CCIP recovery tx type");
        }

        t(vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-004: child still has recovery");
        eq(_recoveryModeCount(), 0, "REC-004: recovery mode not cleared");
        _assertParentCcipReplayRejected(vault, recovery);
    }

    function _assertParentCcipReplayRejected(ChildVault sourceVault, Types.CcipSendRecovery memory recovery) internal {
        bytes memory payload = recovery.ccipTxType == Types.CcipTx.REBALANCE
            ? abi.encode(recovery.nonce, recovery.protocolId)
            : abi.encode(recovery.nonce);
        Client.EVMTokenAmount[] memory amounts = new Client.EVMTokenAmount[](1);
        amounts[0] = Client.EVMTokenAmount({token: parent.vault.getAsset(), amount: recovery.amount});
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: _childChainSelector(sourceVault),
            sender: abi.encode(address(sourceVault)),
            data: abi.encode(recovery.ccipTxType, payload),
            destTokenAmounts: amounts
        });
        bytes32 stateHash = _parentLifecycleHash();

        _changePrank(address(local.mockCcipRouter));
        (bool success,) =
            address(parent.vault).call(abi.encodeWithSelector(IAny2EVMMessageReceiver.ccipReceive.selector, message));

        t(!success, "CCIP-004/NONCE-013: completed parent callback replay succeeded");
        t(_parentLifecycleHash() == stateHash, "CCIP-004: invalid callback changed parent lifecycle state");
    }

    function _parentLifecycleHash() internal view returns (bytes32) {
        uint256 currentNonce = parent.vault.getEpochNonce();
        return keccak256(
            abi.encode(
                currentNonce,
                parent.vault.getEpoch(currentNonce),
                currentNonce > 1 ? parent.vault.getEpoch(currentNonce - 1) : parent.vault.getEpoch(0),
                parent.vault.getRebalance(),
                parent.vault.getRecoveryMode(),
                parent.vault.getRebalanceDepositRecovery(),
                parent.vault.getTotalShares()
            )
        );
    }

    function _stageFailedEpochDeposit(uint256 childSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
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
        t(
            activeChild.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT,
            "REC-002: child epoch deposit recovery mode not set"
        );
        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "EPOCH-002: failed remote deposit epoch not executing"
        );
    }

    function _recoverFailedEpochDeposit(ChildVault vault) internal {
        uint256 epochNonce = vault.getEpochDepositRecovery().epochNonce;
        vault.executeRecovery();

        _completeEpochDepositThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner
        );

        _assertEpochDepositRecoveryCleared(vault);
        t(vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-004: child still has recovery");
        _recordEpochClosed(epochNonce);
        eq(_recoveryModeCount(), 0, "REC-004: recovery mode not cleared");
    }

    function _stageFailedEpochWithdraw(uint256 childSeed, uint256 protocolSeed, uint256 actorSeed, uint256 amountSeed)
        internal
    {
        ChildVault activeChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActorHasShares(actorSeed, amountSeed);
        _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        address actor = _actor(actorSeed);
        uint256 shareBurnAmount = parent.share.balanceOf(actor);
        uint256 epochNonce = parent.vault.getEpochNonce();
        t(shareBurnAmount != 0, "recovery setup: actor has no shares");

        _withdrawAndAssert(actor, shareBurnAmount, "recovery setup: shares not escrowed");

        uint256 tvl = _activeStrategyTvl();
        uint256 grossPricePerShare = _settlementPricePerShare(tvl);
        uint256 settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
        uint256 netWithdrawAmount = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;

        if (netWithdrawAmount == 0) {
            _bootstrapActorShares(actor);
            _ensureActiveStrategyOnChild(activeChild, protocolSeed, actorSeed, amountSeed);
            _closeCurrentEpochIfNotEmpty();

            shareBurnAmount = parent.share.balanceOf(actor);
            epochNonce = parent.vault.getEpochNonce();
            t(shareBurnAmount != 0, "recovery setup: actor has no shares");

            _withdrawAndAssert(actor, shareBurnAmount, "recovery setup: shares not escrowed");

            tvl = _activeStrategyTvl();
            grossPricePerShare = _settlementPricePerShare(tvl);
            settlementPricePerShare = _closeEpochSettlementPricePerShare(tvl);
            netWithdrawAmount = shareBurnAmount * settlementPricePerShare / SHARE_PRECISION;
        }

        t(netWithdrawAmount != 0, "recovery setup: net withdraw is zero");

        FeeSnapshot memory feeSnapshot = _feeSnapshot();

        __before();

        _warpPastEpoch(epochNonce);
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );
        _assertEpochTransition(epochNonce, Types.EpochStatus.OPEN, parent.vault.getEpoch(epochNonce).status);

        t(
            parent.vault.getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING,
            "EPOCH-014: parent epoch did not enter executing"
        );

        __after();

        _assertCloseEpochShareAccounting(epochNonce);
        _assertPerformanceFeeMintedToTreasury();
        _assertPerformanceFeeHighWaterMarkNotDecreased();

        _setActiveChildWithdrawReverts(activeChild, true);
        _executeEpochWithdraw(activeChild, epochNonce, netWithdrawAmount);
        _setActiveChildWithdrawReverts(activeChild, false);

        _recordPerformanceFeeBurden(feeSnapshot, grossPricePerShare, parent.vault.getEpoch(epochNonce).pricePerShare);
        _recordEpochShareAccounting(epochNonce);
        _assertPendingEpochWithdrawRecovery(activeChild, epochNonce, netWithdrawAmount);
        t(
            activeChild.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW,
            "REC-002: child epoch withdraw recovery mode not set"
        );

        _setActiveStrategyWithdrawReturn(netWithdrawAmount);
    }

    function _recoverFailedEpochWithdraw(ChildVault vault) internal {
        Types.EpochRecovery memory recovery = vault.getEpochWithdrawRecovery();
        _setActiveStrategyWithdrawReturn(recovery.amount);

        vault.executeRecovery();

        _assertEpochWithdrawRecoveryCleared(vault);
        _assertEpochTransition(
            recovery.epochNonce, Types.EpochStatus.EXECUTING, parent.vault.getEpoch(recovery.epochNonce).status
        );
        t(
            parent.vault.getEpoch(recovery.epochNonce).status == Types.EpochStatus.CLAIMABLE,
            "EPOCH-014: parent epoch not claimable after recovery"
        );
        t(vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-004: child still has recovery");
        _recordEpochClosed(recovery.epochNonce);
        eq(_recoveryModeCount(), 0, "REC-004: recovery mode not cleared");
    }

    function _stageFailedRebalanceDeposit(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        if (childSeed % 2 == 0) {
            _stageFailedRebalanceDepositParent(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        } else {
            _stageFailedRebalanceDepositChild(childSeed / 2, protocolSeed, actorSeed, amountSeed);
        }
    }

    function _stageFailedRebalanceDepositParent(
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

        t(amount != 0, "REC-002: rebalance deposit recovery amount is zero");

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(
            pendingRebalance.nonce,
            beforeRebalance.nonce,
            "rebalance deposit parent: REBAL-005 nonce changed before completion"
        );
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
        t(
            parent.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
            "REC-002: parent recovery mode not set"
        );
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after deposit failure"
        );
    }

    function _recoverFailedRebalanceDeposit(BaseVault vault) internal {
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        Types.Strategy memory target = beforeRebalance.pendingStrategy;

        FeeSnapshot memory feeSnapshot = _feeSnapshot();
        __before();

        vault.executeRecovery();

        if (address(vault) != address(parent.vault)) {
            _completeRebalanceThroughWorkflow(
                parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
            );
        }

        __after();

        _assertRebalanceDepositRecoveryCleared(vault);
        _assertRebalanceFinalized(beforeRebalance, target, "REBAL-004: state is not none");
        t(vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-004: vault still has recovery");
        _recordManagementFeeBurden(feeSnapshot);
        _assertManagementFeeMintedToTreasury();
        _assertManagementFeeAmount();
        _assertPerformanceFeeHighWaterMarkNotDecreased();
        eq(_recoveryModeCount(), 0, "REC-004: recovery mode not cleared");
    }

    function _stageFailedRebalanceDepositChild(
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

        t(amount != 0, "REC-002: rebalance deposit recovery amount is zero");

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(
            pendingRebalance.nonce,
            beforeRebalance.nonce,
            "rebalance deposit child: REBAL-005 nonce changed before completion"
        );
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
        t(
            destinationChild.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
            "REC-002: child rebalance deposit recovery mode not set"
        );
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after deposit failure"
        );
    }

    /// @notice When a rebalance withdraw from the active Child strategy fails
    function _stageFailedRebalanceWithdraw(
        uint256 childSeed,
        uint256 protocolSeed,
        uint256 actorSeed,
        uint256 amountSeed
    ) internal {
        ChildVault sourceChild = _childVaultBySeed(childSeed);
        _closeCurrentEpochIfNotEmpty();
        _ensureActiveStrategyOnChild(sourceChild, protocolSeed, actorSeed, amountSeed);
        _closeCurrentEpochIfNotEmpty();

        uint64 destinationChainSelector = _rebalanceRecoveryDestination(sourceChild, protocolSeed);
        Types.Strategy memory target = _strategy(destinationChainSelector, _protocolId(protocolSeed / 2));
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        uint256 amount = _activeStrategyTvl();

        t(amount != 0, "recovery setup: rebalance withdraw amount is zero");

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, target
        );

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        eq(
            pendingRebalance.nonce,
            beforeRebalance.nonce,
            "rebalance withdraw: REBAL-005 nonce changed before completion"
        );
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
        t(
            sourceChild.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW,
            "REC-002: child rebalance withdraw recovery mode not set"
        );
        eq(
            uint256(parent.vault.getRebalance().state),
            uint256(Types.RebalanceState.REBALANCING),
            "REBAL-004: state is not rebalancing after withdraw failure"
        );
    }

    function _recoverFailedRebalanceWithdraw(ChildVault vault) internal {
        Types.Rebalance memory beforeRebalance = parent.vault.getRebalance();
        Types.RebalanceWithdrawRecovery memory recovery = vault.getRebalanceWithdrawRecovery();
        Types.Strategy memory target = recovery.strategy;
        uint256 amount = _activeStrategyTvl();
        t(amount != 0, "recovery setup: rebalance withdraw amount is zero");

        FeeSnapshot memory feeSnapshot = _feeSnapshot();
        __before();

        _setActiveStrategyWithdrawReturn(amount);
        vault.executeRecovery();
        _assertRebalanceWithdrawRecoveryCleared(vault);
        t(vault.getRecoveryMode() == Types.RecoveryMode.NONE, "REC-004: child still has recovery");

        if (target.chainSelector != PARENT_CHAIN_SELECTOR) {
            _completeRebalanceThroughWorkflow(
                parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
            );
        }

        __after();

        _assertRebalanceFinalized(beforeRebalance, target, "REBAL-004: state is not none");
        _recordManagementFeeBurden(feeSnapshot);
        _assertManagementFeeMintedToTreasury();
        _assertManagementFeeAmount();
        _assertPerformanceFeeHighWaterMarkNotDecreased();
        eq(_recoveryModeCount(), 0, "REC-004: recovery mode not cleared");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER / UTILITY
    //////////////////////////////////////////////////////////////*/
    function _assertRebalanceFinalized(
        Types.Rebalance memory beforeRebalance,
        Types.Strategy memory target,
        string memory stateMessage
    ) internal {
        Types.Rebalance memory afterRebalance = parent.vault.getRebalance();

        eq(afterRebalance.nonce, beforeRebalance.nonce + 1, "REBAL-005: nonce did not increment");
        eq(uint256(afterRebalance.state), uint256(Types.RebalanceState.NONE), stateMessage);
        t(afterRebalance.activeStrategy.protocolId == target.protocolId, "REBAL-006: wrong active protocol");
        eq(
            uint256(afterRebalance.activeStrategy.chainSelector),
            uint256(target.chainSelector),
            "REBAL-006: wrong active chain"
        );
        t(afterRebalance.pendingStrategy.protocolId == bytes32(0), "REBAL-004: pending protocol still set");
        eq(uint256(afterRebalance.pendingStrategy.chainSelector), 0, "REBAL-004: pending chain still set");
        _assertActiveAdapterFor(target);
    }

    function _assertEpochTransition(uint256 epochNonce, Types.EpochStatus beforeStatus, Types.EpochStatus afterStatus)
        internal
    {
        bool allowed = beforeStatus == afterStatus
            || (beforeStatus == Types.EpochStatus.OPEN && afterStatus == Types.EpochStatus.EXECUTING)
            || (beforeStatus == Types.EpochStatus.OPEN && afterStatus == Types.EpochStatus.CLAIMABLE)
            || (beforeStatus == Types.EpochStatus.EXECUTING && afterStatus == Types.EpochStatus.CLAIMABLE);

        t(allowed, "EPOCH-002: invalid epoch transition");

        if (epochNonce == 0) {
            t(afterStatus == Types.EpochStatus.NONE, "EPOCH-002: epoch zero status changed");
        }
    }

    function _assertCloseEpochShareAccounting(uint256 epochNonce) internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
        uint256 feeShares = _after.treasuryShareBalance - _before.treasuryShareBalance;
        uint256 expectedTotalShares =
            _before.totalShares + feeShares + epoch.remainingShareMintAmount - epoch.totalShareBurnAmount;

        eq(_after.totalShares, expectedTotalShares, "SHARE-002: closeEpoch total share accounting mismatch");
    }

    function _assertPerformanceFeeMintedToTreasury() internal {
        Types.Epoch memory epoch = parent.vault.getEpoch(_before.epochNonce);
        uint256 treasuryShareIncrease = _after.treasuryShareBalance - _before.treasuryShareBalance;
        uint256 derivedFeeShares =
            _after.totalShares + epoch.totalShareBurnAmount - _before.totalShares - epoch.remainingShareMintAmount;

        eq(derivedFeeShares, treasuryShareIncrease, "FEE-002: performance fee did not mint to treasury");
    }

    function _assertPerformanceFeeConditions(uint256 tvl, uint256 grossPricePerShare) internal {
        uint256 actualFeeShares = _after.treasuryShareBalance - _before.treasuryShareBalance;
        if (grossPricePerShare <= _before.performanceFeeHighWaterMark || _before.totalShares == 0) {
            eq(actualFeeShares, 0, "FEE-001: fee minted without yield above high-water mark");
            return;
        }

        uint256 totalYield = FixedPointMathLib.fullMulDivUp(
            grossPricePerShare - _before.performanceFeeHighWaterMark, _before.totalShares, SHARE_PRECISION
        );
        uint256 feeAmount = FixedPointMathLib.fullMulDivUp(totalYield, PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);
        if (feeAmount >= tvl) {
            eq(actualFeeShares, 0, "FEE-001: fee minted when fee consumes TVL");
            return;
        }

        uint256 expectedFeeShares = FixedPointMathLib.fullMulDivUp(feeAmount, _before.totalShares, tvl - feeAmount);
        eq(actualFeeShares, expectedFeeShares, "FEE-001: incorrect performance fee shares");
    }

    function _assertManagementFeeMintedToTreasury() internal {
        uint256 treasuryShareIncrease = _after.treasuryShareBalance - _before.treasuryShareBalance;

        eq(
            _after.totalShares,
            _before.totalShares + treasuryShareIncrease,
            "FEE-002: management fee did not mint to treasury"
        );
    }

    function _assertManagementFeeAmount() internal {
        uint256 elapsed = block.timestamp > 365 days ? 365 days : block.timestamp;
        uint256 expectedFeeShares = FixedPointMathLib.fullMulDivUp(
            _before.totalShares, MANAGEMENT_FEE_BPS * elapsed, BPS_DENOMINATOR * 365 days
        );
        eq(
            _after.treasuryShareBalance - _before.treasuryShareBalance,
            expectedFeeShares,
            "FEE-004: incorrect capped management fee"
        );
    }

    function _assertPerformanceFeeHighWaterMarkNotDecreased() internal {
        lte(
            _before.performanceFeeHighWaterMark,
            _after.performanceFeeHighWaterMark,
            "FEE-003: performance fee high-water mark decreased"
        );
    }

    function _settlementPricePerShare(uint256 tvl) internal view returns (uint256 pricePerShare) {
        uint256 totalShares = parent.vault.getTotalShares();
        if (totalShares != 0 && tvl != 0) return tvl * SHARE_PRECISION / totalShares;
        return ASSET_PRECISION;
    }

    function _closeEpochSettlementPricePerShare(uint256 tvl) internal view returns (uint256 settlementPricePerShare) {
        uint256 grossPricePerShare = _settlementPricePerShare(tvl);
        uint256 highWaterMark = parent.vault.getPerformanceFeeHighWaterMark();
        if (grossPricePerShare <= highWaterMark) return grossPricePerShare;

        uint256 totalShares = parent.vault.getTotalShares();
        uint256 totalYield =
            FixedPointMathLib.fullMulDivUp(grossPricePerShare - highWaterMark, totalShares, SHARE_PRECISION);
        uint256 feeUsdc = FixedPointMathLib.fullMulDivUp(totalYield, PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);
        if (feeUsdc >= tvl) return grossPricePerShare;

        uint256 feeShares = FixedPointMathLib.fullMulDivUp(feeUsdc, totalShares, tvl - feeUsdc);
        return tvl * SHARE_PRECISION / (totalShares + feeShares);
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
        eq(
            _activeStrategyTvl(),
            tvlBefore,
            "ADAPTER-007/ADAPTER-008/ADAPTER-009: TVL changed during successful rebalance"
        );
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
            FeeSnapshot memory feeSnapshot = _feeSnapshot();

            __before();
            _rebalanceTo(target);
            __after();

            _recordManagementFeeBurden(feeSnapshot);
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
        _updateDepositRemainingCounterMax(depositEpochNonce);

        t(parent.share.balanceOf(actor) != 0, "recovery setup: actor has no shares");
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

    function _setParentActiveWithdrawReverts(bool reverts) internal {
        _setProtocolWithdrawReverts(
            parent.vault.getActiveProtocolAdapter(),
            address(parent.aaveV3Adapter),
            address(parent.aaveV4Adapter),
            address(parent.compoundV3Adapter),
            parent.aaveV3Adapter.getProtocolPool(),
            parent.aaveV4Adapter.getProtocolPool(),
            parent.compoundV3Adapter.getProtocolPool(),
            reverts
        );
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

        eq(recovery.epochNonce, epochNonce, "REC-001: wrong epoch deposit recovery nonce");
        eq(recovery.amount, amount, "REC-001: wrong epoch deposit recovery amount");
    }

    function _assertEpochDepositRecoveryCleared(ChildVault vault) internal {
        Types.EpochRecovery memory recovery = vault.getEpochDepositRecovery();

        eq(recovery.epochNonce, 0, "REC-004: epoch deposit recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-004: epoch deposit recovery amount not cleared");
    }

    function _assertPendingEpochWithdrawRecovery(ChildVault vault, uint256 epochNonce, uint256 amount) internal {
        Types.EpochRecovery memory recovery = vault.getEpochWithdrawRecovery();

        eq(recovery.epochNonce, epochNonce, "REC-001: wrong epoch withdraw recovery nonce");
        eq(recovery.amount, amount, "REC-001: wrong epoch withdraw recovery amount");
    }

    function _assertEpochWithdrawRecoveryCleared(ChildVault vault) internal {
        Types.EpochRecovery memory recovery = vault.getEpochWithdrawRecovery();

        eq(recovery.epochNonce, 0, "REC-004: epoch withdraw recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-004: epoch withdraw recovery amount not cleared");
    }

    function _assertPendingRebalanceDepositRecovery(BaseVault vault, uint256 rebalanceNonce, uint256 amount) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();

        eq(recovery.rebalanceNonce, rebalanceNonce, "REC-001: wrong rebalance deposit recovery nonce");
        eq(recovery.amount, amount, "REC-001: wrong rebalance deposit recovery amount");
    }

    function _assertRebalanceDepositRecoveryCleared(BaseVault vault) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();

        eq(recovery.rebalanceNonce, 0, "REC-004: rebalance deposit recovery nonce not cleared");
        eq(recovery.amount, 0, "REC-004: rebalance deposit recovery amount not cleared");
    }

    function _assertPendingRebalanceWithdrawRecovery(
        ChildVault vault,
        uint256 rebalanceNonce,
        Types.Strategy memory strategy
    ) internal {
        Types.RebalanceWithdrawRecovery memory recovery = vault.getRebalanceWithdrawRecovery();

        eq(recovery.rebalanceNonce, rebalanceNonce, "REC-001: wrong rebalance withdraw recovery nonce");
        t(recovery.strategy.protocolId == strategy.protocolId, "REC-001: wrong rebalance withdraw recovery protocol");
        eq(
            uint256(recovery.strategy.chainSelector),
            uint256(strategy.chainSelector),
            "REC-001: wrong rebalance withdraw recovery chain"
        );
    }

    function _assertRebalanceWithdrawRecoveryCleared(ChildVault vault) internal {
        Types.RebalanceWithdrawRecovery memory recovery = vault.getRebalanceWithdrawRecovery();

        eq(recovery.rebalanceNonce, 0, "REC-004: rebalance withdraw recovery nonce not cleared");
        t(recovery.strategy.protocolId == bytes32(0), "REC-004: rebalance withdraw recovery protocol not cleared");
        eq(uint256(recovery.strategy.chainSelector), 0, "REC-004: rebalance withdraw recovery chain not cleared");
    }

    function _assertPendingCcipSendRecovery(
        ChildVault vault,
        Types.CcipTx ccipTxType,
        uint64 destinationChainSelector,
        uint256 amount,
        uint256 nonce,
        bytes32 protocolId
    ) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), uint256(ccipTxType), "CCIP-005: wrong recovery tx type");
        eq(
            uint256(recovery.destinationChainSelector),
            uint256(destinationChainSelector),
            "CCIP-005: wrong recovery destination"
        );
        eq(recovery.amount, amount, "CCIP-005: wrong recovery amount");
        eq(recovery.nonce, nonce, "CCIP-005: wrong recovery nonce");
        t(recovery.protocolId == protocolId, "CCIP-005: wrong recovery protocol id");
    }

    function _assertCcipSendRecoveryCleared(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();

        eq(uint256(recovery.ccipTxType), 0, "REC-004: recovery tx type not cleared");
        eq(recovery.amount, 0, "REC-004: recovery amount not cleared");
        eq(uint256(recovery.destinationChainSelector), 0, "REC-004: recovery destination not cleared");
        eq(recovery.nonce, 0, "REC-004: recovery nonce not cleared");
        t(recovery.protocolId == bytes32(0), "REC-004: recovery protocol id not cleared");
    }

    function _childRecoveryHash(ChildVault vault) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                vault.getRecoveryMode(),
                vault.getRebalanceDepositRecovery(),
                vault.getRebalanceWithdrawRecovery(),
                vault.getEpochDepositRecovery(),
                vault.getEpochWithdrawRecovery(),
                vault.getCcipSendRecovery(),
                vault.getLastHandledEpochNonce(),
                vault.getLastHandledRebalanceNonce()
            )
        );
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

    function _activeAdapterRegistry(uint64 chainSelector) internal view returns (IAdapterRegistry registry) {
        if (chainSelector == PARENT_CHAIN_SELECTOR) return IAdapterRegistry(address(parent.adapterRegistry));
        if (chainSelector == CHILD_CHAIN_SELECTOR) return IAdapterRegistry(address(child.adapterRegistry));
        return IAdapterRegistry(address(remoteChild.adapterRegistry));
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
