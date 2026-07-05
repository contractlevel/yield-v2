// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ChildDeposit_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-initiate");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-complete");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
    }

    function test_CcipFork_recoveryChildRebalanceDeposit_CompletesAfterFailedParentToBaseDeposit() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);
        uint256 rebalanceAmount = parent.aaveV3Adapter.getTVL();

        _setBaseAaveV3RegistryAdapter(address(baseFailingAdapter));
        _selectArbitrumFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _baseAaveV3Strategy());

        _selectArbitrumFork();
        _routeUsdcMessageFromActiveForkTo(baseFork);

        _selectBaseFork();
        _assertRebalanceDepositRecovery(baseChild.vault.getRebalanceDepositRecovery(), 1, rebalanceAmount);
        assertTrue(baseChild.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        _selectArbitrumFork();
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _restoreBaseAaveV3Adapter();
        vm.recordLogs();
        baseChild.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(baseChild.vault));
        _assertRebalanceDepositRecoveryCleared(baseChild.vault.getRebalanceDepositRecovery());
        assertTrue(baseChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertApproxEqAbs(baseChild.aaveV3Adapter.getTVL(), rebalanceAmount, PROTOCOL_FORK_TOLERANCE);

        _selectArbitrumFork();
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, baseConfig.ccip.thisChainSelector);
    }
}
