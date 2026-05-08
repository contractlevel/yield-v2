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
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address complianceOperator;
        address kycProvider;
        TokensConfig tokens;
        ProtocolsConfig protocols;
        CCIPConfig ccip;
    }

    struct TokensConfig {
        address link;
        address usdc;
    }

    struct ProtocolsConfig {
        address aaveV3PoolAddressesProvider;
    }

    struct CCIPConfig {
        address router;
        uint64 thisChainSelector;
        uint64 parentChainSelector;
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
        address kycProvider = makeAddr("kycProvider");

        address aaveV3Pool = address(new MockAaveV3Pool());
        address aaveV3PoolAddressesProvider = address(new MockAaveV3PoolAddressesProvider(aaveV3Pool));

        networkConfig = NetworkConfig({
            initialOwner: address(1),
            tokens: TokensConfig({link: link, usdc: usdc}),
            protocols: ProtocolsConfig({aaveV3PoolAddressesProvider: aaveV3PoolAddressesProvider}),
            treasury: treasury,
            defaultAdmin: defaultAdmin,
            pauser: pauser,
            unpauser: unpauser,
            configOperator: configOperator,
            complianceOperator: complianceOperator,
            kycProvider: kycProvider,
            ccip: CCIPConfig({router: ccipRouter, thisChainSelector: 12345, parentChainSelector: 12345})
        });
    }
}
