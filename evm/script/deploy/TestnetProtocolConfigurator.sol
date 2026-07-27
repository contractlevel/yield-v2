// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperConfig} from "../HelperConfig.s.sol";
import {TestnetProtocolAccess} from "../../test/mocks/testnet/TestnetProtocolAccess.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

library TestnetProtocolConfigurator {
    function authorizeAdapters(
        HelperConfig.ProtocolsConfig memory protocols,
        address aaveV3Adapter,
        address aaveV4Adapter,
        address compoundV3Adapter
    ) internal {
        if (!_isTestnet(block.chainid)) return;

        if (protocols.aaveV3PoolAddressesProvider != address(0) && aaveV3Adapter != address(0)) {
            address pool = IPoolAddressesProvider(protocols.aaveV3PoolAddressesProvider).getPool();
            TestnetProtocolAccess(pool).setAllowedCaller(aaveV3Adapter, true);
        }

        if (protocols.aaveV4Spoke != address(0) && aaveV4Adapter != address(0)) {
            TestnetProtocolAccess(protocols.aaveV4Spoke).setAllowedCaller(aaveV4Adapter, true);
        }

        if (protocols.compoundV3Comet != address(0) && compoundV3Adapter != address(0)) {
            TestnetProtocolAccess(protocols.compoundV3Comet).setAllowedCaller(compoundV3Adapter, true);
        }
    }

    function _isTestnet(uint256 chainId) private pure returns (bool) {
        return chainId == 421614 || chainId == 11155111 || chainId == 84532 || chainId == 11155420 || chainId == 43113;
    }
}
