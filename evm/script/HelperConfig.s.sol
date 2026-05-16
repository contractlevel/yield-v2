// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

import {MockLink} from "../test/mocks/MockLink.sol";
import {MockUSDC} from "../test/mocks/MockUSDC.sol";
import {MockCCIPRouter} from "../test/mocks/MockCCIPRouter.sol";
import {MockAaveV3Pool} from "../test/mocks/MockAaveV3Pool.sol";
import {MockAaveV3PoolAddressesProvider} from "../test/mocks/MockAaveV3PoolAddressesProvider.sol";
import {MockAaveV4Spoke} from "../test/mocks/MockAaveV4Spoke.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    address internal constant BURNER_EOA = 0x07b788B6f616D93434Ce20665cCDbbeDAf446B41;
    uint64 internal constant ARBITRUM_CHAIN_SELECTOR = 4949039107694359620;

    /*//////////////////////////////////////////////////////////////
                             NETWORK CONFIG
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address initialOwner;
        address treasury;
        address kycProvider;
        RolesConfig roles;
        TokensConfig tokens;
        ProtocolsConfig protocols;
        CCIPConfig ccip;
        CREConfig cre;
    }

    struct RolesConfig {
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address complianceOperator;
        address policyAdmin;
        address policyConfigAdmin;
        address policyEngineManager;
        address emergencyDrainer;
        address linkOperator;
    }

    struct TokensConfig {
        address link;
        address usdc;
    }

    struct ProtocolsConfig {
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
    }

    struct CCIPConfig {
        address router;
        uint64 thisChainSelector;
        uint64 parentChainSelector;
    }

    struct CREConfig {
        address keystoneForwarder;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        if (block.chainid == 42161) activeNetworkConfig = getArbitrumConfig();
        else if (block.chainid == 8453) activeNetworkConfig = getBaseConfig();
        else activeNetworkConfig = getOrCreateAnvilEthConfig();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    /*//////////////////////////////////////////////////////////////
                                MAINNETS
    //////////////////////////////////////////////////////////////*/
    function getArbitrumConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policyAdmin: BURNER_EOA,
                policyConfigAdmin: BURNER_EOA,
                policyEngineManager: BURNER_EOA,
                emergencyDrainer: BURNER_EOA,
                linkOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4, usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                aaveV4Spoke: address(0) // @review update when aave v4 is deployed
            }),
            ccip: CCIPConfig({
                router: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
                thisChainSelector: 4949039107694359620,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getBaseConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policyAdmin: BURNER_EOA,
                policyConfigAdmin: BURNER_EOA,
                policyEngineManager: BURNER_EOA,
                emergencyDrainer: BURNER_EOA,
                linkOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196, usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D,
                aaveV4Spoke: address(0) // @review update when aave v4 is deployed
            }),
            ccip: CCIPConfig({
                router: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                thisChainSelector: 15971525489660198786,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getEthereumConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policyAdmin: BURNER_EOA,
                policyConfigAdmin: BURNER_EOA,
                policyEngineManager: BURNER_EOA,
                emergencyDrainer: BURNER_EOA,
                linkOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x514910771AF9Ca656af840dff83E8264EcF986CA, usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                aaveV4Spoke: 0x94E756a88941F6df2d5200234a974eE5A89dC485
            }),
            ccip: CCIPConfig({
                router: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
                thisChainSelector: 5009297550715157269,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory networkConfig) {
        TokensConfig memory tokens = _getMockTokensConfig();
        ProtocolsConfig memory protocols = _getMockProtocolsConfig(tokens.usdc);
        CCIPConfig memory ccip = _getMockCcipConfig(tokens.usdc);
        CREConfig memory cre = _getMockCreConfig();

        networkConfig = NetworkConfig({
            initialOwner: address(1),
            treasury: makeAddr("treasury"),
            kycProvider: makeAddr("kycProvider"),
            roles: _getMockRolesConfig(),
            tokens: tokens,
            protocols: protocols,
            ccip: ccip,
            cre: cre
        });
    }

    function _getMockRolesConfig() private returns (RolesConfig memory) {
        return RolesConfig({
            defaultAdmin: makeAddr("defaultAdmin"),
            pauser: makeAddr("pauser"),
            unpauser: makeAddr("unpauser"),
            configOperator: makeAddr("configOperator"),
            complianceOperator: makeAddr("complianceOperator"),
            policyAdmin: makeAddr("policyAdmin"),
            policyConfigAdmin: makeAddr("policyConfigAdmin"),
            policyEngineManager: makeAddr("policyEngineManager"),
            emergencyDrainer: makeAddr("emergencyDrainer"),
            linkOperator: makeAddr("linkOperator")
        });
    }

    function _getMockTokensConfig() private returns (TokensConfig memory) {
        return TokensConfig({link: address(new MockLink()), usdc: address(new MockUSDC())});
    }

    function _getMockProtocolsConfig(address usdc) private returns (ProtocolsConfig memory) {
        address aaveV3Pool = address(new MockAaveV3Pool());

        return ProtocolsConfig({
            aaveV3PoolAddressesProvider: address(new MockAaveV3PoolAddressesProvider(aaveV3Pool)),
            aaveV4Spoke: address(new MockAaveV4Spoke(usdc))
        });
    }

    function _getMockCcipConfig(address usdc) private returns (CCIPConfig memory) {
        return
            CCIPConfig({
                router: address(new MockCCIPRouter(usdc)), thisChainSelector: 12345, parentChainSelector: 12345
            });
    }

    function _getMockCreConfig() private returns (CREConfig memory) {
        return CREConfig({keystoneForwarder: makeAddr("keystoneForwarder")});
    }
}
