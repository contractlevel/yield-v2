// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

import {AllowlistHarness} from "../../mocks/AllowlistHarness.sol";

abstract contract BaseAllowlistUnitTest is BaseTest {
    AllowlistHarness internal s_allowlist;

    constructor() {
        s_allowlist = new AllowlistHarness(i_owner, i_allowlistOperator);
    }

    function _setAllowlistedUser(address user, bool allowed) internal {
        address[] memory users = new address[](1);
        users[0] = user;
        s_allowlist.setAllowlistedUsers(users, allowed);
    }
}
