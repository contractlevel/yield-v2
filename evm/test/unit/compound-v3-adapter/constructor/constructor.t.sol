// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3AdapterUnitTest} from "../BaseCompoundV3AdapterUnitTest.t.sol";

contract CompoundV3Adapter_ConstructorUnitTest is BaseCompoundV3AdapterUnitTest {
    function test_CompoundV3Adapter_constructor_SetsComet() public view {
        assertEq(s_compoundV3Adapter.getVault(), address(s_parentVault));
        assertEq(s_compoundV3Adapter.getAsset(), address(s_mockUsdc));
        assertEq(s_compoundV3Adapter.getProtocolPool(), address(s_mockComet));
        assertEq(s_compoundV3Adapter.getCometRewards(), address(s_mockCometRewards));
        assertEq(s_compoundV3Adapter.getTVL(), 0);
    }
}
