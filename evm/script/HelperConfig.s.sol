// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

import {MockLink} from "../test/mocks/MockLink.sol";
import {MockUSDC} from "../test/mocks/MockUSDC.sol";
import {MockCCIPRouter} from "../test/mocks/MockCCIPRouter.sol";
import {MockAaveV3Pool} from "../test/mocks/MockAaveV3Pool.sol";
import {MockAaveV3PoolAddressesProvider} from "../test/mocks/MockAaveV3PoolAddressesProvider.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                             NETWORK CONFIG
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address initialOwner;
        address treasury;
        address ccipRouter;
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address complianceOperator;
        uint64 thisChainSelector;
        TokensConfig tokens;
        ProtocolsConfig protocols;
    }

    struct TokensConfig {
        address link;
        address usdc;
    }

    struct ProtocolsConfig {
        address aaveV3PoolAddressesProvider;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        activeNetworkConfig = getOrCreateAnvilEthConfig();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory networkConfig) {
        address link = address(new MockLink());
        address usdc = address(new MockUSDC());

        address treasury = makeAddr("treasury");
        address ccipRouter = address(new MockCCIPRouter(address(usdc)));
        address defaultAdmin = makeAddr("defaultAdmin");
        address pauser = makeAddr("pauser");
        address unpauser = makeAddr("unpauser");
        address configOperator = makeAddr("configOperator");
        address complianceOperator = makeAddr("complianceOperator");

        address aaveV3Pool = address(new MockAaveV3Pool());
        address aaveV3PoolAddressesProvider = address(new MockAaveV3PoolAddressesProvider(aaveV3Pool));

        networkConfig = NetworkConfig({
            initialOwner: address(1),
            tokens: TokensConfig({link: link, usdc: usdc}),
            protocols: ProtocolsConfig({aaveV3PoolAddressesProvider: aaveV3PoolAddressesProvider}),
            treasury: treasury,
            ccipRouter: ccipRouter,
            defaultAdmin: defaultAdmin,
            pauser: pauser,
            unpauser: unpauser,
            configOperator: configOperator,
            complianceOperator: complianceOperator,
            thisChainSelector: 12345
        });
    }
}
