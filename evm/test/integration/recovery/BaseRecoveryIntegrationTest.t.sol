// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../BaseIntegrationTest.t.sol";

import {Types} from "../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";

abstract contract BaseRecoveryIntegrationTest is BaseIntegrationTest {
    bytes32 internal constant CLOSE_EPOCH_WORKFLOW_ID = keccak256("recovery-close-epoch");
    bytes32 internal constant EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID = keccak256("recovery-execute-epoch-withdraw");
    bytes32 internal constant INITIATE_REBALANCE_WORKFLOW_ID = keccak256("recovery-initiate-rebalance");
    bytes32 internal constant EXECUTE_REBALANCE_WORKFLOW_ID = keccak256("recovery-execute-rebalance");
    bytes32 internal constant COMPLETE_REBALANCE_WORKFLOW_ID = keccak256("recovery-complete-rebalance");
    bytes10 internal constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 internal constant EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME = bytes10("epochDraw");
    bytes10 internal constant INITIATE_REBALANCE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 internal constant EXECUTE_REBALANCE_WORKFLOW_NAME = bytes10("execRb");
    bytes10 internal constant COMPLETE_REBALANCE_WORKFLOW_NAME = bytes10("completeRb");

    function setUp() public virtual override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _configureExecuteEpochWithdrawWorkflow(
            child.workflowRouter, EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID, EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME, i_owner
        );
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteRebalanceWorkflow(
            child.workflowRouter, EXECUTE_REBALANCE_WORKFLOW_ID, EXECUTE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _configureCompleteRebalanceWorkflow(
            parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _setDefaultCcipGasLimits();
    }

    function _depositAndClaimParentLocalShares() internal returns (uint256 shareAmount) {
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 1, 0
        );

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        return DEPOSIT_AMOUNT;
    }

    function _prepareAaveV3RebalanceWithdraw(address pool, address adapter, uint256 amount) internal {
        MockAaveV3Pool(pool).setATokenAddress(parent.usdc);
        deal(parent.usdc, adapter, amount);
        deal(parent.usdc, pool, amount);
        MockAaveV3Pool(pool).setWithdrawReturn(amount);
    }

    function _assertAmountRecovery(Types.AmountRecovery memory recovery, uint256 amount) internal view {
        assertEq(recovery.amount, amount);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertAmountRecoveryCleared(Types.AmountRecovery memory recovery) internal pure {
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertRebalanceDepositRecovery(
        Types.RebalanceDepositRecovery memory recovery,
        uint256 rebalanceNonce,
        uint256 amount
    ) internal view {
        assertEq(recovery.rebalanceNonce, rebalanceNonce);
        assertEq(recovery.amount, amount);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertRebalanceDepositRecoveryCleared(Types.RebalanceDepositRecovery memory recovery) internal pure {
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertRebalanceWithdrawRecovery(
        Types.RebalanceWithdrawRecovery memory recovery,
        uint256 rebalanceNonce,
        bytes32 protocolId,
        uint64 chainSelector
    ) internal view {
        assertEq(recovery.rebalanceNonce, rebalanceNonce);
        assertEq(recovery.strategy.protocolId, protocolId);
        assertEq(recovery.strategy.chainSelector, chainSelector);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertRebalanceWithdrawRecoveryCleared(Types.RebalanceWithdrawRecovery memory recovery) internal pure {
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.strategy.protocolId, bytes32(0));
        assertEq(recovery.strategy.chainSelector, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertCompletedRebalance(bytes32 protocolId, uint64 chainSelector) internal view {
        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, 2);
        assertEq(rebalance.activeStrategy.protocolId, protocolId);
        assertEq(rebalance.activeStrategy.chainSelector, chainSelector);
        assertEq(rebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(rebalance.pendingStrategy.chainSelector, 0);
    }

    function test_baseRecoveryIntegrationTest() public virtual {}
}
