// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest, Vm} from "../BaseAaveV4AdapterUnitTest.t.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {IAaveV4Spoke} from "../../../../src/interfaces/IAaveV4Spoke.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        UnderpayingAaveV4Spoke underpayingSpoke =
            new UnderpayingAaveV4Spoke(address(s_mockUsdc), TVL, INSUFFICIENT_AMOUNT);
        AaveV4Adapter adapter = new AaveV4Adapter(address(s_parentVault), address(s_mockUsdc), address(underpayingSpoke));
        deal(address(s_mockUsdc), address(underpayingSpoke), INSUFFICIENT_AMOUNT);

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__IncorrectWithdrawAmount.selector);
        adapter.withdraw(type(uint256).max);
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

contract UnderpayingAaveV4Spoke {
    address internal immutable i_underlying;
    uint256 internal immutable i_tvl;
    uint256 internal immutable i_withdrawReturn;

    constructor(address underlying, uint256 tvl, uint256 withdrawReturn) {
        i_underlying = underlying;
        i_tvl = tvl;
        i_withdrawReturn = withdrawReturn;
    }

    function withdraw(uint256, uint256, address) external returns (uint256, uint256) {
        IERC20(i_underlying).transfer(msg.sender, i_withdrawReturn);
        return (i_withdrawReturn, i_withdrawReturn);
    }

    function getUserSuppliedAssets(uint256, address) external view returns (uint256) {
        return i_tvl;
    }

    function getReserveCount() external pure returns (uint256) {
        return 1;
    }

    function getReserve(uint256) external view returns (IAaveV4Spoke.Reserve memory reserve) {
        reserve.underlying = i_underlying;
    }
}
