// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseRecoveryIntegrationTest} from "../../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildDeposit_RebalanceRecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    function test_Recovery_childRebalanceDeposit_CompletesAfterFailedParentToChildDeposit() external {
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedParentLocalTvl(tvl);
        address childPool = child.aaveV3Adapter.getProtocolPool();
        uint256 childPoolBalanceBefore = IERC20(parent.usdc).balanceOf(childPool);

        MockAaveV3Pool(childPool).setSupplyReverts(true);

        vm.recordLogs();
        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_REBALANCE_WORKFLOW_ID,
            INITIATE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            _childStrategy(AAVE_V3_PROTOCOL_ID)
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("RebalanceDepositRecoveryStored(uint256,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(uint256(storedLog.topics[2]), tvl);
        _assertRebalanceDepositRecovery(child.vault.getRebalanceDepositRecovery(), 1, tvl);
        assertTrue(child.vault.getRecoveryExists());
        assertEq(IERC20(parent.usdc).balanceOf(childPool), childPoolBalanceBefore);
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        MockAaveV3Pool(childPool).setSupplyReverts(false);
        vm.recordLogs();
        child.vault.recoverFailedRebalanceDeposit();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(child.vault));
        _assertRebalanceDepositRecoveryCleared(child.vault.getRebalanceDepositRecovery());
        assertFalse(child.vault.getRecoveryExists());
        assertEq(IERC20(parent.usdc).balanceOf(childPool), childPoolBalanceBefore + tvl);

        _completeRebalanceThroughWorkflow(
            parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner, 1
        );
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
    }
}
