// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../BaseAaveV3ForkTest.t.sol";

contract Base_AaveV3ForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_aaveV3_ConfiguresAdapter() external view {
        _assertAaveV3ForkAdapter(
            baseChild.adapterRegistry, baseChild.aaveV3Adapter, baseConfig, address(baseChild.vault), baseChild.usdc
        );
    }
}
