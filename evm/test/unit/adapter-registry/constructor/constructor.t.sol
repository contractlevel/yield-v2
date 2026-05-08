// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

contract AdapterRegistry_ConstructorUnitTest is BaseUnitTest {
    function test_AdapterRegistry_constructor() public view {
        assertEq(s_adapterRegistry.owner(), i_owner);
    }
}
