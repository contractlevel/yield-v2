// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3AdapterUnitTest, Vm} from "../BaseCompoundV3AdapterUnitTest.t.sol";

import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract CompoundV3Adapter_WithdrawUnitTest is BaseCompoundV3AdapterUnitTest {
    uint256 internal constant TVL = 1000 * 1e6;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;
    uint256 internal constant INSUFFICIENT_AMOUNT = 400 * 1e6;
    uint256 internal constant EXCESS_AMOUNT = 600 * 1e6;

    function setUp() public {
        _changePrank(address(s_parentVault));
    }

    function test_CompoundV3Adapter_withdraw_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_CompoundV3Adapter_withdraw_RevertWhen_UserWithdrawAmountExceedsTVL() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), WITHDRAW_AMOUNT);

        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__WithdrawAmountExceedsTotalValue.selector);
        s_compoundV3Adapter.withdraw(TVL);
    }

    function test_CompoundV3Adapter_withdraw_RevertWhen_RebalanceWithdrawAmountIsLessThanTVL() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockComet), INSUFFICIENT_AMOUNT);
        s_mockComet.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__IncorrectWithdrawAmount.selector);
        s_compoundV3Adapter.withdraw(type(uint256).max);
    }

    function test_CompoundV3Adapter_withdraw_Success_RebalanceWithdraw() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockComet), TVL);
        s_mockComet.setWithdrawReturn(TVL);

        vm.recordLogs();
        uint256 actualAmount = s_compoundV3Adapter.withdraw(type(uint256).max);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_compoundV3Adapter));
        assertEq(uint256(log.topics[1]), TVL);
        assertEq(actualAmount, TVL);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), TVL);
    }

    function test_CompoundV3Adapter_withdraw_RevertWhen_UserWithdrawAmountIsLessThanRequested() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), WITHDRAW_AMOUNT);
        deal(address(s_mockUsdc), address(s_mockComet), INSUFFICIENT_AMOUNT);
        s_mockComet.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__IncorrectWithdrawAmount.selector);
        s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_CompoundV3Adapter_withdraw_Success_UserWithdraw() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), WITHDRAW_AMOUNT);
        deal(address(s_mockUsdc), address(s_mockComet), WITHDRAW_AMOUNT);
        s_mockComet.setWithdrawReturn(WITHDRAW_AMOUNT);

        vm.recordLogs();
        uint256 actualAmount = s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_compoundV3Adapter));
        assertEq(uint256(log.topics[1]), WITHDRAW_AMOUNT);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT);
    }

    function test_CompoundV3Adapter_withdraw_Success_UserWithdraw_WhenAmountIsGreaterThanRequested() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockComet), EXCESS_AMOUNT);
        s_mockComet.setWithdrawReturn(EXCESS_AMOUNT);

        uint256 actualAmount = s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(actualAmount, EXCESS_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), EXCESS_AMOUNT);
    }
}
