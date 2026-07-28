// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

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
    address internal constant BURNER_EOA = 0x7664C538C80870824738A8ADCcd92AcA244D7e69;
    uint64 internal constant ARBITRUM_CHAIN_SELECTOR = 4949039107694359620;
    uint64 internal constant ARBITRUM_SEPOLIA_CHAIN_SELECTOR = 3478487238524512106;
    uint256 internal constant INITIAL_DEFAULT_CCIP_GAS_LIMIT = 500_000;

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
        PolicyRolesConfig policy;
        address linkOperator;
        address rewardsOperator;
        address upgrader;
        address cancelDepositOperator;
    }

    struct PolicyRolesConfig {
        address admin;
        address configAdmin;
        address engineManager;
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
        // Mainnets
        if (block.chainid == 42161) activeNetworkConfig = getArbitrumConfig();
        else if (block.chainid == 8453) activeNetworkConfig = getBaseConfig();
        else if (block.chainid == 1) activeNetworkConfig = getEthereumConfig();
        else if (block.chainid == 43114) activeNetworkConfig = getAvalancheConfig();
        else if (block.chainid == 10) activeNetworkConfig = getOptimismConfig();
        // Testnets
        else if (block.chainid == 421614) activeNetworkConfig = getArbitrumSepoliaConfig();
        else if (block.chainid == 11155111) activeNetworkConfig = getEthereumSepoliaConfig();
        else if (block.chainid == 84532) activeNetworkConfig = getBaseSepoliaConfig();
        else if (block.chainid == 11155420) activeNetworkConfig = getOptimismSepoliaConfig();
        else if (block.chainid == 43113) activeNetworkConfig = getAvalancheFujiConfig();
        // Local
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
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
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
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
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
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
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x5947BB275c521040051D82396192181b413227A3, usdc: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                aaveV4Spoke: 0x435272CefF93a1E657E8ABfdf0A13e95900A3a56,
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
            kycProvider: BURNER_EOA,
            roles: RolesConfig({
                defaultAdmin: BURNER_EOA,
                pauser: BURNER_EOA,
                unpauser: BURNER_EOA,
                configOperator: BURNER_EOA,
                complianceOperator: BURNER_EOA,
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
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
                                TESTNETS
    //////////////////////////////////////////////////////////////*/
    function getArbitrumSepoliaConfig() public pure returns (NetworkConfig memory networkConfig) {
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E, usdc: 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f,
                aaveV4Spoke: address(0),
                compoundV3Comet: 0xCacEf2972a46D3Ad67072c9BFc6C1157bEaf1651,
                compoundV3CometRewards: 0xad024A165c3c973aD74F8B038D386686Ec534006
            }),
            ccip: CCIPConfig({
                router: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
                thisChainSelector: 3478487238524512106,
                parentChainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0x76c9cf548b4179F8901cda1f8623568b58215E62})
        });
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory networkConfig) {
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789, usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x09AddfA88e49bDf33021971e38b0BFae8715Af7A,
                aaveV4Spoke: 0x5d1079dae90f23bbe64fAf3adC08554669D9f938,
                compoundV3Comet: 0x8383A982dc0B844cA9200FbedEeBBE50ae4bb157,
                compoundV3CometRewards: 0x079A90B7761FF10F455BC2188392b2ae765F8DAd
            }),
            ccip: CCIPConfig({
                router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
                thisChainSelector: 16015286601757825753,
                parentChainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory networkConfig) {
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410, usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f,
                aaveV4Spoke: address(0),
                compoundV3Comet: 0xCacEf2972a46D3Ad67072c9BFc6C1157bEaf1651,
                compoundV3CometRewards: 0xad024A165c3c973aD74F8B038D386686Ec534006
            }),
            ccip: CCIPConfig({
                router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                thisChainSelector: 10344971235874465080,
                parentChainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0xF8344CFd5c43616a4366C34E3EEE75af79a74482})
        });
    }

    function getOptimismSepoliaConfig() public pure returns (NetworkConfig memory networkConfig) {
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410, usdc: 0x5fd84259d66Cd46123540766Be93DFE6D43130D7
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f,
                aaveV4Spoke: address(0),
                compoundV3Comet: 0xCacEf2972a46D3Ad67072c9BFc6C1157bEaf1651,
                compoundV3CometRewards: 0xad024A165c3c973aD74F8B038D386686Ec534006
            }),
            ccip: CCIPConfig({
                router: 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57,
                thisChainSelector: 5224473277236331295,
                parentChainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0x76c9cf548b4179F8901cda1f8623568b58215E62})
        });
    }

    function getAvalancheFujiConfig() public pure returns (NetworkConfig memory networkConfig) {
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
                policy: PolicyRolesConfig({admin: BURNER_EOA, configAdmin: BURNER_EOA, engineManager: BURNER_EOA}),
                linkOperator: BURNER_EOA,
                rewardsOperator: BURNER_EOA,
                upgrader: BURNER_EOA,
                cancelDepositOperator: BURNER_EOA
            }),
            tokens: TokensConfig({
                link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846, usdc: 0x5425890298aed601595a70AB815c96711a31Bc65
            }),
            protocols: ProtocolsConfig({
                aaveV3PoolAddressesProvider: 0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f,
                aaveV4Spoke: 0xCacEf2972a46D3Ad67072c9BFc6C1157bEaf1651,
                compoundV3Comet: address(0),
                compoundV3CometRewards: address(0)
            }),
            ccip: CCIPConfig({
                router: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
                thisChainSelector: 14767482510784806043,
                parentChainSelector: ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
                initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
            }),
            cre: CREConfig({keystoneForwarder: 0x76c9cf548b4179F8901cda1f8623568b58215E62})
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
            policy: PolicyRolesConfig({
                admin: makeAddr("policyAdmin"),
                configAdmin: makeAddr("policyConfigAdmin"),
                engineManager: makeAddr("policyEngineManager")
            }),
            linkOperator: makeAddr("linkOperator"),
            rewardsOperator: makeAddr("rewardsOperator"),
            upgrader: makeAddr("upgrader"),
            cancelDepositOperator: makeAddr("cancelDepositOperator")
        });
    }

    function _getMockTokensConfig() private returns (TokensConfig memory) {
        return TokensConfig({link: address(new MockLink()), usdc: address(new MockUSDC())});
    }

    function _getMockProtocolsConfig(address usdc) private returns (ProtocolsConfig memory) {
        address aaveV3Pool = address(new MockAaveV3Pool(usdc));

        return ProtocolsConfig({
            aaveV3PoolAddressesProvider: address(new MockAaveV3PoolAddressesProvider(aaveV3Pool)),
            aaveV4Spoke: address(new MockAaveV4Spoke(usdc)),
            compoundV3Comet: address(new MockComet(usdc)),
            compoundV3CometRewards: address(new MockCometRewards())
        });
    }

    function _getMockCcipConfig(address usdc) private returns (CCIPConfig memory) {
        return CCIPConfig({
            router: address(new MockCCIPRouter(usdc)),
            thisChainSelector: 12346,
            parentChainSelector: 12345,
            initialDefaultCcipGasLimit: INITIAL_DEFAULT_CCIP_GAS_LIMIT
        });
    }

    function _getMockCreConfig() private returns (CREConfig memory) {
        return CREConfig({keystoneForwarder: makeAddr("keystoneForwarder")});
    }
}
