// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest, Vm} from "../BaseAaveV4AdapterUnitTest.t.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract AaveV4Adapter_WithdrawUnitTest is BaseAaveV4AdapterUnitTest {
    uint256 internal constant TVL = 1000 * 1e6;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;
    uint256 internal constant INSUFFICIENT_AMOUNT = 400 * 1e6;
    uint256 internal constant EXCESS_AMOUNT = 600 * 1e6;

    function setUp() public {
        _changePrank(address(s_parentVault));
    }

    function test_AaveV4Adapter_withdraw_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV4Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_AaveV4Adapter_withdraw_RevertWhen_RebalanceWithdrawAmountIsLessThanTVL() external {
        s_mockAaveV4Spoke.setUserSuppliedAssets(s_aaveV4Adapter.getReserveId(), address(s_aaveV4Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV4Spoke), INSUFFICIENT_AMOUNT);
        s_mockAaveV4Spoke.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__IncorrectWithdrawAmount.selector);
        s_aaveV4Adapter.withdraw(type(uint256).max);
    }

    function test_AaveV4Adapter_withdraw_Success_RebalanceWithdraw() external {
        s_mockAaveV4Spoke.setUserSuppliedAssets(s_aaveV4Adapter.getReserveId(), address(s_aaveV4Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV4Spoke), TVL);
        s_mockAaveV4Spoke.setWithdrawReturn(TVL);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV4Adapter.withdraw(type(uint256).max);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), TVL);
        assertEq(actualAmount, TVL);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), TVL);
    }

    function test_AaveV4Adapter_withdraw_RevertWhen_EpochWithdrawAmountIsLessThanRequested() external {
        deal(address(s_mockUsdc), address(s_mockAaveV4Spoke), INSUFFICIENT_AMOUNT);
        s_mockAaveV4Spoke.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__IncorrectWithdrawAmount.selector);
        s_aaveV4Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_AaveV4Adapter_withdraw_Success_EpochWithdraw() external {
        deal(address(s_mockUsdc), address(s_mockAaveV4Spoke), WITHDRAW_AMOUNT);
        s_mockAaveV4Spoke.setWithdrawReturn(WITHDRAW_AMOUNT);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV4Adapter.withdraw(WITHDRAW_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), WITHDRAW_AMOUNT);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT);
    }

    function test_AaveV4Adapter_withdraw_Success_EpochWithdraw_WhenAmountIsGreaterThanRequested() external {
        deal(address(s_mockUsdc), address(s_mockAaveV4Spoke), EXCESS_AMOUNT);
        s_mockAaveV4Spoke.setWithdrawReturn(EXCESS_AMOUNT);

        uint256 actualAmount = s_aaveV4Adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(actualAmount, EXCESS_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), EXCESS_AMOUNT);
    }
}
