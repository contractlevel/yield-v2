// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {RevertingProtocolAdapter} from "../../../../../mocks/RevertingProtocolAdapter.sol";
import {Vm} from "forge-std/Test.sol";

contract ChildDeposit_RebalanceRecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-initiate");
    bytes32 private constant COMPLETE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-complete");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
    }

    function test_CcipFork_recoveryChildRebalanceDeposit_CompletesAfterFailedParentToArbitrumDeposit() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);
        uint256 rebalanceAmount = parent.aaveV3Adapter.getTVL();

        _setArbitrumAaveV3RegistryAdapter(address(arbitrumFailingAdapter));
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _arbitrumAaveV3Strategy());

        _selectBaseFork();
        _routeUsdcMessageFromActiveForkTo(arbitrumFork);

        _selectArbitrumFork();
        _assertRebalanceDepositRecovery(arbitrumChild.vault.getRebalanceDepositRecovery(), 1, rebalanceAmount);
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        _selectBaseFork();
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _restoreArbitrumAaveV3Adapter();
        vm.recordLogs();
        arbitrumChild.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(
            recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(arbitrumChild.vault)
        );
        _assertRebalanceDepositRecoveryCleared(arbitrumChild.vault.getRebalanceDepositRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertApproxEqAbs(arbitrumChild.aaveV3Adapter.getTVL(), rebalanceAmount, PROTOCOL_FORK_TOLERANCE);

        _selectBaseFork();
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, arbitrumConfig.ccip.thisChainSelector);
    }

    function test_CcipFork_recoveryChildRebalanceDeposit_CompletesAfterFailedParentToPolygonDeposit() external {
        _seedParentAaveV3Tvl(DEPOSIT_AMOUNT);
        uint256 rebalanceAmount = parent.aaveV3Adapter.getTVL();

        _selectPolygonFork();
        RevertingProtocolAdapter failingAdapter =
            new RevertingProtocolAdapter(address(polygonChild.vault), polygonChild.asset);
        _setRegistryAdapter(polygonChild.adapterRegistry, AAVE_V3_PROTOCOL_ID, address(failingAdapter));
        _selectBaseFork();
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);
        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _polygonAaveV3Strategy());

        _selectBaseFork();
        _routeUsdcMessageFromActiveForkTo(polygonFork);

        _selectPolygonFork();
        _assertRebalanceDepositRecovery(polygonChild.vault.getRebalanceDepositRecovery(), 1, rebalanceAmount);
        assertTrue(polygonChild.vault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        _selectBaseFork();
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _selectPolygonFork();
        _setRegistryAdapter(polygonChild.adapterRegistry, AAVE_V3_PROTOCOL_ID, address(polygonChild.aaveV3Adapter));
        _setPolygonChildActiveAdapterToAaveV3();
        vm.recordLogs();
        polygonChild.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(
            recoveryLogs, keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(polygonChild.vault)
        );
        _assertRebalanceDepositRecoveryCleared(polygonChild.vault.getRebalanceDepositRecovery());
        assertTrue(polygonChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertApproxEqAbs(polygonChild.aaveV3Adapter.getTVL(), rebalanceAmount, PROTOCOL_FORK_TOLERANCE);

        _selectBaseFork();
        _configureCompleteRebalanceWorkflow(COMPLETE_WORKFLOW_ID);
        _completeRebalanceThroughWorkflow(COMPLETE_WORKFLOW_ID);
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, polygonConfig.ccip.thisChainSelector);
    }
}
