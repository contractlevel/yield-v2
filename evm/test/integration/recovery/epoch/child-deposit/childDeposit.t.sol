// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseRecoveryIntegrationTest} from "../../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildDeposit_RecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    function test_Recovery_childEpochDeposit_DepositsAfterFailedRemoteEpochDeposit() external {
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);

        address childPool = child.aaveV3Adapter.getProtocolPool();
        uint256 childPoolBalanceBefore = IERC20(parent.asset).balanceOf(childPool);

        MockAaveV3Pool(childPool).setSupplyReverts(true);
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        vm.recordLogs();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 0
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("EpochDepositRecoveryStored(uint256,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(uint256(storedLog.topics[2]), DEPOSIT_AMOUNT);
        _assertEpochRecovery(child.vault.getEpochDepositRecovery(), 1, DEPOSIT_AMOUNT);
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
        assertEq(IERC20(parent.asset).balanceOf(childPool), childPoolBalanceBefore);

        MockAaveV3Pool(childPool).setSupplyReverts(false);
        vm.recordLogs();
        child.vault.recoverFailedEpochDeposit();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("EpochDepositRecoveryCleared(uint256)"), address(child.vault));
        Vm.Log memory successLog = _assertEmittedBy(
            recoveryLogs, keccak256("DepositToStrategySuccess(uint256,uint256)"), address(child.vault)
        );
        assertEq(uint256(successLog.topics[1]), 1);
        assertEq(uint256(successLog.topics[2]), DEPOSIT_AMOUNT);
        _assertEpochRecoveryCleared(child.vault.getEpochDepositRecovery());
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(IERC20(parent.asset).balanceOf(childPool), childPoolBalanceBefore + DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        assertEq(parent.share.balanceOf(i_depositor), DEPOSIT_AMOUNT);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
