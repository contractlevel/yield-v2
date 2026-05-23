// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ParentDeposit_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-parent-deposit-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-recovery-parent-deposit-execute");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteRebalanceWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_recoveryParentRebalanceDeposit_FinalizesAfterFailedBaseToParentDeposit() external {
        _seedBaseChildAaveV3Tvl(DEPOSIT_AMOUNT);
        uint256 rebalanceAmount = baseChild.aaveV3Adapter.getTVL();

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());

        _setParentAaveV3RegistryAdapter(address(parentFailingAdapter));
        _selectBaseFork();
        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, address(parent.vault));
        _selectArbitrumFork();
        _setCrosschainVault(parent.vault, baseConfig.ccip.thisChainSelector, address(baseChild.vault));
        _selectBaseFork();
        _executeRebalanceThroughWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());

        _selectBaseFork();
        _routeUsdcMessageFromActiveForkTo(arbitrumFork);

        _selectArbitrumFork();
        _assertRebalanceDepositRecovery(parent.vault.getRebalanceDepositRecovery(), 1, rebalanceAmount);
        assertTrue(parent.vault.getRecoveryExists());
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _restoreParentAaveV3Adapter();
        vm.recordLogs();
        parent.vault.recoverFailedRebalanceDeposit();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(parent.vault));
        _assertEmittedBy(recoveryLogs, keccak256("RebalanceCompleted(uint256)"), address(parent.vault));
        _assertRebalanceDepositRecoveryCleared(parent.vault.getRebalanceDepositRecovery());
        assertFalse(parent.vault.getRecoveryExists());
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), rebalanceAmount, PROTOCOL_FORK_TOLERANCE);
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, arbitrumConfig.ccip.thisChainSelector);
    }
}
