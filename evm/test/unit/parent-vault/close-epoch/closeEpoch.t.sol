// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CloseEpochUnitTest is BaseUnitTest {
    uint256 internal constant WITHDRAW_SHARES = MIN_DEPOSIT_AMOUNT;
    uint256 internal constant TVL = 1_000 * 1e6;
    uint256 internal constant SEEDED_SHARES = 1_000_000 * 1e6;
    uint256 internal constant PERFORMANCE_FEE_BPS = 777;
    uint256 internal constant BPS_DENOMINATOR = 10_000;

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
        vm.expectRevert();
        s_parentVault.closeEpoch(1, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_RebalanceInProgress() public {
        _setParentRebalanceState(Types.RebalanceState.REBALANCING);

        _warpPastMinEpoch();
        vm.expectRevert(IParentVault.ParentVault__RebalanceInProgress.selector);
        s_parentVault.closeEpoch(1, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);

        _warpPastMinEpoch();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.closeEpoch(1, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EpochTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochTooShort.selector, 1));
        s_parentVault.closeEpoch(1, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_EmptyEpoch() public {
        _warpPastMinEpoch();
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EmptyEpoch.selector, 1));
        s_parentVault.closeEpoch(1, 0);
    }

    function test_ParentVault_closeEpoch_RevertWhen_LocalNetDepositAdapterReverts() public {
        _submitDeposit();
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(i_epochOperator);
        _warpPastMinEpoch();
        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_parentVault.closeEpoch(1, TVL);
    }

    function test_ParentVault_closeEpoch_RevertWhen_LocalNetWithdrawAdapterReverts() public {
        _prepareNetWithdraw();
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_epochOperator);
        _warpPastMinEpoch();
        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, TVL));
        s_parentVault.closeEpoch(1, TVL);
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

    function test_ParentVault_closeEpoch_RemoteNetWithdraw_MarksEpochExecuting() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();

        _closeEpoch(TVL);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.EXECUTING));
    }

    function test_ParentVault_closeEpoch_RemoteNetWithdraw_EmitsEpochExecuting() public {
        _prepareRemoteStrategy();
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochExecuting(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), TVL);
    }

    function test_ParentVault_closeEpoch_Success_StoresPricePerShareOnEpoch() public {
        _submitDeposit();
        _closeEpoch(TVL);

        // totalShares == 0 before close → bootstrap pricePerShare == SHARE_PRECISION
        assertEq(s_parentVault.getEpoch(1).pricePerShare, SHARE_PRECISION);
    }

    function test_ParentVault_closeEpoch_Success_StoresTotalWithdrawClaimAmountOnEpoch() public {
        _prepareNetWithdraw();
        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, TVL);
    }

    function test_ParentVault_closeEpoch_LocalNetWithdraw_WhenAdapterReturnsDifferentAmount_UpdatesWithdrawClaimAmount()
        public
    {
        uint256 amountOut = TVL - 1;
        _prepareNetWithdraw();
        s_mockProtocolAdapter.setWithdrawReturnAmount(amountOut);

        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, amountOut);
    }

    function test_ParentVault_closeEpoch_Success_StoresClosedAtTimestampOnEpoch() public {
        _submitDeposit();
        _closeEpoch(TVL);

        assertEq(s_parentVault.getEpoch(1).closedAtTimestamp, block.timestamp);
    }

    function test_ParentVault_closeEpoch_Success_UpdatesTotalShares() public {
        _submitDeposit();
        _closeEpoch(TVL);

        // pricePerShare == SHARE_PRECISION → newShares == DEPOSIT_AMOUNT
        assertEq(s_parentVault.getTotalShares(), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_NoFeeWhenPricePerShareEqualsHighWaterMark() public {
        _setParentTotalShares(SEEDED_SHARES);
        _submitDeposit();
        _closeEpoch(SEEDED_SHARES);

        uint256 newShares = DEPOSIT_AMOUNT;
        assertEq(s_yieldcoin.balanceOf(i_treasury), 0);
        assertEq(s_parentVault.getTotalShares(), SEEDED_SHARES + newShares);
        assertEq(s_parentVault.getPerformanceFeeHighWaterMark(), SHARE_PRECISION);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_MintsTreasurySharesWhenPricePerShareExceedsHighWaterMark()
        public
    {
        uint256 grossPricePerShare = 105 * SHARE_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedFeeShares =
            _expectedPerformanceFeeShares(SEEDED_SHARES, tvl, grossPricePerShare, SHARE_PRECISION);
        uint256 settlementPricePerShare = _pricePerShare(tvl, SEEDED_SHARES + expectedFeeShares);
        uint256 expectedDepositShares = DEPOSIT_AMOUNT * SHARE_PRECISION / settlementPricePerShare;

        _setParentTotalShares(SEEDED_SHARES);
        _submitDeposit();
        _closeEpoch(tvl);

        assertEq(s_yieldcoin.balanceOf(i_treasury), expectedFeeShares);
        assertEq(s_parentVault.getTotalShares(), SEEDED_SHARES + expectedFeeShares + expectedDepositShares);
        assertEq(s_parentVault.getEpoch(1).pricePerShare, settlementPricePerShare);
        assertEq(s_parentVault.getPerformanceFeeHighWaterMark(), settlementPricePerShare);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_EmitsPerformanceFeeCollected() public {
        uint256 grossPricePerShare = 105 * SHARE_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedFeeShares =
            _expectedPerformanceFeeShares(SEEDED_SHARES, tvl, grossPricePerShare, SHARE_PRECISION);

        _setParentTotalShares(SEEDED_SHARES);
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(tvl);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("PerformanceFeeCollected(uint256,uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), expectedFeeShares);
        assertEq(uint256(log.topics[3]), SHARE_PRECISION);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_DoesNotUpdateHighWaterMarkBelowPriorHigh() public {
        uint256 highWaterMark = 105 * SHARE_PRECISION / 100;
        uint256 grossPricePerShare = 103 * SHARE_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedDepositShares = DEPOSIT_AMOUNT * SHARE_PRECISION / grossPricePerShare;

        _setParentTotalShares(SEEDED_SHARES);
        _setParentPerformanceFeeHighWaterMark(highWaterMark);
        _submitDeposit();
        _closeEpoch(tvl);

        assertEq(s_yieldcoin.balanceOf(i_treasury), 0);
        assertEq(s_parentVault.getTotalShares(), SEEDED_SHARES + expectedDepositShares);
        assertEq(s_parentVault.getPerformanceFeeHighWaterMark(), highWaterMark);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_ChargesOnlyYieldAboveHighWaterMarkAfterDrawdown() public {
        uint256 highWaterMark = 105 * SHARE_PRECISION / 100;
        uint256 grossPricePerShare = 106 * SHARE_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedFeeShares = _expectedPerformanceFeeShares(SEEDED_SHARES, tvl, grossPricePerShare, highWaterMark);
        uint256 settlementPricePerShare = _pricePerShare(tvl, SEEDED_SHARES + expectedFeeShares);
        uint256 expectedDepositShares = DEPOSIT_AMOUNT * SHARE_PRECISION / settlementPricePerShare;

        _setParentTotalShares(SEEDED_SHARES);
        _setParentPerformanceFeeHighWaterMark(highWaterMark);
        _submitDeposit();
        _closeEpoch(tvl);

        assertEq(s_yieldcoin.balanceOf(i_treasury), expectedFeeShares);
        assertEq(s_parentVault.getTotalShares(), SEEDED_SHARES + expectedFeeShares + expectedDepositShares);
        assertEq(s_parentVault.getEpoch(1).pricePerShare, settlementPricePerShare);
        assertEq(s_parentVault.getPerformanceFeeHighWaterMark(), settlementPricePerShare);
    }

    function test_ParentVault_closeEpoch_PerformanceFee_WithdrawsSettleAtPostFeePrice() public {
        uint256 grossPricePerShare = 105 * SHARE_PRECISION / 100;
        uint256 tvl = SEEDED_SHARES * grossPricePerShare / SHARE_PRECISION;
        uint256 expectedFeeShares =
            _expectedPerformanceFeeShares(SEEDED_SHARES, tvl, grossPricePerShare, SHARE_PRECISION);
        uint256 settlementPricePerShare = _pricePerShare(tvl, SEEDED_SHARES + expectedFeeShares);
        uint256 expectedWithdrawUsdc = WITHDRAW_SHARES * settlementPricePerShare / SHARE_PRECISION;

        _setParentTotalShares(SEEDED_SHARES);
        _submitParentWithdraw(WITHDRAW_SHARES);
        _closeEpoch(tvl);

        assertEq(s_parentVault.getEpoch(1).totalWithdrawClaimAmount, expectedWithdrawUsdc);
        assertEq(s_parentVault.getEpoch(1).pricePerShare, settlementPricePerShare);
    }

    function test_ParentVault_closeEpoch_LocalNetDeposit_EmitsEpochClaimable() public {
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_closeEpoch_LocalNetDeposit_EmitsDepositToStrategySuccess() public {
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositToStrategySuccess(uint256,uint256)"), address(s_parentVault));
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

    function test_ParentVault_closeEpoch_LocalNetWithdraw_EmitsWithdrawFromStrategySuccess() public {
        _prepareNetWithdraw();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawFromStrategySuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), TVL);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_EmitsEpochClaimable() public {
        _prepareRemoteStrategy();
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_closeEpoch_RemoteNetDeposit_EmitsCCIPBridged() public {
        _prepareRemoteStrategy();
        _submitDeposit();

        vm.recordLogs();
        _closeEpoch(TVL);

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPBridged(bytes32,uint256,uint8)"), address(s_parentVault));
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
        assertEq(uint256(log.topics[3]), uint256(Types.CcipTx.DEPOSIT));
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _closeEpoch(uint256 tvl) internal {
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(1, tvl);
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
        _setParentPerformanceFeeHighWaterMark(TVL * SHARE_PRECISION / WITHDRAW_SHARES);
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

    function _expectedPerformanceFeeShares(
        uint256 totalShares,
        uint256 tvl,
        uint256 grossPricePerShare,
        uint256 highWaterMark
    ) internal pure returns (uint256 feeShares) {
        uint256 totalYield = _ceilDiv((grossPricePerShare - highWaterMark) * totalShares, SHARE_PRECISION);
        uint256 feeUsdc = _ceilDiv(totalYield * PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);
        feeShares = _ceilDiv(feeUsdc * totalShares, tvl - feeUsdc);
    }

    function _pricePerShare(uint256 tvl, uint256 totalShares) internal pure returns (uint256 pricePerShare) {
        pricePerShare = tvl * SHARE_PRECISION / totalShares;
    }

    function _ceilDiv(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        result = numerator == 0 ? 0 : (numerator - 1) / denominator + 1;
    }
}
