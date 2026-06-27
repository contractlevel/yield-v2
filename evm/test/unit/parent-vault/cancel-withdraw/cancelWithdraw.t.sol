// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CancelWithdrawUnitTest is BaseUnitTest {
    uint256 internal constant SHARE_BURN_AMOUNT = 100 * 1e6;

    function setUp() public {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_withdrawer, SHARE_BURN_AMOUNT);

        _changePrank(i_withdrawer);
        s_yieldcoin.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.withdraw(SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_cancelWithdraw_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.cancelWithdraw();
    }

    function test_ParentVault_cancelWithdraw_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.cancelWithdraw();
    }

    function test_ParentVault_cancelWithdraw_RevertWhen_NoWithdraw() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_nonOwner, 1));
        s_parentVault.cancelWithdraw();
    }

    function test_ParentVault_cancelWithdraw_Success_TransfersShares() public {
        uint256 vaultBefore = s_yieldcoin.balanceOf(address(s_parentVault));
        uint256 withdrawerBefore = s_yieldcoin.balanceOf(i_withdrawer);
        s_parentVault.cancelWithdraw();
        assertEq(s_yieldcoin.balanceOf(address(s_parentVault)), vaultBefore - SHARE_BURN_AMOUNT);
        assertEq(s_yieldcoin.balanceOf(i_withdrawer), withdrawerBefore + SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_cancelWithdraw_Success_DeletesWithdrawMapping() public {
        s_parentVault.cancelWithdraw();
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 1), 0);
    }

    function test_ParentVault_cancelWithdraw_Success_UpdatesEpochTotal() public {
        s_parentVault.cancelWithdraw();
        assertEq(s_parentVault.getEpoch(1).totalShareBurnAmount, 0);
    }

    function test_ParentVault_cancelWithdraw_Success_EmitsWithdrawCancelled() public {
        vm.recordLogs();
        s_parentVault.cancelWithdraw();
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawCancelled(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_withdrawer);
        assertEq(uint256(log.topics[3]), SHARE_BURN_AMOUNT);
    }
}
