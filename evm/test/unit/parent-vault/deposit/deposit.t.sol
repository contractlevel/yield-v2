// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_DepositUnitTest is BaseUnitTest {
    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT * 2);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
    }

    function test_ParentVault_deposit_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.deposit(DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_RevertWhen_AmountTooSmall() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__AmountTooSmall.selector, DEPOSIT_AMOUNT - 1));
        s_parentVault.deposit(DEPOSIT_AMOUNT - 1);
    }

    function test_ParentVault_deposit_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.deposit(DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_Success_TransfersUsdc() public {
        uint256 vaultBefore = s_mockUsdc.balanceOf(address(s_parentVault));
        uint256 depositorBefore = s_mockUsdc.balanceOf(i_depositor);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), vaultBefore + DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_depositor), depositorBefore - DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_Success_UpdatesDepositMapping() public {
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_Success_UpdatesEpochTotal() public {
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getEpoch(1).totalDepositAmount, DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_Success_ReturnsEpochNonce() public {
        uint256 epochNonce = s_parentVault.deposit(DEPOSIT_AMOUNT);
        assertEq(epochNonce, 1);
    }

    function test_ParentVault_deposit_Success_EmitsDepositSubmitted() public {
        vm.recordLogs();
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositSubmitted(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_depositor);
        assertEq(uint256(log.topics[3]), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_Success_Accumulates() public {
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), DEPOSIT_AMOUNT * 2);
        assertEq(s_parentVault.getEpoch(1).totalDepositAmount, DEPOSIT_AMOUNT * 2);
    }
}
