// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseRecoveryIntegrationTest} from "../../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";

contract ChildWithdraw_RebalanceRecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    function test_Recovery_childRebalanceWithdraw_FinalizesParentAfterFailedChildWithdraw() external {
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedChildLocalTvl(tvl);
        address childPool = child.aaveV3Adapter.getProtocolPool();
        address parentSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 parentReserveId = parent.aaveV4Adapter.getReserveId();
        uint256 parentSuppliedBefore =
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter));

        _prepareAaveV3RebalanceWithdraw(childPool, address(child.aaveV3Adapter), tvl);
        MockAaveV3Pool(childPool).setWithdrawReverts(true);

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
            failureLogs, keccak256("RebalanceWithdrawRecoveryStored(uint256,bytes32,uint64)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(bytes32(storedLog.topics[2]), AAVE_V4_PROTOCOL_ID);
        assertEq(uint64(uint256(storedLog.topics[3])), PARENT_CHAIN_SELECTOR);
        _assertRebalanceWithdrawRecovery(
            child.vault.getRebalanceWithdrawRecovery(), 1, AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR
        );
        assertTrue(child.vault.getRecoveryExists());
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        MockAaveV3Pool(childPool).setWithdrawReverts(false);
        deal(parent.usdc, childPool, tvl);
        MockAaveV3Pool(childPool).setWithdrawReturn(tvl);

        vm.recordLogs();
        child.vault.recoverFailedRebalanceWithdraw();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceWithdrawRecoveryCleared(uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(child.vault));
        _assertRebalanceWithdrawRecoveryCleared(child.vault.getRebalanceWithdrawRecovery());
        assertFalse(child.vault.getRecoveryExists());
        assertEq(child.vault.getActiveProtocolAdapter(), address(0));
        assertEq(
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter)),
            parentSuppliedBefore + tvl
        );
        _assertCompletedRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
    }
}
