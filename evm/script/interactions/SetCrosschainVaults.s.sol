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

        HelperConfig.NetworkConfig[6] memory configs = _getNetworkConfigs(helperConfig);

        uint64[] memory chainSelectors = new uint64[](5);
        address[] memory vaults = new address[](5);
        uint256 index;

        for (uint256 i; i < configs.length; ++i) {
            if (configs[i].ccip.thisChainSelector == activeConfig.ccip.thisChainSelector) continue;
            require(configs[i].deployed.vaultProxy != address(0), "Crosschain vault proxy not configured");

            chainSelectors[index] = configs[i].ccip.thisChainSelector;
            vaults[index] = configs[i].deployed.vaultProxy;
            unchecked {
                ++index;
            }
        }

        vm.broadcast(msg.sender);
        IBaseVault(activeConfig.deployed.vaultProxy).setCrosschainVaults(chainSelectors, vaults);
    }

    function _getNetworkConfigs(HelperConfig helperConfig)
        private
        view
        returns (HelperConfig.NetworkConfig[6] memory configs)
    {
        if (_isMainnet()) {
            configs[0] = helperConfig.getArbitrumConfig();
            configs[1] = helperConfig.getEthereumConfig();
            configs[2] = helperConfig.getBaseConfig();
            configs[3] = helperConfig.getOptimismConfig();
            configs[4] = helperConfig.getAvalancheConfig();
            configs[5] = helperConfig.getPolygonConfig();
        } else {
            configs[0] = helperConfig.getArbitrumSepoliaConfig();
            configs[1] = helperConfig.getEthereumSepoliaConfig();
            configs[2] = helperConfig.getBaseSepoliaConfig();
            configs[3] = helperConfig.getOptimismSepoliaConfig();
            configs[4] = helperConfig.getAvalancheFujiConfig();
            configs[5] = helperConfig.getPolygonAmoyConfig();
        }
    }

    function _isMainnet() private view returns (bool) {
        return block.chainid == 1 || block.chainid == 10 || block.chainid == 137 || block.chainid == 8453
            || block.chainid == 42161 || block.chainid == 43114;
    }
}
