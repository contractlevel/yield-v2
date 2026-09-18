// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ChildToParent_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-child-parent-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-child-parent-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteRebalanceWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_rebalanceChildToParent_RoutesUsdcToParentAndFinalizes() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _selectArbitrumFork();
        _executeRebalanceThroughWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        _routeUsdcMessageTo(baseFork);

        _selectBaseFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, baseConfig.ccip.thisChainSelector);
    }

    function test_CcipFork_rebalanceChildToParent_RoutesPolygonUsdcToParentAndFinalizes() external {
        _setParentRemoteStrategyToPolygon();
        _setPolygonChildActiveAdapterToAaveV3();
        _configureExecuteRebalanceWorkflow(polygonChild.workflowRouter, EXECUTE_WORKFLOW_ID);
        _seedPolygonChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _selectPolygonFork();
        _executeRebalanceThroughWorkflow(polygonChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        _routeUsdcMessageTo(baseFork);

        _selectBaseFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, baseConfig.ccip.thisChainSelector);
    }
}
