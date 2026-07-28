// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";

contract SetCrosschainVaults is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory activeConfig = helperConfig.getActiveNetworkConfig();
        require(activeConfig.deployed.vaultProxy != address(0), "Vault proxy not configured");

        HelperConfig.NetworkConfig[5] memory configs;
        configs[0] = helperConfig.getArbitrumSepoliaConfig();
        configs[1] = helperConfig.getEthereumSepoliaConfig();
        configs[2] = helperConfig.getBaseSepoliaConfig();
        configs[3] = helperConfig.getOptimismSepoliaConfig();
        configs[4] = helperConfig.getAvalancheFujiConfig();

        uint64[] memory chainSelectors = new uint64[](4);
        address[] memory vaults = new address[](4);
        uint256 index;

        for (uint256 i; i < configs.length; ++i) {
            if (configs[i].ccip.thisChainSelector == activeConfig.ccip.thisChainSelector) continue;

            chainSelectors[index] = configs[i].ccip.thisChainSelector;
            vaults[index] = configs[i].deployed.vaultProxy;
            unchecked {
                ++index;
            }
        }

        vm.broadcast(msg.sender);
        IBaseVault(activeConfig.deployed.vaultProxy).setCrosschainVaults(chainSelectors, vaults);
    }
}
