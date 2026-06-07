// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

import {MockLink} from "../test/mocks/MockLink.sol";
import {MockUSDC} from "../test/mocks/MockUSDC.sol";
import {MockCCIPRouter} from "../test/mocks/MockCCIPRouter.sol";
import {MockAaveV3Pool} from "../test/mocks/MockAaveV3Pool.sol";
import {MockAaveV3PoolAddressesProvider} from "../test/mocks/MockAaveV3PoolAddressesProvider.sol";
import {MockAaveV4Spoke} from "../test/mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../test/mocks/MockComet.sol";
import {MockCometRewards} from "../test/mocks/MockCometRewards.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    address internal constant BURNER_EOA = 0x07b788B6f616D93434Ce20665cCDbbeDAf446B41;
    uint64 internal constant ARBITRUM_CHAIN_SELECTOR = 4949039107694359620;
    uint256 internal constant INITIAL_DEFAULT_CCIP_GAS_LIMIT = 500_000;

    /*//////////////////////////////////////////////////////////////
                             NETWORK CONFIG
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address initialOwner;
        address treasury;
        address emergencyReceiver;
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
        address donateOperator;
        address rewardsOperator;
    }

    struct TokensConfig {
        address link;
        address usdc;
    }

    struct ProtocolsConfig {
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
    }

    struct CCIPConfig {
        address router;
        uint64 thisChainSelector;
        uint64 parentChainSelector;
        uint256 initialDefaultCcipGasLimit;
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
        else if (block.chainid == 1) activeNetworkConfig = getEthereumConfig();
        else if (block.chainid == 43114) activeNetworkConfig = getAvalancheConfig();
        else if (block.chainid == 10) activeNetworkConfig = getOptimismConfig();
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
            emergencyReceiver: BURNER_EOA,
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
                linkOperator: BURNER_EOA,
                donateOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4, usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                // @review-deploy update when aave v4 is deployed
                aaveV4Spoke: address(0),
                compoundV3Comet: 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf,
                compoundV3CometRewards: 0x88730d254A2f7e6AC8388c3198aFd694bA9f7fae
            }),
            ccip: CCIPConfig({
                router: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
                thisChainSelector: 4949039107694359620,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getBaseConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            emergencyReceiver: BURNER_EOA,
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
                linkOperator: BURNER_EOA,
                donateOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196, usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D,
                // @review-deploy update when aave v4 is deployed
                aaveV4Spoke: address(0),
                compoundV3Comet: 0xb125E6687d4313864e53df431d5425969c15Eb2F,
                compoundV3CometRewards: 0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1
            }),
            ccip: CCIPConfig({
                router: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                thisChainSelector: 15971525489660198786,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getEthereumConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            emergencyReceiver: BURNER_EOA,
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
                linkOperator: BURNER_EOA,
                donateOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x514910771AF9Ca656af840dff83E8264EcF986CA, usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                aaveV4Spoke: 0x94e7A5dCbE816e498b89aB752661904E2F56c485,
                compoundV3Comet: 0xc3d688B66703497DAA19211EEdff47f25384cdc3,
                compoundV3CometRewards: 0x1B0e765F6224C21223AeA2af16c1C46E38885a40
            }),
            ccip: CCIPConfig({
                router: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
                thisChainSelector: 5009297550715157269,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0x0b93082D9b3C7C97fAcd250082899BAcf3af3885})
        });
    }

    function getAvalancheConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            emergencyReceiver: BURNER_EOA,
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
                linkOperator: BURNER_EOA,
                donateOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x5947BB275c521040051D82396192181b413227A3, usdc: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                aaveV4Spoke: address(0),
                compoundV3Comet: address(0),
                compoundV3CometRewards: address(0)
            }),
            ccip: CCIPConfig({
                router: 0x27F39D0af3303703750D4001fCc1844c6491563c,
                thisChainSelector: 6433500567565415381,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0x76c9cf548b4179F8901cda1f8623568b58215E62})
        });
    }

    function getOptimismConfig() public pure returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            initialOwner: BURNER_EOA,
            treasury: BURNER_EOA,
            emergencyReceiver: BURNER_EOA,
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
                linkOperator: BURNER_EOA,
                donateOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6, usdc: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                aaveV4Spoke: address(0),
                compoundV3Comet: 0x2e44e174f7D53F0212823acC11C01A11d58c5bCB,
                compoundV3CometRewards: 0x443EA0340cb75a160F31A440722dec7b5bc3C2E9
            }),
            ccip: CCIPConfig({
                router: 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f,
                thisChainSelector: 3734403246176062136,
                parentChainSelector: ARBITRUM_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
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
            emergencyReceiver: makeAddr("emergencyReceiver"),
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
            linkOperator: makeAddr("linkOperator"),
            donateOperator: makeAddr("donateOperator"),
            rewardsOperator: makeAddr("rewardsOperator")
        });
    }

    function _getMockTokensConfig() private returns (TokensConfig memory) {
        return TokensConfig({link: address(new MockLink()), usdc: address(new MockUSDC())});
    }

    function _getMockProtocolsConfig(address usdc) private returns (ProtocolsConfig memory) {
        address aaveV3Pool = address(new MockAaveV3Pool());

        return ProtocolsConfig({
            aaveV3PoolAddressesProvider: address(new MockAaveV3PoolAddressesProvider(aaveV3Pool)),
            aaveV4Spoke: address(new MockAaveV4Spoke(usdc)),
            compoundV3Comet: address(new MockComet()),
            compoundV3CometRewards: address(new MockCometRewards())
        });
    }

    function _getMockCcipConfig(address usdc) private returns (CCIPConfig memory) {
        return CCIPConfig({
            router: address(new MockCCIPRouter(usdc)),
            thisChainSelector: 12345,
            parentChainSelector: 12345,
            initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
        });
    }

    function _getMockCreConfig() private returns (CREConfig memory) {
        return CREConfig({keystoneForwarder: makeAddr("keystoneForwarder")});
    }
}
