// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CompleteEpochDepositUnitTest is BaseUnitTest {
    uint256 internal constant TVL = 1_000 * ASSET_PRECISION;

    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_CallerDoesNotHaveEpochOperatorRole() public {
        _prepareExecutingNetDeposit();

        _changePrank(i_nonOwner);
        uint256 epochNonce = s_parentVault.getEpochNonce() - 1;
        vm.expectRevert();
        s_parentVault.completeEpochDeposit(epochNonce, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_NoEpochHasCompleted() public {
        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce() - 1;
        vm.expectRevert(IParentVault.ParentVault__NoCompletedEpoch.selector);
        s_parentVault.completeEpochDeposit(epochNonce, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_InvalidEpochNonce() public {
        _prepareExecutingNetDeposit();
        uint256 invalidEpochNonce = s_parentVault.getEpochNonce();

        _changePrank(i_epochOperator);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__InvalidEpochNonce.selector, invalidEpochNonce));
        s_parentVault.completeEpochDeposit(invalidEpochNonce, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_PreviousEpochIsNotNetDeposit() public {
        _prepareExecutingNetWithdraw();

        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce() - 1;
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotNetDeposit.selector, 1));
        s_parentVault.completeEpochDeposit(epochNonce, 1);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_PreviousEpochIsNotExecuting() public {
        _prepareExecutingNetDeposit();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(s_parentVault.getEpochNonce() - 1, DEPOSIT_AMOUNT);

        uint256 epochNonce = s_parentVault.getEpochNonce() - 1;
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotExecuting.selector, 1));
        s_parentVault.completeEpochDeposit(epochNonce, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_completeEpochDeposit_Success_MarksPreviousEpochClaimable() public {
        _prepareExecutingNetDeposit();

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(s_parentVault.getEpochNonce() - 1, DEPOSIT_AMOUNT);

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_completeEpochDeposit_Success_EmitsEpochClaimable() public {
        _prepareExecutingNetDeposit();

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(s_parentVault.getEpochNonce() - 1, DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_ActualDepositAmountIsZero() public {
        _prepareExecutingNetDeposit();

        _changePrank(i_epochOperator);
        vm.expectRevert(
            abi.encodeWithSelector(IParentVault.ParentVault__InvalidActualDepositAmount.selector, 0, DEPOSIT_AMOUNT)
        );
        s_parentVault.completeEpochDeposit(1, 0);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_ActualDepositAmountExceedsExpected() public {
        _prepareExecutingNetDeposit();
        uint256 actualDepositAmount = DEPOSIT_AMOUNT + 1;

        _changePrank(i_epochOperator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IParentVault.ParentVault__InvalidActualDepositAmount.selector, actualDepositAmount, DEPOSIT_AMOUNT
            )
        );
        s_parentVault.completeEpochDeposit(1, actualDepositAmount);
    }

    function test_ParentVault_completeEpochDeposit_ExactDeliveryDoesNotReduceShares() public {
        _prepareExecutingNetDeposit();
        Types.Epoch memory epochBefore = s_parentVault.getEpoch(1);
        uint256 totalSharesBefore = s_parentVault.getTotalShares();

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(1, DEPOSIT_AMOUNT);

        Types.Epoch memory epochAfter = s_parentVault.getEpoch(1);
        Vm.Log memory reconciliationLog =
            _assertEmittedBy(keccak256("EpochDepositReconciled(uint256,uint256,uint256)"), address(s_parentVault));
        assertEq(epochAfter.remainingShareMintAmount, epochBefore.remainingShareMintAmount);
        assertEq(epochAfter.remainingDepositClaimAmount, epochBefore.remainingDepositClaimAmount);
        assertEq(epochAfter.totalDepositAmount, epochBefore.totalDepositAmount);
        assertEq(s_parentVault.getTotalShares(), totalSharesBefore);
        assertEq(uint256(reconciliationLog.topics[2]), DEPOSIT_AMOUNT);
        assertEq(uint256(reconciliationLog.topics[3]), 0);
    }

    function test_ParentVault_completeEpochDeposit_ShortDeliveryReducesEpochAndTotalShares() public {
        _prepareExecutingNetDeposit();
        uint256 actualDepositAmount = DEPOSIT_AMOUNT * 99 / 100;
        uint256 expectedAdjustedShares = YIELD_PRECISION * actualDepositAmount / DEPOSIT_AMOUNT;

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(1, actualDepositAmount);

        Types.Epoch memory epoch = s_parentVault.getEpoch(1);
        assertEq(epoch.remainingShareMintAmount, expectedAdjustedShares);
        assertEq(epoch.remainingDepositClaimAmount, DEPOSIT_AMOUNT);
        assertEq(epoch.totalDepositAmount, DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getTotalShares(), expectedAdjustedShares);
    }

    function test_ParentVault_completeEpochDeposit_MixedEpochUsesWithdrawClaimsPlusActualDeposit() public {
        uint256 totalSharesBefore = YIELD_PRECISION;
        uint256 withdrawClaimAmount = DEPOSIT_AMOUNT / 2;
        uint256 withdrawShares = withdrawClaimAmount * totalSharesBefore / TVL;
        _prepareExecutingMixedNetDeposit(totalSharesBefore, withdrawShares);
        Types.Epoch memory epochBefore = s_parentVault.getEpoch(1);
        uint256 expectedDepositAmount = DEPOSIT_AMOUNT - withdrawClaimAmount;
        uint256 actualDepositAmount = expectedDepositAmount / 2;
        uint256 effectiveDepositAmount = withdrawClaimAmount + actualDepositAmount;
        uint256 expectedAdjustedShares = epochBefore.remainingShareMintAmount * effectiveDepositAmount / DEPOSIT_AMOUNT;
        uint256 expectedShareReduction = epochBefore.remainingShareMintAmount - expectedAdjustedShares;
        uint256 authoritativeSharesBefore = s_parentVault.getTotalShares();

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(1, actualDepositAmount);

        Types.Epoch memory epochAfter = s_parentVault.getEpoch(1);
        assertEq(epochAfter.remainingShareMintAmount, expectedAdjustedShares);
        assertEq(epochAfter.remainingDepositClaimAmount, DEPOSIT_AMOUNT);
        assertEq(epochAfter.totalWithdrawClaimAmount, withdrawClaimAmount);
        assertEq(s_parentVault.getTotalShares(), authoritativeSharesBefore - expectedShareReduction);
    }

    function test_ParentVault_completeEpochDeposit_EmitsEpochDepositReconciledBeforeEpochClaimable() public {
        _prepareExecutingNetDeposit();
        uint256 actualDepositAmount = DEPOSIT_AMOUNT * 99 / 100;
        uint256 expectedShareReduction = YIELD_PRECISION - YIELD_PRECISION * actualDepositAmount / DEPOSIT_AMOUNT;

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(1, actualDepositAmount);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        Vm.Log memory reconciliationLog = logs[0];
        assertEq(reconciliationLog.emitter, address(s_parentVault));
        assertEq(reconciliationLog.topics[0], keccak256("EpochDepositReconciled(uint256,uint256,uint256)"));
        assertEq(uint256(reconciliationLog.topics[1]), 1);
        assertEq(uint256(reconciliationLog.topics[2]), actualDepositAmount);
        assertEq(uint256(reconciliationLog.topics[3]), expectedShareReduction);
        assertEq(logs[1].topics[0], keccak256("EpochClaimable(uint256)"));
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_AdjustedSharesRoundToZero() public {
        _prepareExecutingNetDepositWithAccounting(1, DEPOSIT_AMOUNT);

        _changePrank(i_epochOperator);
        vm.expectRevert(IParentVault.ParentVault__DepositWouldMintZeroShares.selector);
        s_parentVault.completeEpochDeposit(1, DEPOSIT_AMOUNT - 1);
    }

    function testFuzz_ParentVault_completeEpochDeposit_ReconcilesValidShortDelivery(uint256 actualDepositAmount)
        public
    {
        actualDepositAmount = bound(actualDepositAmount, 1, DEPOSIT_AMOUNT);
        _prepareExecutingNetDeposit();
        uint256 expectedAdjustedShares = YIELD_PRECISION * actualDepositAmount / DEPOSIT_AMOUNT;

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit(1, actualDepositAmount);

        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, expectedAdjustedShares);
        assertEq(s_parentVault.getTotalShares(), expectedAdjustedShares);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_Paused() public {
        _prepareExecutingNetDeposit();
        _changePrank(i_pauser);
        s_parentVault.pause();

        _changePrank(i_epochOperator);
        uint256 epochNonce = s_parentVault.getEpochNonce() - 1;
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.completeEpochDeposit(epochNonce, DEPOSIT_AMOUNT);
    }

    function _prepareExecutingNetDeposit() internal {
        _prepareExecutingNetDepositWithAccounting(0, TVL);
    }

    function _prepareExecutingNetDepositWithAccounting(uint256 totalShares, uint256 tvl) internal {
        _prepareRemoteStrategy();
        _setParentTotalShares(totalShares);
        _changePrank(i_depositor);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), tvl);
    }

    function _prepareExecutingMixedNetDeposit(uint256 totalShares, uint256 withdrawShares) internal {
        _prepareRemoteStrategy();
        _setParentTotalShares(totalShares);
        _changePrank(i_depositor);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        _submitParentWithdraw(withdrawShares);
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), TVL);
    }

    function _prepareExecutingNetWithdraw() internal {
        _prepareRemoteStrategy();
        _setParentTotalShares(YIELD_PRECISION);
        _submitParentWithdraw(YIELD_PRECISION);
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), TVL);
    }

    function _prepareRemoteStrategy() internal {
        _clearParentActiveAdapter();
        _setParentActiveStrategy(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
    }

    function _warpPastMinEpoch() internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
    }
}
