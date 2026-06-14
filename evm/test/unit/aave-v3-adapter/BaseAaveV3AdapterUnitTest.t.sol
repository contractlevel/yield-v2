// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../BaseUnitTest.t.sol";

import {AaveV3Adapter} from "../../../src/modules/adapters/AaveV3Adapter.sol";
import {MockAToken} from "../../mocks/MockAToken.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";
import {MockAaveV3PoolAddressesProvider} from "../../mocks/MockAaveV3PoolAddressesProvider.sol";

abstract contract BaseAaveV3AdapterUnitTest is BaseUnitTest {
    MockAaveV3Pool internal s_mockAaveV3Pool;
    MockAaveV3PoolAddressesProvider internal s_mockPoolAddressesProvider;
    MockAToken internal s_mockAToken;
    AaveV3Adapter internal s_aaveV3Adapter;

    constructor() {
        s_mockAToken = new MockAToken();
        s_mockAaveV3Pool = new MockAaveV3Pool();
        s_mockAaveV3Pool.setATokenAddress(address(s_mockAToken));
        s_mockPoolAddressesProvider = new MockAaveV3PoolAddressesProvider(address(s_mockAaveV3Pool));
        s_aaveV3Adapter = new AaveV3Adapter(address(s_parentVault), address(s_mockPoolAddressesProvider));

        vm.label(address(s_mockAToken), "MockAToken");
        vm.label(address(s_mockAaveV3Pool), "MockAaveV3Pool");
        vm.label(address(s_mockPoolAddressesProvider), "MockAaveV3PoolAddressesProvider");
        vm.label(address(s_aaveV3Adapter), "AaveV3Adapter");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}
}
