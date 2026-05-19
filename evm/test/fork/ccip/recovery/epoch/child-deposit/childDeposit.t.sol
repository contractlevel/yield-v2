// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipRecoveryForkTest} from "../../BaseCcipRecoveryForkTest.t.sol";

import {Vm} from "forge-std/Test.sol";

contract ChildDeposit_RecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-recovery-child-deposit-close");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToFailingAdapter();
    }

    function test_CcipFork_recoveryChildEpochDeposit_DepositsAfterFailedBaseDeposit() external {
        _selectArbitrumFork();

        _registerKyc(i_depositor);
        _fundAndApproveParentUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 1, 0);

        _selectBaseFork();
        _setBaseChildActiveAdapterToFailingAdapter();
        _selectArbitrumFork();
        _routeUsdcMessageFromActiveForkTo(baseFork);

        _selectBaseFork();
        _assertAmountRecovery(baseChild.vault.getEpochDepositRecovery(1), DEPOSIT_AMOUNT);

        _restoreBaseAaveV3Adapter();
        vm.recordLogs();
        baseChild.vault.recoverFailedEpochDeposit(1);
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("EpochDepositRecoveryCleared(uint256)"), address(baseChild.vault));
        _assertAmountRecoveryCleared(baseChild.vault.getEpochDepositRecovery(1));
        assertApproxEqAbs(baseChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);

        _selectArbitrumFork();
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        assertEq(parent.share.balanceOf(i_depositor), DEPOSIT_AMOUNT);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
