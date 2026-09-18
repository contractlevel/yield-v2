// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_RecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant SEED_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-seed");
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-close");
    bytes32 private constant WITHDRAW_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteEpochWithdrawWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryChildEpochWithdraw_FinalizesParentAfterFailedArbitrumWithdraw() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);
        uint256 withdrawAmount = shareAmount * ASSET_PRECISION / YIELD_PRECISION;

        _selectBaseFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, withdrawAmount);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToFailingAdapter();
        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, withdrawAmount);
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("EpochWithdrawRecoveryStored(uint256,uint256)"), address(arbitrumChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 2);
        assertEq(uint256(storedLog.topics[2]), withdrawAmount);
        _assertEpochRecovery(arbitrumChild.vault.getEpochWithdrawRecovery(), 2, withdrawAmount);
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW);

        _restoreArbitrumAaveV3Adapter();
        _prepareArbitrumToParentRouting();
        vm.warp(block.timestamp + 12 hours); // Avoid Aave rounding while keeping forked CCIP prices fresh.
        arbitrumChild.vault.executeRecovery();

        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);

        _selectArbitrumFork();
        _assertEpochRecoveryCleared(arbitrumChild.vault.getEpochWithdrawRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertApproxEqAbs(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + withdrawAmount, 1);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
    }
}
