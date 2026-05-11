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
        uint256 aaveV4ReserveId;
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
        TokensConfig memory tokens = _getMockTokensConfig();
        ProtocolsConfig memory protocols = _getMockProtocolsConfig(tokens.usdc);
        CCIPConfig memory ccip = _getMockCcipConfig(tokens.usdc);
        CREConfig memory cre = _getMockCreConfig();

        return NetworkConfig({
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
            aaveV4Spoke: address(new MockAaveV4Spoke(usdc)),
            aaveV4ReserveId: 1
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
