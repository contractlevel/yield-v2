// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ChildWithdraw_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-withdraw-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteRebalanceWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryChildRebalanceWithdraw_FinalizesParentAfterFailedArbitrumWithdraw() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToFailingAdapter();
        vm.recordLogs();
        _executeRebalanceThroughWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs,
            keccak256("RebalanceWithdrawRecoveryStored(uint256,bytes32,uint64)"),
            address(arbitrumChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), 1);
        assertEq(bytes32(storedLog.topics[2]), AAVE_V3_PROTOCOL_ID);
        assertEq(uint64(uint256(storedLog.topics[3])), baseConfig.ccip.thisChainSelector);
        _assertRebalanceWithdrawRecovery(
            arbitrumChild.vault.getRebalanceWithdrawRecovery(),
            1,
            AAVE_V3_PROTOCOL_ID,
            baseConfig.ccip.thisChainSelector
        );
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);

        _restoreArbitrumAaveV3Adapter();
        _prepareArbitrumToParentRouting();
        vm.warp(block.timestamp + 5 minutes);
        arbitrumChild.vault.executeRecovery();

        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);

        _selectArbitrumFork();
        _assertRebalanceWithdrawRecoveryCleared(arbitrumChild.vault.getRebalanceWithdrawRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(0));

        _selectBaseFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, baseConfig.ccip.thisChainSelector);
    }
}
