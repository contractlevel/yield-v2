// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ParentDeposit_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-parent-deposit-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-recovery-parent-deposit-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteRebalanceWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryParentRebalanceDeposit_FinalizesAfterFailedArbitrumToParentDeposit() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);
        uint256 rebalanceAmount = arbitrumChild.aaveV3Adapter.getTVL();

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _setParentAaveV3RegistryAdapter(address(parentFailingAdapter));
        _selectArbitrumFork();
        _setCrosschainVault(arbitrumChild.vault, baseConfig.ccip.thisChainSelector, address(parent.vault));
        _selectBaseFork();
        _setCrosschainVault(parent.vault, arbitrumConfig.ccip.thisChainSelector, address(arbitrumChild.vault));
        _selectArbitrumFork();
        _executeRebalanceThroughWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());

        _selectArbitrumFork();
        _routeUsdcMessageFromActiveForkTo(baseFork);

        _selectBaseFork();
        _assertRebalanceDepositRecovery(parent.vault.getRebalanceDepositRecovery(), 1, rebalanceAmount);
        assertTrue(parent.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _restoreParentAaveV3Adapter();
        vm.recordLogs();
        parent.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(parent.vault));
        Vm.Log memory completedLog = _assertEmittedBy(
            recoveryLogs, keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(parent.vault)
        );
        assertEq(uint256(completedLog.topics[1]), 1);
        assertEq(bytes32(completedLog.topics[2]), AAVE_V3_PROTOCOL_ID);
        assertEq(uint64(uint256(completedLog.topics[3])), baseConfig.ccip.thisChainSelector);
        _assertRebalanceDepositRecoveryCleared(parent.vault.getRebalanceDepositRecovery());
        assertTrue(parent.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), rebalanceAmount, PROTOCOL_FORK_TOLERANCE);
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, baseConfig.ccip.thisChainSelector);
    }
}
