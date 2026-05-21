// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseRecoveryIntegrationTest} from "../../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_RecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    function test_Recovery_childEpochWithdraw_FinalizesParentAfterFailedRemoteEpochWithdraw() external {
        uint256 shareAmount = _depositAndClaimParentLocalShares();
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);

        address childPool = child.aaveV3Adapter.getProtocolPool();

        _approveShares(i_depositor, address(parent.vault), shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, shareAmount
        );
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(
            child.workflowRouter,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
            i_owner,
            2,
            shareAmount
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("EpochWithdrawRecoveryStored(uint256,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 2);
        assertEq(uint256(storedLog.topics[2]), shareAmount);
        _assertEpochRecovery(child.vault.getEpochWithdrawRecovery(), 2, shareAmount);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        deal(parent.usdc, childPool, shareAmount);
        MockAaveV3Pool(childPool).setWithdrawReturn(shareAmount);

        vm.recordLogs();
        child.vault.recoverFailedEpochWithdraw();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("EpochWithdrawRecoveryCleared(uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("WithdrawFromStrategySuccess(uint256,uint256)"), address(child.vault));
        _assertEpochRecoveryCleared(child.vault.getEpochWithdrawRecovery());
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBeforeClaim = IERC20(parent.usdc).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimUsdc(2);

        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBeforeClaim + shareAmount);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
    }
}
