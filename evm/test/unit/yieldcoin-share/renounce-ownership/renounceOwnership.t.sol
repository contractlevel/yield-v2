// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";

contract YieldcoinShare_RenounceOwnershipUnitTest is BaseUnitTest {
    function test_YieldcoinShare_renounceOwnership_RevertWhen_CalledByOwner() external {
        _changePrank(i_upgrader);
        vm.expectRevert(YieldcoinShare.YieldcoinShare__CannotRenounceOwnership.selector);
        s_yieldcoin.renounceOwnership();
    }

    function test_YieldcoinShare_renounceOwnership_RevertWhen_CalledByNonOwner() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(YieldcoinShare.YieldcoinShare__CannotRenounceOwnership.selector);
        s_yieldcoin.renounceOwnership();
    }
}
