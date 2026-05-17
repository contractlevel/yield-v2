// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "./BaseAaveV3ForkTest.t.sol";

contract Ethereum_AaveV3ForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_aaveV3_ConfiguresAdapter() external view {
        _assertAaveV3ForkAdapter(
            ethereumChild.adapterRegistry,
            ethereumChild.aaveV3Adapter,
            ethereumConfig,
            address(ethereumChild.vault),
            ethereumChild.usdc
        );
    }
}
