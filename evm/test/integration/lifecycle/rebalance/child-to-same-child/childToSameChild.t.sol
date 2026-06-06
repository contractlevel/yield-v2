// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV4Spoke} from "../../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildToSameChild_RebalanceIntegrationTest is BaseIntegrationTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("child-to-same-child-initiate-rebalance");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("child-to-same-child-execute-rebalance");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("child-to-same-child-complete-rebalance");
    bytes10 private constant INITIATE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 private constant EXECUTE_WORKFLOW_NAME = bytes10("execRb");
    bytes10 private constant COMPLETE_WORKFLOW_NAME = bytes10("completeRb");

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, INITIATE_WORKFLOW_ID, INITIATE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteRebalanceWorkflow(child.workflowRouter, EXECUTE_WORKFLOW_ID, EXECUTE_WORKFLOW_NAME, i_owner);
        _configureCompleteRebalanceWorkflow(
            parent.workflowRouter, COMPLETE_WORKFLOW_ID, COMPLETE_WORKFLOW_NAME, i_owner
        );

        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();
    }

    function test_Rebalance_childToSameChild_CompletesAfterLocalChildStrategyMove() external {
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedChildLocalTvl(tvl);
        address targetSpoke = child.aaveV4Adapter.getProtocolPool();
        uint256 targetReserveId = child.aaveV4Adapter.getReserveId();

        uint256 routerBalanceBeforeRebalance = IERC20(parent.usdc).balanceOf(address(local.mockCcipRouter));
        uint256 targetTvlBefore =
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(child.aaveV4Adapter));

        vm.recordLogs();
        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_WORKFLOW_ID,
            INITIATE_WORKFLOW_NAME,
            i_owner,
            _childStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory initiateLogs = vm.getRecordedLogs();

        Vm.Log memory initiatedLog = _assertEmittedBy(
            initiateLogs, keccak256("RebalanceInitiated(uint256,uint64,bytes32)"), address(parent.vault)
        );
        assertEq(uint256(initiatedLog.topics[1]), 1);
        assertEq(uint64(uint256(initiatedLog.topics[2])), CHILD_CHAIN_SELECTOR);
        assertEq(bytes32(initiatedLog.topics[3]), AAVE_V4_PROTOCOL_ID);

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(pendingRebalance.nonce, 1);
        assertEq(pendingRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(pendingRebalance.activeStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
        assertEq(pendingRebalance.pendingStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(pendingRebalance.pendingStrategy.chainSelector, CHILD_CHAIN_SELECTOR);

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(
            child.workflowRouter,
            EXECUTE_WORKFLOW_ID,
            EXECUTE_WORKFLOW_NAME,
            i_owner,
            1,
            _childStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory executeLogs = vm.getRecordedLogs();

        Vm.Log memory withdrawLog =
            _assertEmittedBy(executeLogs, keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(child.vault));
        assertEq(uint256(withdrawLog.topics[1]), 1);
        assertEq(uint256(withdrawLog.topics[2]), tvl);

        Vm.Log memory depositLog =
            _assertEmittedBy(executeLogs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(child.vault));
        assertEq(uint256(depositLog.topics[1]), 1);
        assertEq(uint256(depositLog.topics[2]), tvl);

        assertEq(IERC20(parent.usdc).balanceOf(address(local.mockCcipRouter)), routerBalanceBeforeRebalance);
        assertEq(child.vault.getActiveProtocolAdapter(), address(child.aaveV4Adapter));
        assertEq(
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(child.aaveV4Adapter)),
            targetTvlBefore + tvl
        );

        vm.recordLogs();
        _completeRebalanceThroughWorkflow(parent.workflowRouter, COMPLETE_WORKFLOW_ID, COMPLETE_WORKFLOW_NAME, i_owner);
        Vm.Log[] memory completeLogs = vm.getRecordedLogs();

        Vm.Log memory completedLog = _assertEmittedBy(
            completeLogs, keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(parent.vault)
        );
        assertEq(uint256(completedLog.topics[1]), 1);
        assertEq(bytes32(completedLog.topics[2]), AAVE_V4_PROTOCOL_ID);
        assertEq(uint64(uint256(completedLog.topics[3])), CHILD_CHAIN_SELECTOR);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
        assertEq(completedRebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(completedRebalance.pendingStrategy.chainSelector, 0);
    }
}
