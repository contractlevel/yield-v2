// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ParentVault_ForceCancelDepositUnitTest is BaseUnitTest {
    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        _changePrank(i_cancelDepositOperator);
    }

    function test_ParentVault_forceCancelDeposit_RevertWhen_CallerDoesNotHaveCANCEL_DEPOSIT_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CANCEL_DEPOSIT_OPERATOR_ROLE
            )
        );
        s_parentVault.forceCancelDeposit(i_depositor);
    }

    function test_ParentVault_forceCancelDeposit_RevertWhen_EpochNotOpen() external {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.forceCancelDeposit(i_depositor);
    }

    function test_ParentVault_forceCancelDeposit_RevertWhen_NoDeposit() external {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_nonOwner, 1));
        s_parentVault.forceCancelDeposit(i_nonOwner);
    }

    function test_ParentVault_forceCancelDeposit_Success_TransfersUsdc() external {
        uint256 vaultBefore = s_mockUsdc.balanceOf(address(s_parentVault));
        uint256 depositorBefore = s_mockUsdc.balanceOf(i_depositor);
        uint256 operatorBefore = s_mockUsdc.balanceOf(i_cancelDepositOperator);
        s_parentVault.forceCancelDeposit(i_depositor);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), vaultBefore - DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_depositor), depositorBefore + DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_cancelDepositOperator), operatorBefore);
    }

    function test_ParentVault_forceCancelDeposit_Success_DeletesDepositMapping() external {
        s_parentVault.forceCancelDeposit(i_depositor);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
    }

    function test_ParentVault_forceCancelDeposit_Success_UpdatesEpochTotal() external {
        s_parentVault.forceCancelDeposit(i_depositor);
        assertEq(s_parentVault.getEpoch(1).totalDepositAmount, 0);
    }

    function test_ParentVault_forceCancelDeposit_Success_EmitsDepositForceCancelled() external {
        vm.recordLogs();
        s_parentVault.forceCancelDeposit(i_depositor);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositForceCancelled(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_depositor);
        assertEq(uint256(log.topics[3]), DEPOSIT_AMOUNT);
    }
}
