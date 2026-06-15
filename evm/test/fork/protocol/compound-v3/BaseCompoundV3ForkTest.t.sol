// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseForkTest} from "../../BaseForkTest.t.sol";
import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseCompoundV3ForkTest is BaseForkTest {
    function _assertCompoundV3DepositRevertsWhenCallerIsNotVault(CompoundV3Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.deposit(DEPOSIT_AMOUNT);
    }

    function _assertCompoundV3DepositSucceeds(CompoundV3Adapter adapter, address vault, address usdc) internal {
        uint256 tvlBefore = adapter.getTVL();

        _depositToCompoundV3(adapter, vault, usdc, DEPOSIT_AMOUNT);

        assertEq(IERC20(usdc).balanceOf(address(adapter)), 0);
        assertApproxEqAbs(adapter.getTVL(), tvlBefore + DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
    }

    function _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(CompoundV3Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function _assertCompoundV3EpochWithdrawRevertsWhenAmountExceedsTVL(CompoundV3Adapter adapter, address vault)
        internal
    {
        _changePrank(vault);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__WithdrawAmountExceedsTotalValue.selector);
        adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function _assertCompoundV3EpochWithdrawSucceeds(CompoundV3Adapter adapter, address vault, address usdc) internal {
        _depositToCompoundV3(adapter, vault, usdc, DEPOSIT_AMOUNT + WITHDRAW_AMOUNT);

        uint256 tvlBefore = adapter.getTVL();
        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLt(adapter.getTVL(), tvlBefore);
    }

    function _assertCompoundV3RebalanceWithdrawSucceeds(CompoundV3Adapter adapter, address vault, address usdc)
        internal
    {
        _depositToCompoundV3(adapter, vault, usdc, DEPOSIT_AMOUNT);

        uint256 vaultBalanceBefore = IERC20(usdc).balanceOf(vault);

        vm.recordLogs();
        uint256 actualAmount = adapter.withdraw(type(uint256).max);

        assertEq(uint256(_assertEmittedBy(keccak256("Withdraw(uint256)"), address(adapter)).topics[1]), actualAmount);
        assertApproxEqAbs(actualAmount, DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(IERC20(usdc).balanceOf(vault), vaultBalanceBefore + actualAmount);
        assertLe(adapter.getTVL(), PROTOCOL_FORK_TOLERANCE);
    }

    function _depositToCompoundV3(CompoundV3Adapter adapter, address vault, address usdc, uint256 amount) internal {
        deal(usdc, address(adapter), amount);
        _changePrank(vault);

        vm.recordLogs();
        adapter.deposit(amount);

        assertEq(uint256(_assertEmittedBy(keccak256("Deposit(uint256)"), address(adapter)).topics[1]), amount);
    }

    function _assertCompoundV3ClaimRewardsRevertsWhenCallerIsNotRewardsOperator(CompoundV3Adapter adapter) internal {
        _changePrank(i_nonOwner);

        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__CallerNotRewardsOperator.selector);
        adapter.claimRewards(i_nonOwner);
    }

    function _assertCompoundV3ClaimRewardsSucceeds(CompoundV3Adapter adapter, address vault, address deployer)
        internal
    {
        address operator = makeAddr("forkRewardsOperator");

        _changePrank(deployer);
        IAccessControl(vault).grantRole(Roles.REWARDS_OPERATOR_ROLE, operator);

        vm.recordLogs();
        _changePrank(operator);
        adapter.claimRewards(operator);

        assertEq(
            address(
                uint160(uint256(_assertEmittedBy(keccak256("RewardsClaimed(address)"), address(adapter)).topics[1]))
            ),
            operator
        );
    }

    function test_baseCompoundV3ForkTest() public virtual {}
}
