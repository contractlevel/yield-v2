// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "./BaseAaveV3ForkTest.t.sol";

contract Arbitrum_AaveV3ForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_aaveV3_ConfiguresAdapter() external view {
        _assertAaveV3ForkAdapter(
            parent.adapterRegistry, parent.aaveV3Adapter, arbitrumConfig, address(parent.vault), parent.usdc
        );
    }
}
