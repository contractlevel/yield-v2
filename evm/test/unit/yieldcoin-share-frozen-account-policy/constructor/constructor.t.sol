// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {
    YieldcoinShareFrozenAccountPolicy
} from "../../../../src/modules/policies/YieldcoinShareFrozenAccountPolicy.sol";
import {
    IYieldcoinShareFrozenAccountPolicy
} from "../../../../src/interfaces/policies/IYieldcoinShareFrozenAccountPolicy.sol";

contract YieldcoinShareFrozenAccountPolicy_ConstructorUnitTest is BaseUnitTest {
    function test_YieldcoinShareFrozenAccountPolicy_constructor_RevertWhen_ShareIsZeroAddress() external {
        vm.expectRevert(IYieldcoinShareFrozenAccountPolicy.YieldcoinShareFrozenAccountPolicy__NoZeroAddress.selector);
        new YieldcoinShareFrozenAccountPolicy(address(0));
    }

    function test_YieldcoinShareFrozenAccountPolicy_constructor_Success() external {
        YieldcoinShareFrozenAccountPolicy policy = new YieldcoinShareFrozenAccountPolicy(address(s_yieldcoin));

        assertEq(policy.getShare(), address(s_yieldcoin));
    }
}
