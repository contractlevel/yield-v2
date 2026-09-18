// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ParentToChild_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-parent-child-initiate");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-parent-child-complete");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
    }

    function test_CcipFork_rebalanceParentToChild_RoutesUsdcToChildAndCompletes() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _arbitrumAaveV3Strategy());
        _routeUsdcMessageTo(arbitrumFork);

        _selectArbitrumFork();
        assertApproxEqAbs(arbitrumChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(arbitrumChild.aaveV3Adapter));

        _selectBaseFork();
        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(0));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, arbitrumConfig.ccip.thisChainSelector);
    }

    function test_CcipFork_rebalanceParentToChild_RoutesUsdcToPolygonAndCompletes() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _polygonAaveV3Strategy());
        _routeUsdcMessageTo(polygonFork);

        _selectPolygonFork();
        assertApproxEqAbs(polygonChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(polygonChild.vault.getActiveProtocolAdapter(), address(polygonChild.aaveV3Adapter));

        _selectBaseFork();
        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(0));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, polygonConfig.ccip.thisChainSelector);
    }
}
