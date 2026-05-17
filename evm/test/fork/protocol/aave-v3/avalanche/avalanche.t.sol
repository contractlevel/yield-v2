// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../BaseAaveV3ForkTest.t.sol";

contract Avalanche_AaveV3ForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_aaveV3_ConfiguresAdapter() external view {
        _assertAaveV3ForkAdapter(
            avalancheChild.adapterRegistry,
            avalancheChild.aaveV3Adapter,
            avalancheConfig,
            address(avalancheChild.vault),
            avalancheChild.usdc
        );
    }
}
