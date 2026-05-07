// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3AdapterUnitTest, Vm} from "../BaseAaveV3AdapterUnitTest.t.sol";

import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract AaveV3Adapter_WithdrawUnitTest is BaseAaveV3AdapterUnitTest {
    uint256 internal constant TVL = 1000 * 1e6;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;
    uint256 internal constant INSUFFICIENT_AMOUNT = 900 * 1e6;

    function setUp() public {
        _changePrank(address(s_parentVault));
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV3Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_RebalanceWithdrawAmountIsLessThanTVL() external {
        deal(address(s_mockAToken), address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), INSUFFICIENT_AMOUNT);
        s_mockAaveV3Pool.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(AaveV3Adapter.AaveV3Adapter__IncorrectWithdrawAmount.selector);
        s_aaveV3Adapter.withdraw(type(uint256).max);
    }

    function test_AaveV3Adapter_withdraw_Success_RebalanceWithdraw() external {
        deal(address(s_mockAToken), address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), TVL);
        s_mockAaveV3Pool.setWithdrawReturn(TVL);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV3Adapter.withdraw(type(uint256).max);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), TVL);
        assertEq(actualAmount, TVL);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), TVL);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_UserWithdrawAmountIsLessThanRequested() external {
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), INSUFFICIENT_AMOUNT);
        s_mockAaveV3Pool.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(AaveV3Adapter.AaveV3Adapter__IncorrectWithdrawAmount.selector);
        s_aaveV3Adapter.withdraw(TVL);
    }

    function test_AaveV3Adapter_withdraw_Success_UserWithdraw() external {
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), WITHDRAW_AMOUNT);
        s_mockAaveV3Pool.setWithdrawReturn(WITHDRAW_AMOUNT);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV3Adapter.withdraw(WITHDRAW_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), WITHDRAW_AMOUNT);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT);
    }
}
