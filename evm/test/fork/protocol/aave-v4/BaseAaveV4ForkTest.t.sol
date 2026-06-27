// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkTest} from "../../BaseForkTest.t.sol";
import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseAaveV4ForkTest is BaseForkTest {
    function _assertAaveV4DepositRevertsWhenCallerIsNotVault(AaveV4Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.deposit(DEPOSIT_AMOUNT);
    }

    function _assertAaveV4DepositSucceeds(AaveV4Adapter adapter, address vault, address usdc) internal {
        uint256 tvlBefore = adapter.getTVL();

        _depositToAaveV4(adapter, vault, usdc, DEPOSIT_AMOUNT);

        assertEq(IERC20(usdc).balanceOf(address(adapter)), 0);
        assertApproxEqAbs(adapter.getTVL(), tvlBefore + DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
    }

    function _assertAaveV4WithdrawRevertsWhenCallerIsNotVault(AaveV4Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function _assertAaveV4EpochWithdrawSucceeds(AaveV4Adapter adapter, address vault, address usdc) internal {
        _depositToAaveV4(adapter, vault, usdc, DEPOSIT_AMOUNT + WITHDRAW_AMOUNT);

        uint256 tvlBefore = adapter.getTVL();
        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLt(adapter.getTVL(), tvlBefore);
    }

    function _assertAaveV4RebalanceWithdrawSucceeds(AaveV4Adapter adapter, address vault, address usdc) internal {
        _depositToAaveV4(adapter, vault, usdc, DEPOSIT_AMOUNT);

        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(type(uint256).max);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertApproxEqAbs(actualAmount, DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLe(adapter.getTVL(), PROTOCOL_FORK_TOLERANCE);
    }

    function _depositToAaveV4(AaveV4Adapter adapter, address vault, address usdc, uint256 amount) internal {
        deal(usdc, address(adapter), amount);
        _changePrank(vault);

        vm.recordLogs();
        adapter.deposit(amount);

        assertEq(uint256(_assertEmittedBy(keccak256("Deposit(uint256)"), address(adapter)).topics[1]), amount);
    }

    function test_baseAaveV4ForkTest() public virtual {}
}
