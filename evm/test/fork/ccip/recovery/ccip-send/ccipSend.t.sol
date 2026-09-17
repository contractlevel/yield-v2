// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipRecoveryForkTest} from "../BaseCcipRecoveryForkTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CcipSend_RecoveryCcipForkTest is BaseCcipRecoveryForkTest {
    address internal constant INVALID_CCIP_RECEIVER = address(1);

    bytes32 private constant SEED_WORKFLOW_ID = keccak256("ccip-fork-recovery-ccip-send-seed");
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-recovery-ccip-send-close");
    bytes32 private constant WITHDRAW_WORKFLOW_ID = keccak256("ccip-fork-recovery-ccip-send-withdraw");
    bytes32 private constant INITIATE_WORKFLOW_ID = keccak256("ccip-fork-recovery-ccip-send-initiate");
    bytes32 private constant EXECUTE_WORKFLOW_ID = keccak256("ccip-fork-recovery-ccip-send-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteEpochWithdrawWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID);
        _configureExecuteRebalanceWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_Recovery_ChildVault_ccipSend_EpochWithdraw_RetryMakesParentEpochClaimable() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);
        uint256 withdrawAmount = shareAmount * ASSET_PRECISION / YIELD_PRECISION;

        _selectBaseFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, withdrawAmount);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _prepareArbitrumToParentRouting();
        _setCrosschainVault(arbitrumChild.vault, baseConfig.ccip.thisChainSelector, INVALID_CCIP_RECEIVER);
        vm.warp(block.timestamp + 12 hours); // Avoid Aave rounding while keeping forked CCIP prices fresh.

        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, withdrawAmount);
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(arbitrumChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(storedLog.topics[2])), baseConfig.ccip.thisChainSelector);
        assertEq(uint256(storedLog.topics[3]), withdrawAmount);
        _assertCcipSendRecovery(
            arbitrumChild.vault.getCcipSendRecovery(),
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            baseConfig.ccip.thisChainSelector,
            withdrawAmount,
            2,
            bytes32(0)
        );
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);

        _setCrosschainVault(arbitrumChild.vault, baseConfig.ccip.thisChainSelector, address(parent.vault));
        vm.warp(block.timestamp + 5 minutes);
        arbitrumChild.vault.executeRecovery();

        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);
        _assertCcipSendRecoveryCleared(arbitrumChild.vault.getCcipSendRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertApproxEqAbs(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + withdrawAmount, 1);
    }

    function test_CcipFork_Recovery_ChildVault_ccipSend_Rebalance_RetryCompletesParentRebalance() external {
        _seedArbitrumChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());
        _prepareArbitrumToParentRouting();
        _setCrosschainVault(arbitrumChild.vault, baseConfig.ccip.thisChainSelector, INVALID_CCIP_RECEIVER);

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(arbitrumChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(arbitrumChild.vault)
        );
        Types.CcipSendRecovery memory recovery = arbitrumChild.vault.getCcipSendRecovery();
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.REBALANCE));
        assertEq(uint64(uint256(storedLog.topics[2])), baseConfig.ccip.thisChainSelector);
        assertEq(uint256(storedLog.topics[3]), recovery.amount);
        assertApproxEqAbs(recovery.amount, DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        _assertCcipSendRecovery(
            recovery, Types.CcipTx.REBALANCE, baseConfig.ccip.thisChainSelector, recovery.amount, 1, AAVE_V3_PROTOCOL_ID
        );
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);

        _setCrosschainVault(arbitrumChild.vault, baseConfig.ccip.thisChainSelector, address(parent.vault));
        vm.warp(block.timestamp + 5 minutes);
        arbitrumChild.vault.executeRecovery();

        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);
        _assertCcipSendRecoveryCleared(arbitrumChild.vault.getCcipSendRecovery());
        assertTrue(arbitrumChild.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(0));

        _selectBaseFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, baseConfig.ccip.thisChainSelector);
    }
}
