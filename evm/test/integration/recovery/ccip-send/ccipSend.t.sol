// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseRecoveryIntegrationTest} from "../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CcipSend_RecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    address internal constant INVALID_CCIP_RECEIVER = address(1);

    function test_Recovery_ChildVault_ccipSend_EpochWithdraw_RetryMakesParentEpochClaimable() external {
        uint256 shareAmount = _depositAndClaimParentLocalShares();

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_REBALANCE_WORKFLOW_ID,
            INITIATE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            _childStrategy(AAVE_V3_PROTOCOL_ID)
        );
        _completeRebalanceThroughWorkflow(
            parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
        );

        _approveShares(i_depositor, address(parent.vault), shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, DEPOSIT_AMOUNT
        );
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, INVALID_CCIP_RECEIVER);

        vm.recordLogs();
        _executeEpochWithdrawThroughWorkflow(
            child.workflowRouter,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
            i_owner,
            2,
            DEPOSIT_AMOUNT
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(storedLog.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(storedLog.topics[3]), DEPOSIT_AMOUNT);
        _assertCcipSendRecovery(
            child.vault.getCcipSendRecovery(),
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            PARENT_CHAIN_SELECTOR,
            DEPOSIT_AMOUNT,
            2,
            bytes32(0)
        );
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));

        vm.recordLogs();
        child.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("CCIPBridged(bytes32,uint64,uint8)"), address(child.vault));
        _assertCcipSendRecoveryCleared(child.vault.getCcipSendRecovery());
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBeforeClaim = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertEq(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBeforeClaim + DEPOSIT_AMOUNT);
    }

    function test_Recovery_ChildVault_ccipSend_Rebalance_RetryCompletesParentRebalance() external {
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedChildLocalTvl(tvl);
        address parentSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 parentReserveId = parent.aaveV4Adapter.getReserveId();
        uint256 parentSuppliedBefore =
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter));

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            INITIATE_REBALANCE_WORKFLOW_ID,
            INITIATE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, INVALID_CCIP_RECEIVER);

        vm.recordLogs();
        _executeRebalanceThroughWorkflow(
            child.workflowRouter,
            EXECUTE_REBALANCE_WORKFLOW_ID,
            EXECUTE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            1,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.REBALANCE));
        assertEq(uint64(uint256(storedLog.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(storedLog.topics[3]), tvl);
        _assertCcipSendRecovery(
            child.vault.getCcipSendRecovery(),
            Types.CcipTx.REBALANCE,
            PARENT_CHAIN_SELECTOR,
            tvl,
            1,
            AAVE_V4_PROTOCOL_ID
        );
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));

        vm.recordLogs();
        child.vault.executeRecovery();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("CCIPBridged(bytes32,uint64,uint8)"), address(child.vault));
        _assertCcipSendRecoveryCleared(child.vault.getCcipSendRecovery());
        assertTrue(child.vault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter)),
            parentSuppliedBefore + tvl
        );
        _assertCompletedRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
    }
}
