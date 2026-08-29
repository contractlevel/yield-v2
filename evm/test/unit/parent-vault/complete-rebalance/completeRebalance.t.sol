// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CompleteRebalanceUnitTest is BaseUnitTest {
    uint256 internal constant TOTAL_SHARES = 1_000_000 * YIELD_PRECISION;
    uint256 internal constant MANAGEMENT_FEE_BPS = 100;
    uint256 internal constant BPS_DENOMINATOR = 10_000;

    function setUp() public {
        _setParentRebalanceState(Types.RebalanceState.REBALANCING);
        _changePrank(i_rebalanceOperator);
    }

    function test_ParentVault_completeRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        uint256 rebalanceNonce = s_parentVault.getRebalance().nonce;
        vm.expectRevert();
        s_parentVault.completeRebalance(rebalanceNonce);
    }

    function test_ParentVault_completeRebalance_RevertWhen_Paused() public {
        _changePrank(i_pauser);
        s_parentVault.pause();

        _changePrank(i_rebalanceOperator);
        uint256 rebalanceNonce = s_parentVault.getRebalance().nonce;
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.completeRebalance(rebalanceNonce);
    }

    function test_ParentVault_completeRebalance_RevertWhen_InvalidRebalanceNonce() public {
        uint256 invalidRebalanceNonce = s_parentVault.getRebalance().nonce + 1;

        vm.expectRevert(
            abi.encodeWithSelector(IParentVault.ParentVault__InvalidRebalanceNonce.selector, invalidRebalanceNonce)
        );
        s_parentVault.completeRebalance(invalidRebalanceNonce);
    }

    function test_ParentVault_completeRebalance_RevertWhen_NoRebalanceInProgress() public {
        _setParentRebalanceState(Types.RebalanceState.NONE);
        uint256 rebalanceNonce = s_parentVault.getRebalance().nonce;
        vm.expectRevert(IParentVault.ParentVault__NoRebalanceInProgress.selector);
        s_parentVault.completeRebalance(rebalanceNonce);
    }

    function test_ParentVault_completeRebalance_RevertWhen_RecoveryExists() public {
        _setParentRecoveryMode(Types.RecoveryMode.REBALANCE_DEPOSIT);

        uint256 rebalanceNonce = s_parentVault.getRebalance().nonce;
        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_parentVault.completeRebalance(rebalanceNonce);
    }

    function test_ParentVault_completeRebalance_RevertWhen_PendingStrategyIsLocal() public {
        _setParentPendingRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        assertEq(s_parentVault.getRebalance().pendingStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
        uint256 rebalanceNonce = s_parentVault.getRebalance().nonce;

        vm.expectRevert(IParentVault.ParentVault__CannotCompleteLocalRebalance.selector);
        s_parentVault.completeRebalance(rebalanceNonce);
    }

    function test_ParentVault_completeRebalance_Success_SetsRebalanceStateToNone() public {
        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);
        assertEq(uint256(s_parentVault.getRebalance().state), uint256(Types.RebalanceState.NONE));
    }

    function test_ParentVault_completeRebalance_Success_IncrementsRebalanceNonce() public {
        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);
        assertEq(s_parentVault.getRebalance().nonce, 2);
    }

    function test_ParentVault_completeRebalance_Success_UpdatesLastRebalanceCompletedTimestamp() public {
        vm.warp(block.timestamp + 30 days);
        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);
        assertEq(s_parentVault.getRebalance().lastRebalanceCompletedTimestamp, block.timestamp);
    }

    function test_ParentVault_completeRebalance_Success_MintsFeeSharestoTreasury() public {
        _setParentTotalShares(TOTAL_SHARES);
        uint256 elapsed = 365 days;
        vm.warp(s_parentVault.getRebalance().lastRebalanceCompletedTimestamp + elapsed);

        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);

        assertEq(s_yieldcoin.balanceOf(i_treasury), _expectedFeeShares(TOTAL_SHARES, elapsed));
    }

    function test_ParentVault_completeRebalance_Success_IncrementsTotalSharesByFeeShares() public {
        _setParentTotalShares(TOTAL_SHARES);
        uint256 elapsed = 365 days;
        vm.warp(s_parentVault.getRebalance().lastRebalanceCompletedTimestamp + elapsed);

        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);

        assertEq(s_parentVault.getTotalShares(), TOTAL_SHARES + _expectedFeeShares(TOTAL_SHARES, elapsed));
    }

    function test_ParentVault_completeRebalance_Success_Emits_RebalanceCompleted() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);

        vm.recordLogs();
        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(log.topics[2], AAVE_V3_PROTOCOL_ID);
        assertEq(uint256(log.topics[3]), CHILD_CHAIN_SELECTOR);
    }

    function test_ParentVault_completeRebalance_Success_Emits_ManagementFeeCollected() public {
        _setParentTotalShares(TOTAL_SHARES);
        uint256 elapsed = 365 days;
        vm.warp(s_parentVault.getRebalance().lastRebalanceCompletedTimestamp + elapsed);

        uint256 expectedFeeShares = _expectedFeeShares(TOTAL_SHARES, elapsed);

        vm.recordLogs();
        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("ManagementFeeCollected(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), expectedFeeShares);
    }

    function test_ParentVault_completeRebalance_Success_CapsManagementFeeElapsedAtOneYear() public {
        _setParentTotalShares(TOTAL_SHARES);
        uint256 elapsed = 730 days;
        vm.warp(s_parentVault.getRebalance().lastRebalanceCompletedTimestamp + elapsed);

        uint256 expectedFeeShares = _expectedFeeShares(TOTAL_SHARES, 365 days);

        s_parentVault.completeRebalance(s_parentVault.getRebalance().nonce);

        assertEq(s_yieldcoin.balanceOf(i_treasury), expectedFeeShares);
        assertEq(s_parentVault.getTotalShares(), TOTAL_SHARES + expectedFeeShares);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _expectedFeeShares(uint256 totalShares, uint256 elapsed) internal pure returns (uint256) {
        if (elapsed > 365 days) elapsed = 365 days;
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        return (totalShares * MANAGEMENT_FEE_BPS * elapsed + denominator - 1) / denominator;
    }
}
