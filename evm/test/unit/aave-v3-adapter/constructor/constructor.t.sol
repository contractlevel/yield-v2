// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3AdapterUnitTest} from "../BaseAaveV3AdapterUnitTest.t.sol";
import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract AaveV3Adapter_ConstructorUnitTest is BaseAaveV3AdapterUnitTest {
    function test_AaveV3Adapter_constructor_SetsPoolAddressesProvider() public view {
        assertEq(s_aaveV3Adapter.getPoolAddressesProvider(), address(s_mockPoolAddressesProvider));
        assertEq(s_aaveV3Adapter.getProtocolPool(), s_mockPoolAddressesProvider.getPool());
        assertEq(s_aaveV3Adapter.getTVL(), 0);
    }

    function test_AaveV3Adapter_constructor_RevertWhen_VaultIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new AaveV3Adapter(address(0), address(s_mockUsdc), address(s_mockPoolAddressesProvider));
    }

    function test_AaveV3Adapter_constructor_RevertWhen_AssetIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new AaveV3Adapter(address(s_parentVault), address(0), address(s_mockPoolAddressesProvider));
    }

    function test_AaveV3Adapter_constructor_RevertWhen_PoolAddressesProviderIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new AaveV3Adapter(address(s_parentVault), address(s_mockUsdc), address(0));
    }
}
