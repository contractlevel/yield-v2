// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_DepositForUnitTest is BaseUnitTest {
    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT * 2);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
    }

    function test_ParentVault_depositFor_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_depositFor_RevertWhen_BeneficiaryIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_parentVault.depositFor(address(0), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_depositFor_RevertWhen_AmountTooSmall() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__AmountTooSmall.selector, DEPOSIT_AMOUNT - 1));
        s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT - 1);
    }

    function test_ParentVault_depositFor_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_depositFor_Success_SeparatesPayerAndBeneficiary() public {
        uint256 payerBefore = s_mockUsdc.balanceOf(i_depositor);
        uint256 beneficiaryBefore = s_mockUsdc.balanceOf(i_recipient1);

        uint256 epochNonce = s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT);

        assertEq(epochNonce, 1);
        assertEq(s_mockUsdc.balanceOf(i_depositor), payerBefore - DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_recipient1), beneficiaryBefore);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
        assertEq(s_parentVault.getDepositAmount(i_recipient1, 1), DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getEpoch(1).totalDepositAmount, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_depositFor_Success_EmitsBeneficiary() public {
        vm.recordLogs();
        s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositSubmitted(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_recipient1);
        assertEq(uint256(log.topics[3]), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_depositFor_Success_OnlyBeneficiaryCanCancelAndReceivesRefund() public {
        s_parentVault.depositFor(i_recipient1, DEPOSIT_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_depositor, 1));
        s_parentVault.cancelDeposit();

        uint256 beneficiaryBefore = s_mockUsdc.balanceOf(i_recipient1);
        _changePrank(i_recipient1);
        s_parentVault.cancelDeposit();
        assertEq(s_mockUsdc.balanceOf(i_recipient1), beneficiaryBefore + DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getDepositAmount(i_recipient1, 1), 0);
    }
}
