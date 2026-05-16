// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../BaseUnitTest.t.sol";

import {CompoundV3Adapter} from "../../../src/modules/adapters/CompoundV3Adapter.sol";
import {MockComet} from "../../mocks/MockComet.sol";

abstract contract BaseCompoundV3AdapterUnitTest is BaseUnitTest {
    MockComet internal s_mockComet;
    CompoundV3Adapter internal s_compoundV3Adapter;

    constructor() {
        s_mockComet = new MockComet();
        s_compoundV3Adapter = new CompoundV3Adapter(address(s_parentVault), address(s_mockUsdc), address(s_mockComet));

        vm.label(address(s_mockComet), "MockComet");
        vm.label(address(s_compoundV3Adapter), "CompoundV3Adapter");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}
}
