// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract YieldcoinShare_MintUnitTest is BaseUnitTest {
    uint256 internal constant AMOUNT = 10e18;

    function test_YieldcoinShare_mint_RevertWhen_CallerLacksMinterRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.MINTER_ROLE
            )
        );
        s_yieldcoin.mint(i_recipient1, AMOUNT);
    }

    function test_YieldcoinShare_mint_RevertWhen_RecipientIsZeroAddress() external {
        _changePrank(address(s_parentVault));
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        s_yieldcoin.mint(address(0), AMOUNT);
    }

    function test_YieldcoinShare_mint_Success_UpdatesBalanceAndSupply() external {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_recipient1, AMOUNT);

        assertEq(s_yieldcoin.balanceOf(i_recipient1), AMOUNT);
        assertEq(s_yieldcoin.totalSupply(), AMOUNT);
    }

    function test_YieldcoinShare_mint_Success_EmitsTransfer() external {
        _changePrank(address(s_parentVault));
        vm.recordLogs();
        s_yieldcoin.mint(i_recipient1, AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Transfer(address,address,uint256)"), address(s_yieldcoin));
        assertEq(address(uint160(uint256(log.topics[1]))), address(0));
        assertEq(address(uint160(uint256(log.topics[2]))), i_recipient1);
        assertEq(abi.decode(log.data, (uint256)), AMOUNT);
    }
}
