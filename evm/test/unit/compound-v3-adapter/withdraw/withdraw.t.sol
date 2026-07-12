// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3AdapterUnitTest, Vm} from "../BaseCompoundV3AdapterUnitTest.t.sol";

import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function test_CompoundV3Adapter_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), WITHDRAW_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__WithdrawAmountExceedsTotalValue.selector);
        s_compoundV3Adapter.withdraw(TVL);
    }

    function test_CompoundV3Adapter_withdraw_RevertWhen_RebalanceWithdrawAmountIsLessThanTVL() external {
        UnderpayingComet underpayingComet = new UnderpayingComet(address(s_mockUsdc), TVL, INSUFFICIENT_AMOUNT);
        CompoundV3Adapter adapter =
            new CompoundV3Adapter(address(s_parentVault), address(underpayingComet), address(s_mockCometRewards));
        deal(address(s_mockUsdc), address(underpayingComet), INSUFFICIENT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        adapter.withdraw(type(uint256).max);
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

    function test_CompoundV3Adapter_withdraw_RevertWhen_EpochWithdrawAmountIsLessThanRequested() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), WITHDRAW_AMOUNT);
        deal(address(s_mockUsdc), address(s_mockComet), INSUFFICIENT_AMOUNT);
        s_mockComet.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_CompoundV3Adapter_withdraw_Success_EpochWithdraw() external {
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

    function test_CompoundV3Adapter_withdraw_Success_EpochWithdraw_WhenAmountIsGreaterThanRequested() external {
        s_mockComet.setBalance(address(s_compoundV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockComet), EXCESS_AMOUNT);
        s_mockComet.setWithdrawReturn(EXCESS_AMOUNT);

        uint256 actualAmount = s_compoundV3Adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(actualAmount, EXCESS_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), EXCESS_AMOUNT);
    }
}

contract UnderpayingComet {
    address internal immutable i_baseToken;
    uint256 internal immutable i_tvl;
    uint256 internal immutable i_withdrawReturn;

    constructor(address _baseToken, uint256 tvl, uint256 withdrawReturn) {
        i_baseToken = _baseToken;
        i_tvl = tvl;
        i_withdrawReturn = withdrawReturn;
    }

    function baseToken() external view returns (address) {
        return i_baseToken;
    }

    function withdraw(address asset, uint256) external {
        IERC20(asset).transfer(msg.sender, i_withdrawReturn);
    }

    function balanceOf(address) external view returns (uint256) {
        return i_tvl;
    }
}
