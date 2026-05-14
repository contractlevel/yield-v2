// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildToParent_RebalanceIntegrationTest is BaseIntegrationTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("child-to-parent-initiate-rebalance");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("child-to-parent-execute-rebalance");
    bytes10 private constant INITIATE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 private constant EXECUTE_WORKFLOW_NAME = bytes10("execRb");

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, INITIATE_WORKFLOW_ID, INITIATE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteRebalanceWorkflow(child.workflowRouter, EXECUTE_WORKFLOW_ID, EXECUTE_WORKFLOW_NAME, i_owner);

        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();
    }

    function test_Rebalance_childToParent_FinalizesAfterLocalCcipSendToParent() external {
        uint256 tvl = _seedChildLocalTvl(DEPOSIT_AMOUNT);
        address oldPool = child.aaveV3Adapter.getProtocolPool();
        address targetSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 targetReserveId = parent.aaveV4Adapter.getReserveId();

        MockAaveV3Pool(oldPool).setATokenAddress(parent.usdc);
        deal(parent.usdc, address(child.aaveV3Adapter), tvl);
        deal(parent.usdc, oldPool, tvl);
        MockAaveV3Pool(oldPool).setWithdrawReturn(tvl);

        uint256 routerBalanceBeforeRebalance = IERC20(parent.usdc).balanceOf(address(local.mockCcipRouter));
        uint256 targetTvlBefore =
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(parent.aaveV4Adapter));

        vm.recordLogs();
        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_WORKFLOW_ID,
            INITIATE_WORKFLOW_NAME,
            i_owner,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory initiateLogs = vm.getRecordedLogs();

        Vm.Log memory initiatedLog = _assertEmittedBy(
            initiateLogs, keccak256("RebalanceInitiated(uint256,uint64,bytes32)"), address(parent.vault)
        );
        assertEq(uint256(initiatedLog.topics[1]), 1);
        assertEq(uint64(uint256(initiatedLog.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(bytes32(initiatedLog.topics[3]), AAVE_V4_PROTOCOL_ID);

        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(pendingRebalance.nonce, 1);
        assertEq(pendingRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(pendingRebalance.activeStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
        assertEq(pendingRebalance.pendingStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(pendingRebalance.pendingStrategy.chainSelector, PARENT_CHAIN_SELECTOR);

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(
            child.workflowRouter,
            EXECUTE_WORKFLOW_ID,
            EXECUTE_WORKFLOW_NAME,
            i_owner,
            1,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory executeLogs = vm.getRecordedLogs();

        Vm.Log memory withdrawLog =
            _assertEmittedBy(executeLogs, keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(child.vault));
        assertEq(uint256(withdrawLog.topics[1]), 1);
        assertEq(uint256(withdrawLog.topics[2]), tvl);

        Vm.Log memory childBridgeLog =
            _assertEmittedBy(executeLogs, keccak256("USDCBridged(bytes32,uint256,uint8)"), address(child.vault));
        assertEq(uint256(childBridgeLog.topics[2]), tvl);
        assertEq(uint256(childBridgeLog.topics[3]), uint256(Types.CcipTx.REBALANCE));

        Vm.Log memory depositLog =
            _assertEmittedBy(executeLogs, keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(parent.vault));
        assertEq(uint256(depositLog.topics[1]), 1);
        assertEq(uint256(depositLog.topics[2]), tvl);

        Vm.Log memory completedLog =
            _assertEmittedBy(executeLogs, keccak256("RebalanceCompleted(uint256)"), address(parent.vault));
        assertEq(uint256(completedLog.topics[1]), 1);

        assertEq(IERC20(parent.usdc).balanceOf(address(local.mockCcipRouter)), routerBalanceBeforeRebalance);
        assertEq(child.vault.getActiveProtocolAdapter(), address(0));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV4Adapter));
        assertEq(
            MockAaveV4Spoke(targetSpoke).getUserSuppliedAssets(targetReserveId, address(parent.aaveV4Adapter)),
            targetTvlBefore + tvl
        );

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(completedRebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(completedRebalance.pendingStrategy.chainSelector, 0);
    }
}
