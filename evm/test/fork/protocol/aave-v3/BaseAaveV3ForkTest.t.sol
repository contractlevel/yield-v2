// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseForkTest} from "../../BaseForkTest.t.sol";
import {HelperConfig} from "../../../../script/HelperConfig.s.sol";
import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {AdapterRegistry} from "../../../../src/modules/AdapterRegistry.sol";

abstract contract BaseAaveV3ForkTest is BaseForkTest {
    function _assertAaveV3ForkAdapter(
        AdapterRegistry registry,
        AaveV3Adapter adapter,
        HelperConfig.NetworkConfig memory config,
        address vault,
        address usdc
    ) internal view {
        _assertOptionalAaveV3Adapter(registry, adapter, config.protocols.aaveV3PoolAddressesProvider, vault, usdc);

        if (config.protocols.aaveV3PoolAddressesProvider == address(0)) return;

        assertGt(config.protocols.aaveV3PoolAddressesProvider.code.length, 0);
        assertGt(adapter.getProtocolPool().code.length, 0);
    }

    function test_baseAaveV3ForkTest() public virtual {}
}
