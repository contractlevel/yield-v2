// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract YieldcoinShare_PausedTokenOperationsUnitTest is BaseUnitTest {
    uint256 internal constant AMOUNT = 10e18;

    modifier givenOwnerHasShares() {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_owner, AMOUNT);
        _;
    }

    function test_YieldcoinShare_transfer_RevertWhen_Paused()
        external
        givenOwnerHasShares
        givenContractIsPaused(address(s_yieldcoin))
    {
        _changePrank(i_owner);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        s_yieldcoin.transfer(i_recipient1, AMOUNT);
    }

    function test_YieldcoinShare_mint_RevertWhen_Paused() external givenContractIsPaused(address(s_yieldcoin)) {
        _changePrank(address(s_parentVault));
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        s_yieldcoin.mint(i_recipient1, AMOUNT);
    }

    function test_YieldcoinShare_transferFrom_RevertWhen_Paused()
        external
        givenOwnerHasShares
        givenContractIsPaused(address(s_yieldcoin))
    {
        _changePrank(i_owner);
        s_yieldcoin.approve(i_nonOwner, AMOUNT);
        _changePrank(i_nonOwner);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        s_yieldcoin.transferFrom(i_owner, i_recipient1, AMOUNT);
    }

    function test_YieldcoinShare_burn_RevertWhen_Paused()
        external
        givenOwnerHasShares
        givenContractIsPaused(address(s_yieldcoin))
    {
        _changePrank(address(s_parentVault));
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        s_yieldcoin.burn(i_owner, AMOUNT);
    }

    function test_YieldcoinShare_approve_SuccessWhenPaused() external givenContractIsPaused(address(s_yieldcoin)) {
        _changePrank(i_owner);
        assertTrue(s_yieldcoin.approve(i_nonOwner, AMOUNT));
        assertEq(s_yieldcoin.allowance(i_owner, i_nonOwner), AMOUNT);
    }
}
