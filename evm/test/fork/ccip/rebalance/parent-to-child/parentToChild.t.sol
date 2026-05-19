// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ParentToChild_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-parent-child-initiate");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-parent-child-complete");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
    }

    function test_CcipFork_rebalanceParentToChild_RoutesUsdcToChildAndCompletes() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _baseAaveV3Strategy());
        _routeUsdcMessageTo(baseFork);

        _selectBaseFork();
        assertApproxEqAbs(baseChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(baseChild.aaveV3Adapter));

        _selectArbitrumFork();
        Types.Rebalance memory pendingRebalance = parent.vault.getRebalance();
        assertEq(uint256(pendingRebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(0));

        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID, 1);

        Types.Rebalance memory completedRebalance = parent.vault.getRebalance();
        assertEq(uint256(completedRebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(completedRebalance.nonce, 2);
        assertEq(completedRebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(completedRebalance.activeStrategy.chainSelector, baseConfig.ccip.thisChainSelector);
    }
}
