// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../BaseUnitTest.t.sol";

import {AaveV4Adapter} from "../../../src/modules/adapters/AaveV4Adapter.sol";
import {MockAaveV4Spoke} from "../../mocks/MockAaveV4Spoke.sol";

abstract contract BaseAaveV4AdapterUnitTest is BaseUnitTest {
    MockAaveV4Spoke internal s_mockAaveV4Spoke;
    AaveV4Adapter internal s_aaveV4Adapter;

    constructor() {
        s_mockAaveV4Spoke = new MockAaveV4Spoke(address(s_mockUsdc));
        s_aaveV4Adapter = new AaveV4Adapter(address(s_parentVault), address(s_mockUsdc), address(s_mockAaveV4Spoke));

        vm.label(address(s_mockAaveV4Spoke), "MockAaveV4Spoke");
        vm.label(address(s_aaveV4Adapter), "AaveV4Adapter");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}
}
