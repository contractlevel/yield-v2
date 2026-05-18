// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipRecoveryForkTest} from "../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_RecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant SEED_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-seed");
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-close");
    bytes32 private constant WITHDRAW_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-execute");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteEpochWithdrawWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryChildEpochWithdraw_FinalizesParentAfterFailedBaseWithdraw() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);

        _selectArbitrumFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 2, shareAmount);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _selectBaseFork();
        _setBaseChildActiveAdapterToFailingAdapter();
        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, shareAmount);
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("EpochWithdrawRecoveryStored(uint256,uint256)"), address(baseChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 2);
        assertEq(uint256(storedLog.topics[2]), shareAmount);
        _assertAmountRecovery(baseChild.vault.getEpochWithdrawRecovery(2), shareAmount);

        _restoreBaseAaveV3Adapter();
        _prepareBaseToParentRouting();
        vm.warp(block.timestamp + 5 minutes);
        baseChild.vault.recoverFailedEpochWithdraw(2);

        _selectBaseFork();
        _routeUsdcMessageTo(arbitrumFork);

        _selectBaseFork();
        _assertAmountRecoveryCleared(baseChild.vault.getEpochWithdrawRecovery(2));

        _selectArbitrumFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        (uint256 expectedClaimAmount,) = parent.vault.getNetAmountAndOperationFee(shareAmount);
        uint256 depositorUsdcBefore = IERC20(parent.usdc).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimUsdc(2);

        assertApproxEqAbs(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBefore + expectedClaimAmount, 1);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
    }
}
