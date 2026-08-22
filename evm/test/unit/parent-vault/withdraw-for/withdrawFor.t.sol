// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_WithdrawForUnitTest is BaseUnitTest {
    uint256 internal constant SHARE_BURN_AMOUNT = 100 * YIELD_PRECISION;

    function setUp() public {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_withdrawer, SHARE_BURN_AMOUNT);
        _changePrank(i_withdrawer);
        s_yieldcoin.approve(address(s_parentVault), type(uint256).max);
    }

    function test_ParentVault_withdrawFor_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.withdrawFor(i_recipient1, SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_withdrawFor_RevertWhen_BeneficiaryIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_parentVault.withdrawFor(address(0), SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_withdrawFor_RevertWhen_BeneficiaryIsParentVault() public {
        vm.expectRevert(IParentVault.ParentVault__InvalidBeneficiary.selector);
        s_parentVault.withdrawFor(address(s_parentVault), SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_withdrawFor_RevertWhen_AmountIsZero() public {
        vm.expectRevert(IParentVault.ParentVault__NoZeroAmount.selector);
        s_parentVault.withdrawFor(i_recipient1, 0);
    }

    function test_ParentVault_withdrawFor_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.withdrawFor(i_recipient1, SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_withdrawFor_Success_SeparatesPayerAndBeneficiary() public {
        uint256 payerBefore = s_yieldcoin.balanceOf(i_withdrawer);
        uint256 beneficiaryBefore = s_yieldcoin.balanceOf(i_recipient1);

        uint256 epochNonce = s_parentVault.withdrawFor(i_recipient1, SHARE_BURN_AMOUNT);

        assertEq(epochNonce, 1);
        assertEq(s_yieldcoin.balanceOf(i_withdrawer), payerBefore - SHARE_BURN_AMOUNT);
        assertEq(s_yieldcoin.balanceOf(i_recipient1), beneficiaryBefore);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 1), 0);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_recipient1, 1), SHARE_BURN_AMOUNT);
        assertEq(s_parentVault.getEpoch(1).totalShareBurnAmount, SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_withdrawFor_Success_EmitsBeneficiary() public {
        vm.recordLogs();
        s_parentVault.withdrawFor(i_recipient1, SHARE_BURN_AMOUNT);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawSubmitted(uint256,address,uint256)"), address(s_parentVault));
        assertEq(address(uint160(uint256(log.topics[2]))), i_recipient1);
    }

    function test_ParentVault_withdrawFor_Success_OnlyBeneficiaryCanCancelAndReceivesRefund() public {
        s_parentVault.withdrawFor(i_recipient1, SHARE_BURN_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_withdrawer, 1));
        s_parentVault.cancelWithdraw();

        uint256 beneficiaryBefore = s_yieldcoin.balanceOf(i_recipient1);
        _changePrank(i_recipient1);
        s_parentVault.cancelWithdraw();
        assertEq(s_yieldcoin.balanceOf(i_recipient1), beneficiaryBefore + SHARE_BURN_AMOUNT);
    }
}
