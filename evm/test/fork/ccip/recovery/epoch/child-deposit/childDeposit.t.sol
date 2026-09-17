// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";

contract ChildDeposit_RecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-close");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToFailingAdapter();
    }

    function test_CcipFork_recoveryChildEpochDeposit_DepositsAfterFailedArbitrumDeposit() external {
        _selectBaseFork();

        _fundAndApproveParentUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 0);

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToFailingAdapter();
        _selectBaseFork();
        _routeUsdcMessageFromActiveForkTo(arbitrumFork);

        _selectArbitrumFork();
        _assertEpochRecovery(arbitrumChild.vault.getEpochDepositRecovery(), 1, DEPOSIT_AMOUNT);
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);

        _restoreArbitrumAaveV3Adapter();
        vm.recordLogs();
        arbitrumChild.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("EpochDepositRecoveryCleared(uint256)"), address(arbitrumChild.vault));
        _assertEpochRecoveryCleared(arbitrumChild.vault.getEpochDepositRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertApproxEqAbs(arbitrumChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);

        _selectBaseFork();
        _completeEpochDepositThroughWorkflow(CLOSE_WORKFLOW_ID, 1, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(parent.share.balanceOf(i_depositor), expectedShares);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
