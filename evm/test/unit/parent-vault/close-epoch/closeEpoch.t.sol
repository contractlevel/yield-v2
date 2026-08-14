// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {MockCCIPRouter} from "../../../mocks/MockCCIPRouter.sol";

contract ParentVault_CloseEpochUnitTest is BaseUnitTest {
    uint256 internal constant WITHDRAW_SHARES = YIELD_PRECISION;
    uint256 internal constant TVL = 1_000 * 1e6;
    uint256 internal constant SEEDED_SHARES = 1_000_000 * YIELD_PRECISION;
    uint256 internal constant SEEDED_TVL = 1_000_000 * ASSET_PRECISION;

    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        deal(address(s_mockUsdc), address(s_parentVault), DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
        _changePrank(i_epochOperator);
    }

    function test_ParentVault_closeEpoch_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert();
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_Paused() public {
        _changePrank(i_pauser);
        s_parentVault.pause();

        _changePrank(i_epochOperator);
        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_InvalidEpochNonce() public {
        uint256 invalidEpochNonce = s_parentVault.getEpochNonce() + 1;

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__InvalidEpochNonce.selector, invalidEpochNonce));
        s_parentVault.closeEpoch(invalidEpochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_RebalanceInProgress() public {
        _setParentRebalanceState(Types.RebalanceState.REBALANCING);

        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IParentVault.ParentVault__RebalanceInProgress.selector);
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_RecoveryExists() public {
        _setParentRecoveryMode(Types.RecoveryMode.REBALANCE_DEPOSIT);

        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);

        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EpochTooShort() public {
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochTooShort.selector, 1));
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EmptyEpoch() public {
        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EmptyEpoch.selector, 1));
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_ZeroTvlWithOutstandingShares() public {
        _setParentTotalShares(SEEDED_SHARES);
        _submitDeposit();

        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IParentVault.ParentVault__ZeroTvlWithOutstandingShares.selector);
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_ScaledTvlToShareRatioRoundsToZero() public {
        _setParentTotalShares(SHARE_PRECISION + 1);
        _submitDeposit();

        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IParentVault.ParentVault__ZeroPricePerShare.selector);
        s_parentVault.closeEpoch(epochNonce, 1);
    }

    function test_ParentVault_closeEpoch_RevertWhen_ShareBurnExistsWithZeroTotalShares() public {
        _setParentEpochTotalShareBurnAmount(1, 1);

        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IParentVault.ParentVault__ShareBurnWithZeroTotalShares.selector);
        s_parentVault.closeEpoch(epochNonce, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_DepositWouldMintZeroShares() public {
        uint256 totalShares = 1;
        uint256 tvl = DEPOSIT_AMOUNT + 1;
        _setParentTotalShares(totalShares);
        _submitDeposit();

        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(IParentVault.ParentVault__DepositWouldMintZeroShares.selector);
        s_parentVault.closeEpoch(epochNonce, tvl);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.OPEN));

        _changePrank(i_depositor);
        s_parentVault.cancelDeposit();
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.OPEN));
    }

    function test_ParentVault_closeEpoch_RevertWhen_LocalNetDepositAdapterReverts() public {
        _submitDeposit();
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(i_epochOperator);
        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_parentVault.closeEpoch(epochNonce, TVL);
    }

    function test_ParentVault_closeEpoch_RevertWhen_LocalNetWithdrawAdapterReverts() public {
        _prepareNetWithdraw();
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_epochOperator);
        _warpPastMinEpoch();
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, TVL));
        s_parentVault.closeEpoch(epochNonce, TVL);
    }

    function test_ParentVault_closeEpoch_Success_MakesEpochClaimable() public {
        _submitDeposit();
        _closeEpoch(TVL);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_closeEpoch_Success_OpensNextEpoch() public {
        _submitDeposit();
        _closeEpoch(TVL);

        _assertNextEpochOpen();
    }

    function test_ParentVault_closeEpoch_Success_EmitsEpochOpen() public {
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochOpen(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 2);
    }

    function test_ParentVault_closeEpoch_LocalNetDeposit_DepositsNetFlowIntoAdapter() public {
        _submitDeposit();
        _closeEpoch(TVL);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_closeEpoch_LocalNetWithdraw_WithdrawsNetFlowFromAdapter() public {
        _prepareNetWithdraw();

        _closeEpoch(TVL);

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), TVL);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_BridgesNetFlowToStrategyChain() public {
        _prepareRemoteStrategy();
        _submitDeposit();
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        _closeEpoch(TVL);

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + DEPOSIT_AMOUNT);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_MarksEpochExecuting() public {
        _prepareRemoteStrategy();
        _submitDeposit();

        _closeEpoch(TVL);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.EXECUTING));
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_RevertWhen_CcipSendReverts() public {
        _prepareRemoteStrategy();
        _submitDeposit();
        s_mockCcipRouter.setCcipSendReverts(true);

        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(MockCCIPRouter.MockCCIPRouter__CcipSendReverts.selector);
        s_parentVault.closeEpoch(epochNonce, TVL);
    }

    function test_ParentVault_closeEpoch_RemoteNetWithdraw_MarksEpochExecuting() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();

        _closeEpoch(TVL);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.EXECUTING));
    }

    function test_ParentVault_closeEpoch_RemoteNetWithdraw_EmitsEpochWithdrawExecuting() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochWithdrawExecuting(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), TVL);
    }

    function test_ParentVault_closeEpoch_RevertWhen_PreviousEpochNotClaimable() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();
        _closeEpoch(TVL);

        _submitDeposit();

        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 1));
        s_parentVault.closeEpoch(epochNonce, TVL);
    }

    function test_ParentVault_closeEpoch_WhenPreviousEpochClaimable_ClosesCurrentEpoch() public {
        _submitDeposit();
        _closeEpoch(TVL);

        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _submitDeposit();

        _closeEpoch(TVL);

        assertEq(uint8(s_parentVault.getEpoch(2).status), uint8(Types.EpochStatus.CLAIMABLE));
        assertEq(s_parentVault.getEpochNonce(), 3);
    }

    function test_ParentVault_closeEpoch_Success_StoresTotalWithdrawClaimAmountOnEpoch() public {
        _prepareNetWithdraw();
        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, TVL);
    }

    function test_ParentVault_closeEpoch_Success_InitializesRemainingClaimAmounts() public {
        _setParentTotalShares(TVL * SHARE_PRECISION / ASSET_PRECISION);
        _submitDeposit();
        _submitParentWithdraw(WITHDRAW_SHARES);
        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, DEPOSIT_AMOUNT);
        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, expectedShares);
        assertEq(s_parentVault.getEpoch(1).remainingShareBurnAmount, WITHDRAW_SHARES);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, ASSET_PRECISION);
    }

    function test_ParentVault_closeEpoch_LocalNetWithdraw_WhenAdapterReturnsDifferentAmount_UpdatesWithdrawClaimAmount()
        public
    {
        uint256 amountOut = TVL - 1;
        _prepareNetWithdraw();
        s_mockProtocolAdapter.setWithdrawReturnAmount(amountOut);

        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, amountOut);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, amountOut);
    }

    function test_ParentVault_closeEpoch_RemoteNetWithdraw_StoresTotalWithdrawClaimAmount() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();

        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, TVL);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, TVL);
    }

    function test_ParentVault_closeEpoch_Success_WhenNetFlowIsZero_ClosesWithoutExternalAction() public {
        // _prepareNetWithdraw() sizes the withdraw so that, with exact SHARE_PRECISION division and
        // Closing at tvl == DEPOSIT_AMOUNT prices the withdraw at exactly
        // DEPOSIT_AMOUNT too - matching _submitDeposit()'s fixed amount, so netFlow == 0 exactly.
        _submitDeposit();
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(DEPOSIT_AMOUNT);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.CLAIMABLE));
        assertEq(s_mockProtocolAdapter.getDepositCalls(), 0);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 0);
        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, DEPOSIT_AMOUNT);

        bytes32 ccipBridgedSig = keccak256("CCIPBridged(bytes32,uint64,uint8)");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i; i < logs.length; ++i) {
            assertFalse(logs[i].topics[0] == ccipBridgedSig && logs[i].emitter == address(s_parentVault));
        }
    }

    function test_ParentVault_closeEpoch_Success_UpdatesTotalShares() public {
        _submitDeposit();
        _closeEpoch(TVL);

        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(s_parentVault.getTotalShares(), expectedShares);
    }

    function test_ParentVault_closeEpoch_HighYieldUsesUndilutedPriceAndMintsNoTreasuryShares() public {
        uint256 grossPricePerShare = 105 * ASSET_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedDepositShares = DEPOSIT_AMOUNT * SEEDED_SHARES / tvl;

        _setParentTotalShares(SEEDED_SHARES);
        _submitDeposit();
        _closeEpoch(tvl);

        assertEq(s_yieldcoin.balanceOf(i_treasury), 0);
        assertEq(s_parentVault.getTotalShares(), SEEDED_SHARES + expectedDepositShares);
    }

    function test_ParentVault_closeEpoch_HighYieldWithdrawsSettleAtUndilutedPrice() public {
        uint256 grossPricePerShare = 105 * ASSET_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedWithdrawUsdc = WITHDRAW_SHARES * grossPricePerShare / SHARE_PRECISION;

        _setParentTotalShares(SEEDED_SHARES);
        _submitParentWithdraw(WITHDRAW_SHARES);
        _closeEpoch(tvl);

        assertEq(s_yieldcoin.balanceOf(i_treasury), 0);
        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, expectedWithdrawUsdc);
    }

    function test_ParentVault_closeEpoch_Success_UsesDirectFullPrecisionSettlementForBothSides() public {
        uint256 totalShares = 3 * SHARE_PRECISION;
        uint256 tvl = 10 * ASSET_PRECISION;
        uint256 expectedNewShares = DEPOSIT_AMOUNT * totalShares / tvl;
        uint256 oldPricePerShare = tvl * SHARE_PRECISION / totalShares;
        uint256 oldTotalWithdraw = totalShares * oldPricePerShare / SHARE_PRECISION;

        assertEq(oldTotalWithdraw, tvl - 1);

        _prepareRemoteStrategy();
        _setParentTotalShares(totalShares);
        _submitDeposit();
        _submitParentWithdraw(totalShares);
        _closeEpoch(tvl);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, tvl);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, tvl);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, expectedNewShares);
        assertEq(s_parentVault.getTotalShares(), expectedNewShares);
    }

    function test_ParentVault_closeEpoch_LocalNetDeposit_EmitsEpochClaimable() public {
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_closeEpoch_LocalNetDeposit_EmitsEpochDepositToStrategySuccess() public {
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositToStrategySuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_closeEpoch_LocalNetWithdraw_EmitsEpochClaimable() public {
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_closeEpoch_LocalNetWithdraw_EmitsEpochWithdrawFromStrategySuccess() public {
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochWithdrawFromStrategySuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), TVL);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_EmitsEpochDepositExecuting() public {
        _prepareRemoteStrategy();
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositExecuting(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_EmitsCCIPBridged() public {
        _prepareRemoteStrategy();
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPBridged(bytes32,uint64,uint8)"), address(s_parentVault));
        assertEq(uint256(log.topics[2]), CHILD_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[3]), uint256(Types.CcipTx.EPOCH_NET_DEPOSIT));
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _closeEpoch(uint256 tvl) internal {
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), tvl);
    }

    function _warpPastMinEpoch() internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
    }

    function _submitDeposit() internal {
        _changePrank(i_depositor);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
    }

    function _prepareNetWithdraw() internal {
        _setParentTotalShares(WITHDRAW_SHARES);
        _submitParentWithdraw(WITHDRAW_SHARES);
    }

    function _prepareRemoteStrategy() internal {
        _clearParentActiveAdapter();
        _setParentActiveStrategy(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
    }

    function _assertNextEpochOpen() internal view {
        assertEq(s_parentVault.getEpochNonce(), 2);
        assertEq(uint256(s_parentVault.getEpoch(2).status), uint256(Types.EpochStatus.OPEN));
        assertEq(s_parentVault.getEpoch(2).openedAtTimestamp, block.timestamp);
    }
}
