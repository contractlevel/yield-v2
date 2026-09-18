// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ChildToRemoteChild_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-execute");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-complete");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteRebalanceWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_rebalanceChildToRemoteChild_RoutesUsdcToRemoteChildAndCompletes() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _ethereumAaveV3Strategy());

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToAaveV3();
        _executeRebalanceThroughWorkflow(
            arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _ethereumAaveV3Strategy()
        );
        _selectEthereumFork();
        _setCrosschainVault(ethereumChild.vault, arbitrumConfig.ccip.thisChainSelector, address(arbitrumChild.vault));
        _selectArbitrumFork();
        _routeUsdcMessageTo(ethereumFork);

        _selectArbitrumFork();
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(0));

        _selectEthereumFork();
        assertApproxEqAbs(ethereumChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(ethereumChild.vault.getActiveProtocolAdapter(), address(ethereumChild.aaveV3Adapter));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, ethereumConfig.ccip.thisChainSelector);
    }

    function test_CcipFork_rebalanceChildToRemoteChild_RoutesUsdcToPolygonAndCompletes() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _polygonAaveV3Strategy());

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToAaveV3();
        _executeRebalanceThroughWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _polygonAaveV3Strategy());
        _selectPolygonFork();
        _setCrosschainVault(polygonChild.vault, arbitrumConfig.ccip.thisChainSelector, address(arbitrumChild.vault));
        _selectArbitrumFork();
        _routeUsdcMessageTo(polygonFork);

        _selectArbitrumFork();
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(0));

        _selectPolygonFork();
        assertApproxEqAbs(polygonChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(polygonChild.vault.getActiveProtocolAdapter(), address(polygonChild.aaveV3Adapter));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, polygonConfig.ccip.thisChainSelector);
    }
}
