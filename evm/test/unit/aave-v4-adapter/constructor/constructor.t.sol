// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest} from "../BaseAaveV4AdapterUnitTest.t.sol";

contract AaveV4Adapter_ConstructorUnitTest is BaseAaveV4AdapterUnitTest {
    function test_AaveV4Adapter_constructor_SetsSpokeAndReserveId() public {
        assertEq(s_aaveV4Adapter.getProtocolPool(), address(s_mockAaveV4Spoke));
        assertEq(s_aaveV4Adapter.getReserveId(), RESERVE_ID);
        assertEq(s_aaveV4Adapter.getTVL(), 0);
    }
}
