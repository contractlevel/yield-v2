// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkTest} from "../../BaseForkTest.t.sol";
import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseAaveV3ForkTest is BaseForkTest {
    function _assertAaveV3DepositRevertsWhenCallerIsNotVault(AaveV3Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.deposit(DEPOSIT_AMOUNT);
    }

    function _assertAaveV3DepositSucceeds(AaveV3Adapter adapter, address vault, address usdc) internal {
        uint256 tvlBefore = adapter.getTVL();

        _depositToAaveV3(adapter, vault, usdc, DEPOSIT_AMOUNT);

        assertEq(IERC20(usdc).balanceOf(address(adapter)), 0);
        assertApproxEqAbs(adapter.getTVL(), tvlBefore + DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
    }

    function _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(AaveV3Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function _assertAaveV3EpochWithdrawSucceeds(AaveV3Adapter adapter, address vault, address usdc) internal {
        _depositToAaveV3(adapter, vault, usdc, DEPOSIT_AMOUNT + WITHDRAW_AMOUNT);

        uint256 tvlBefore = adapter.getTVL();
        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLt(adapter.getTVL(), tvlBefore);
    }

    function _assertAaveV3RebalanceWithdrawSucceeds(AaveV3Adapter adapter, address vault, address usdc) internal {
        _depositToAaveV3(adapter, vault, usdc, DEPOSIT_AMOUNT);

        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(type(uint256).max);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertApproxEqAbs(actualAmount, DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLe(adapter.getTVL(), PROTOCOL_FORK_TOLERANCE);
    }

    function _depositToAaveV3(AaveV3Adapter adapter, address vault, address usdc, uint256 amount) internal {
        deal(usdc, address(adapter), amount);
        _changePrank(vault);

        vm.recordLogs();
        adapter.deposit(amount);

        assertEq(uint256(_assertEmittedBy(keccak256("Deposit(uint256)"), address(adapter)).topics[1]), amount);
    }

    function test_baseAaveV3ForkTest() public virtual {}
}
