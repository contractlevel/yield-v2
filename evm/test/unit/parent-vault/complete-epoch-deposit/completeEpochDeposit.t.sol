// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CompleteEpochDepositUnitTest is BaseUnitTest {
    uint256 internal constant TVL = 1_000 * ASSET_PRECISION;

    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_CallerDoesNotHaveEpochOperatorRole() public {
        _prepareExecutingNetDeposit();

        _changePrank(i_nonOwner);
        vm.expectRevert();
        s_parentVault.completeEpochDeposit();
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_NoEpochHasCompleted() public {
        _changePrank(i_epochOperator);
        vm.expectRevert(IParentVault.ParentVault__NoCompletedEpoch.selector);
        s_parentVault.completeEpochDeposit();
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_PreviousEpochIsNotNetDeposit() public {
        _prepareExecutingNetWithdraw();

        _changePrank(i_epochOperator);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotNetDeposit.selector, 1));
        s_parentVault.completeEpochDeposit();
    }

    function test_ParentVault_completeEpochDeposit_RevertWhen_PreviousEpochIsNotExecuting() public {
        _prepareExecutingNetDeposit();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit();

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotExecuting.selector, 1));
        s_parentVault.completeEpochDeposit();
    }

    function test_ParentVault_completeEpochDeposit_Success_MarksPreviousEpochClaimable() public {
        _prepareExecutingNetDeposit();

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit();

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_completeEpochDeposit_Success_EmitsEpochClaimable() public {
        _prepareExecutingNetDeposit();

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit();

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_ParentVault_completeEpochDeposit_Success_WhenPaused() public {
        _prepareExecutingNetDeposit();
        _changePrank(i_pauser);
        s_parentVault.pause();

        _changePrank(i_epochOperator);
        s_parentVault.completeEpochDeposit();

        assertEq(uint8(s_parentVault.getEpoch(1).status), uint8(Types.EpochStatus.CLAIMABLE));
    }

    function _prepareExecutingNetDeposit() internal {
        _prepareRemoteStrategy();
        _changePrank(i_depositor);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(TVL);
    }

    function _prepareExecutingNetWithdraw() internal {
        _prepareRemoteStrategy();
        _setParentTotalShares(YIELD_PRECISION);
        _submitParentWithdraw(YIELD_PRECISION);
        _warpPastMinEpoch();
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(TVL);
    }

    function _prepareRemoteStrategy() internal {
        _clearParentActiveAdapter();
        _setParentActiveStrategy(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
    }

    function _warpPastMinEpoch() internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
    }
}
