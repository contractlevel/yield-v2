// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseRecoveryIntegrationTest} from "../BaseRecoveryIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";

import {Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CcipSend_RecoveryIntegrationTest is BaseRecoveryIntegrationTest {
    address internal constant INVALID_CCIP_RECEIVER = address(1);

    function test_Recovery_ChildVault_ccipSend_EpochWithdraw_RetryMakesParentEpochClaimable() external {
        uint256 shareAmount = _depositAndClaimParentLocalShares();
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);

        address childPool = child.aaveV3Adapter.getProtocolPool();
        _prepareAaveV3RebalanceWithdraw(childPool, address(child.aaveV3Adapter), shareAmount);

        _approveShares(i_depositor, address(parent.vault), shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, shareAmount
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
            shareAmount
        );
        Vm.Log[] memory failureLogs = vm.getRecordedLogs();

        Vm.Log memory storedLog = _assertEmittedBy(
            failureLogs, keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(child.vault)
        );
        assertEq(uint256(storedLog.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(storedLog.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(storedLog.topics[3]), shareAmount);
        _assertCcipSendRecovery(
            child.vault.getCcipSendRecovery(),
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            PARENT_CHAIN_SELECTOR,
            shareAmount,
            abi.encode(uint256(2))
        );
        assertTrue(child.vault.getRecoveryExists());
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));

        vm.recordLogs();
        child.vault.recoverFailedCcipSend();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("CCIPBridged(bytes32,uint256,uint8)"), address(child.vault));
        _assertCcipSendRecoveryCleared(child.vault.getCcipSendRecovery());
        assertFalse(child.vault.getRecoveryExists());
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBeforeClaim = IERC20(parent.usdc).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimUsdc(2);

        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBeforeClaim + shareAmount);
    }

    function test_Recovery_ChildVault_ccipSend_Rebalance_RetryCompletesParentRebalance() external {
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        uint256 tvl = DEPOSIT_AMOUNT;
        _seedChildLocalTvl(tvl);
        address childPool = child.aaveV3Adapter.getProtocolPool();
        address parentSpoke = parent.aaveV4Adapter.getProtocolPool();
        uint256 parentReserveId = parent.aaveV4Adapter.getReserveId();
        uint256 parentSuppliedBefore =
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter));

        _prepareAaveV3RebalanceWithdraw(childPool, address(child.aaveV3Adapter), tvl);

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
            abi.encode(uint256(1), AAVE_V4_PROTOCOL_ID)
        );
        assertTrue(child.vault.getRecoveryExists());
        assertEq(uint256(parent.vault.getRebalance().state), uint256(Types.RebalanceState.REBALANCING));

        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));

        vm.recordLogs();
        child.vault.recoverFailedCcipSend();
        Vm.Log[] memory recoveryLogs = vm.getRecordedLogs();

        _assertEmittedBy(recoveryLogs, keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(child.vault));
        _assertEmittedBy(recoveryLogs, keccak256("CCIPBridged(bytes32,uint256,uint8)"), address(child.vault));
        _assertCcipSendRecoveryCleared(child.vault.getCcipSendRecovery());
        assertFalse(child.vault.getRecoveryExists());
        assertEq(
            MockAaveV4Spoke(parentSpoke).getUserSuppliedAssets(parentReserveId, address(parent.aaveV4Adapter)),
            parentSuppliedBefore + tvl
        );
        _assertCompletedRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
    }
}
