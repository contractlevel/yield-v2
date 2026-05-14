// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";

contract ParentToParent_RebalanceIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("parent-to-parent-rebalance");
    bytes10 private constant WORKFLOW_NAME = bytes10("rebalance");

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureInitiateRebalanceWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
    }

    function test_Rebalance_parentToParent_FinalizesSynchronouslyIntoParentTargetStrategy() external {
        uint256 tvl = _seedParentLocalTvl(DEPOSIT_AMOUNT);
        address oldPool = parent.aaveV3Adapter.getProtocolPool();
        address targetSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 targetReserveId = parent.aaveV4Adapter.getReserveId();

        MockAaveV3Pool(oldPool).setATokenAddress(parent.usdc);
        deal(parent.usdc, address(parent.aaveV3Adapter), tvl);
        deal(parent.usdc, oldPool, tvl);
        MockAaveV3Pool(oldPool).setWithdrawReturn(tvl);

        uint256 targetTvlBefore =
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(parent.aaveV4Adapter));

        vm.recordLogs();
        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();

        Vm.Log memory withdrawLog =
            _assertEmittedBy(logs, keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(parent.vault));
        assertEq(uint256(withdrawLog.topics[1]), 1);
        assertEq(uint256(withdrawLog.topics[2]), tvl);

        Vm.Log memory depositLog =
            _assertEmittedBy(logs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(parent.vault));
        assertEq(uint256(depositLog.topics[1]), 1);
        assertEq(uint256(depositLog.topics[2]), tvl);

        Vm.Log memory completedLog =
            _assertEmittedBy(logs, keccak256("RebalanceCompleted(uint256)"), address(parent.vault));
        assertEq(uint256(completedLog.topics[1]), 1);

        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, 2);
        assertEq(rebalance.activeStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(rebalance.activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(rebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(rebalance.pendingStrategy.chainSelector, 0);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV4Adapter));
        assertEq(
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(parent.aaveV4Adapter)),
            targetTvlBefore + tvl
        );
    }
}
