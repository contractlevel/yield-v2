// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "./BaseAaveV3ForkTest.t.sol";

contract Optimism_AaveV3ForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_aaveV3_ConfiguresAdapter() external view {
        _assertAaveV3ForkAdapter(
            optimismChild.adapterRegistry,
            optimismChild.aaveV3Adapter,
            optimismConfig,
            address(optimismChild.vault),
            optimismChild.usdc
        );
    }
}
