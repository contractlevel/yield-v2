// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ParentToChild_RebalanceIntegrationTest is BaseIntegrationTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("parent-to-child-initiate-rebalance");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("parent-to-child-complete-rebalance");
    bytes10 private constant INITIATE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 private constant COMPLETE_WORKFLOW_NAME = bytes10("completeRb");

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, INITIATE_WORKFLOW_ID, INITIATE_WORKFLOW_NAME, i_owner
        );
        _configureCompleteRebalanceWorkflow(
            parent.workflowRouter, COMPLETE_WORKFLOW_ID, COMPLETE_WORKFLOW_NAME, i_owner
        );
        _setDefaultCcipGasLimits();
    }

    function test_Rebalance_parentToChild_CompletesAfterLocalCcipSendToChild() external {
        uint256 tvl = _seedParentLocalTvl(DEPOSIT_AMOUNT);
        address oldPool = parent.aaveV3Adapter.getProtocolPool();
        address childPool = child.aaveV3Adapter.getProtocolPool();
        uint256 childPoolBalanceBefore = IERC20(parent.usdc).balanceOf(childPool);

        MockAaveV3Pool(oldPool).setATokenAddress(parent.usdc);
        deal(parent.usdc, address(parent.aaveV3Adapter), tvl);
        deal(parent.usdc, oldPool, tvl);
        MockAaveV3Pool(oldPool).setWithdrawReturn(tvl);

        vm.recordLogs();
        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_WORKFLOW_ID,
            INITIATE_WORKFLOW_NAME,
            i_owner,
            _childStrategy(AAVE_V3_PROTOCOL_ID)
        );
        Vm.Log[] memory initiateLogs = vm.getRecordedLogs();

        Vm.Log memory withdrawLog = _assertEmittedBy(
            initiateLogs, keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(parent.vault)
        );
        assertEq(uint256(withdrawLog.topics[1]), 1);
        assertEq(uint256(withdrawLog.topics[2]), tvl);

        Vm.Log memory depositLog =
            _assertEmittedBy(initiateLogs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(child.vault));
        assertEq(uint256(depositLog.topics[1]), 1);
        assertEq(uint256(depositLog.topics[2]), tvl);

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(pendingRebalance.nonce, 1);
        assertEq(pendingRebalance.pendingStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(pendingRebalance.pendingStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(0));
        assertEq(IERC20(parent.usdc).balanceOf(childPool), childPoolBalanceBefore + tvl);
        assertEq(child.vault.getActiveProtocolAdapter(), address(child.aaveV3Adapter));

        vm.recordLogs();
        _completeRebalanceThroughWorkflow(
            parent.workflowRouter, COMPLETE_WORKFLOW_ID, COMPLETE_WORKFLOW_NAME, i_owner, 1
        );
        Vm.Log[] memory completeLogs = vm.getRecordedLogs();

        Vm.Log memory completedLog =
            _assertEmittedBy(completeLogs, keccak256("RebalanceCompleted(uint256)"), address(parent.vault));
        assertEq(uint256(completedLog.topics[1]), 1);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
        assertEq(completedRebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(completedRebalance.pendingStrategy.chainSelector, 0);
    }
}
