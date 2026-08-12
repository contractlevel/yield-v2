// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract YieldcoinShare_BurnUnitTest is BaseUnitTest {
    uint256 internal constant AMOUNT = 10e18;

    modifier givenUserHasShares() {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_owner, AMOUNT);
        _;
    }

    function test_YieldcoinShare_burn_RevertWhen_CallerLacksBurnerRole() external givenUserHasShares {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.BURNER_ROLE
            )
        );
        s_yieldcoin.burn(i_owner, AMOUNT);
    }

    function test_YieldcoinShare_burn_RevertWhen_UserIsZeroAddress() external {
        _changePrank(address(s_parentVault));
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0)));
        s_yieldcoin.burn(address(0), AMOUNT);
    }

    function test_YieldcoinShare_burn_RevertWhen_BalanceIsInsufficient() external {
        _changePrank(address(s_parentVault));
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, i_owner, 0, AMOUNT));
        s_yieldcoin.burn(i_owner, AMOUNT);
    }

    function test_YieldcoinShare_burn_Success_UpdatesBalanceAndSupply() external givenUserHasShares {
        _changePrank(address(s_parentVault));
        s_yieldcoin.burn(i_owner, AMOUNT);

        assertEq(s_yieldcoin.balanceOf(i_owner), 0);
        assertEq(s_yieldcoin.totalSupply(), 0);
    }

    function test_YieldcoinShare_burn_Success_EmitsTransfer() external givenUserHasShares {
        _changePrank(address(s_parentVault));
        vm.recordLogs();
        s_yieldcoin.burn(i_owner, AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Transfer(address,address,uint256)"), address(s_yieldcoin));
        assertEq(address(uint160(uint256(log.topics[1]))), i_owner);
        assertEq(address(uint160(uint256(log.topics[2]))), address(0));
        assertEq(abi.decode(log.data, (uint256)), AMOUNT);
    }
}
