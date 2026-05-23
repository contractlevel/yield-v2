// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ChildWithdraw_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-execute");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteRebalanceWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryChildRebalanceWithdraw_FinalizesParentAfterFailedBaseWithdraw() external {
        _seedBaseChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _selectBaseFork();
        _setBaseChildActiveAdapterToFailingAdapter();
        vm.recordLogs();
        _executeRebalanceThroughWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("RebalanceWithdrawRecoveryStored(uint256,bytes32,uint64)"), address(baseChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(bytes32(storedLog.topics[2]), AAVE_V3_PROTOCOL_ID);
        assertEq(uint64(uint256(storedLog.topics[3])), arbitrumConfig.ccip.thisChainSelector);
        _assertRebalanceWithdrawRecovery(
            baseChild.vault.getRebalanceWithdrawRecovery(),
            1,
            AAVE_V3_PROTOCOL_ID,
            arbitrumConfig.ccip.thisChainSelector
        );
        assertTrue(baseChild.vault.getRecoveryExists());

        _restoreBaseAaveV3Adapter();
        _prepareBaseToParentRouting();
        vm.warp(block.timestamp + 5 minutes);
        baseChild.vault.recoverFailedRebalanceWithdraw();

        _selectBaseFork();
        _routeUsdcMessageTo(arbitrumFork);

        _selectBaseFork();
        _assertRebalanceWithdrawRecoveryCleared(baseChild.vault.getRebalanceWithdrawRecovery());
        assertFalse(baseChild.vault.getRecoveryExists());
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(0));

        _selectArbitrumFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, arbitrumConfig.ccip.thisChainSelector);
    }
}
