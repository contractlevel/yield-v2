// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ChildToRemoteChild_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-execute");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-child-remote-complete");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteRebalanceWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_rebalanceChildToRemoteChild_RoutesUsdcToRemoteChildAndCompletes() external {
        _seedBaseChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _ethereumAaveV3Strategy());

        _selectBaseFork();
        _setBaseChildActiveAdapterToAaveV3();
        _executeRebalanceThroughWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _ethereumAaveV3Strategy());
        _selectEthereumFork();
        _setCrosschainVault(ethereumChild.vault, baseConfig.ccip.thisChainSelector, address(baseChild.vault));
        _selectBaseFork();
        _routeUsdcMessageTo(ethereumFork);

        _selectBaseFork();
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(0));

        _selectEthereumFork();
        assertApproxEqAbs(ethereumChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(ethereumChild.vault.getActiveProtocolAdapter(), address(ethereumChild.aaveV3Adapter));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID, 1);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, ethereumConfig.ccip.thisChainSelector);
    }
}
