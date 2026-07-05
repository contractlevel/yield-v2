// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseRecoveryIntegrationTest} from "../../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV4Spoke} from "../../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";

contract ParentDeposit_RebalanceRecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    function test_Recovery_parentRebalanceDeposit_FinalizesAfterFailedChildToParentDeposit() external {
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedChildLocalTvl(tvl);
        address parentSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 parentReserveId = parent.aaveV4Adapter.getReserveId();
        uint256 parentSuppliedBefore =
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter));

        MockAaveV4Spoke(parentSpoke).setSupplyReverts(true);

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_REBALANCE_WORKFLOW_ID,
            INITIATE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(
            child.workflowRouter,
            EXECUTE_REBALANCE_WORKFLOW_ID,
            EXECUTE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            1,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("RebalanceDepositRecoveryStored(uint256,uint256)"), address(parent.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(uint256(storedLog.topics[2]), tvl);
        _assertRebalanceDepositRecovery(parent.vault.getRebalanceDepositRecovery(), 1, tvl);
        assertTrue(parent.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter)),
            parentSuppliedBefore
        );

        MockAaveV4Spoke(parentSpoke).setSupplyReverts(false);
        vm.recordLogs();
        parent.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(parent.vault));
        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(parent.vault));
        Vm.Log memory completedLog = _assertEmittedBy(
            recoveryLogs, keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(parent.vault)
        );
        assertEq(uint256(completedLog.topics[1]), 1);
        assertEq(bytes32(completedLog.topics[2]), AAVE_V4_PROTOCOL_ID);
        assertEq(uint64(uint256(completedLog.topics[3])), PARENT_CHAIN_SELECTOR);
        _assertRebalanceDepositRecoveryCleared(parent.vault.getRebalanceDepositRecovery());
        assertTrue(parent.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter)),
            parentSuppliedBefore + tvl
        );
        _assertCompletedRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
    }
}
