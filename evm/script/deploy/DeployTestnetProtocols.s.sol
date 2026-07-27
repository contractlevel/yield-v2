// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {TestnetAaveV3Pool} from "../../test/mocks/testnet/TestnetAaveV3Pool.sol";
import {TestnetAaveV3PoolAddressesProvider} from "../../test/mocks/testnet/TestnetAaveV3PoolAddressesProvider.sol";
import {TestnetAaveV4Spoke} from "../../test/mocks/testnet/TestnetAaveV4Spoke.sol";
import {TestnetComet} from "../../test/mocks/testnet/TestnetComet.sol";
import {TestnetCometRewards} from "../../test/mocks/testnet/TestnetCometRewards.sol";

/// @title DeployTestnetProtocols Script
/// @author @contractlevel
/// @notice Deploys the protocol mocks supported on the active testnet
contract DeployTestnetProtocols is Script {
    error DeployTestnetProtocols__UnsupportedChain(uint256 chainId);

    struct Deployment {
        address asset;
        TestnetAaveV3Pool aaveV3Pool;
        TestnetAaveV3PoolAddressesProvider aaveV3PoolAddressesProvider;
        TestnetAaveV4Spoke aaveV4Spoke;
        TestnetComet compoundV3Comet;
        TestnetCometRewards compoundV3CometRewards;
    }

    function run() external returns (Deployment memory deploy) {
        HelperConfig.NetworkConfig memory networkConfig = new HelperConfig().getActiveNetworkConfig();
        address deployer = msg.sender;

        vm.startBroadcast(deployer);
        deploy = deployForChain(block.chainid, networkConfig.tokens.usdc, deployer);
        vm.stopBroadcast();
    }

    function deployForChain(uint256 chainId, address asset, address owner) public returns (Deployment memory deploy) {
        bool deployAaveV3;
        bool deployAaveV4;
        bool deployCompoundV3;

        if (chainId == 421614) {
            // Arbitrum Sepolia
            deployAaveV3 = true;
            deployCompoundV3 = true;
        } else if (chainId == 11155111) {
            // Ethereum Sepolia
            deployAaveV3 = true;
            deployAaveV4 = true;
            deployCompoundV3 = true;
        } else if (chainId == 84532) {
            // Base Sepolia
            deployAaveV3 = true;
            deployCompoundV3 = true;
        } else if (chainId == 11155420) {
            // Optimism Sepolia
            deployAaveV3 = true;
            deployCompoundV3 = true;
        } else if (chainId == 43113) {
            // Avalanche Fuji
            deployAaveV3 = true;
            deployAaveV4 = true;
        } else {
            revert DeployTestnetProtocols__UnsupportedChain(chainId);
        }

        deploy.asset = asset;

        if (deployAaveV3) {
            deploy.aaveV3Pool = new TestnetAaveV3Pool(asset, owner);
            deploy.aaveV3PoolAddressesProvider = new TestnetAaveV3PoolAddressesProvider(address(deploy.aaveV3Pool));
        }

        if (deployAaveV4) deploy.aaveV4Spoke = new TestnetAaveV4Spoke(asset, owner);

        if (deployCompoundV3) {
            deploy.compoundV3Comet = new TestnetComet(asset, owner);
            deploy.compoundV3CometRewards = new TestnetCometRewards();
        }
    }
}
