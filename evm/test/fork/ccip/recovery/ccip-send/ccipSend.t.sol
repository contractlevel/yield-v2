// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

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
        _selectArbitrumFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _configureInitiateRebalanceWorkflow(INITIATE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteEpochWithdrawWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID);
        _configureExecuteRebalanceWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_Recovery_ChildVault_ccipSend_EpochWithdraw_RetryMakesParentEpochClaimable() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);

        _selectArbitrumFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, shareAmount);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _prepareBaseToParentRouting();
        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, INVALID_CCIP_RECEIVER);
        vm.warp(block.timestamp + 5 minutes);

        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, shareAmount);
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(baseChild.vault)
        );
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(storedLog.topics[2])), arbitrumConfig.ccip.thisChainSelector);
        assertEq(uint256(storedLog.topics[3]), shareAmount);
        _assertCcipSendRecovery(
            baseChild.vault.getCcipSendRecovery(),
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            arbitrumConfig.ccip.thisChainSelector,
            shareAmount,
            abi.encode(uint256(2))
        );
        assertTrue(baseChild.vault.getRecoveryExists());

        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, address(parent.vault));
        vm.warp(block.timestamp + 5 minutes);
        baseChild.vault.recoverFailedCcipSend();

        _selectBaseFork();
        _routeUsdcMessageTo(arbitrumFork);
        _assertCcipSendRecoveryCleared(baseChild.vault.getCcipSendRecovery());
        assertFalse(baseChild.vault.getRecoveryExists());

        _selectArbitrumFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertApproxEqAbs(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + shareAmount, 1);
    }

    function test_CcipFork_Recovery_ChildVault_ccipSend_Rebalance_RetryCompletesParentRebalance() external {
        _seedBaseChildAaveV3Tvl(DEPOSIT_AMOUNT);

        _initiateRebalanceThroughWorkflow(INITIATE_WORKFLOW_ID, _parentAaveV3Strategy());
        _prepareBaseToParentRouting();
        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, INVALID_CCIP_RECEIVER);

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(baseChild.workflowRouter, EXECUTE_WORKFLOW_ID, 1, _parentAaveV3Strategy());
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(baseChild.vault)
        );
        Types.CcipSendRecovery memory recovery = baseChild.vault.getCcipSendRecovery();
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.REBALANCE));
        assertEq(uint64(uint256(storedLog.topics[2])), arbitrumConfig.ccip.thisChainSelector);
        assertEq(uint256(storedLog.topics[3]), recovery.amount);
        assertApproxEqAbs(recovery.amount, DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        _assertCcipSendRecovery(
            recovery,
            Types.CcipTx.REBALANCE,
            arbitrumConfig.ccip.thisChainSelector,
            recovery.amount,
            abi.encode(uint256(1), AAVE_V3_PROTOCOL_ID)
        );
        assertTrue(baseChild.vault.getRecoveryExists());

        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, address(parent.vault));
        vm.warp(block.timestamp + 5 minutes);
        baseChild.vault.recoverFailedCcipSend();

        _selectBaseFork();
        _routeUsdcMessageTo(arbitrumFork);
        _assertCcipSendRecoveryCleared(baseChild.vault.getCcipSendRecovery());
        assertFalse(baseChild.vault.getRecoveryExists());
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(0));

        _selectArbitrumFork();
        assertApproxEqAbs(parent.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
        _assertCompletedRebalance(AAVE_V3_PROTOCOL_ID, arbitrumConfig.ccip.thisChainSelector);
    }
}
