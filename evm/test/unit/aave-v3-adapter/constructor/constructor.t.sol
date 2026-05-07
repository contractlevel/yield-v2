// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3AdapterUnitTest} from "../BaseAaveV3AdapterUnitTest.t.sol";

contract AaveV3Adapter_ConstructorUnitTest is BaseAaveV3AdapterUnitTest {
    function test_AaveV3Adapter_constructor_SetsPoolAddressesProvider() public {
        assertEq(s_aaveV3Adapter.getPoolAddressesProvider(), address(s_mockPoolAddressesProvider));
        assertEq(s_aaveV3Adapter.getProtocolPool(), s_mockPoolAddressesProvider.getPool());
        assertEq(s_aaveV3Adapter.getTVL(), 0);
    }
}
