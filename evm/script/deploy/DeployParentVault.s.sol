// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {ParentVault, BaseVault} from "../../src/vaults/ParentVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {Yieldcoin} from "../../src/token/Yieldcoin.sol"; // @review replace this with compliance-ready token

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {IdentityRegistry} from "@chainlink/cross-chain-identity/IdentityRegistry.sol";
import {CredentialRegistry} from "@chainlink/cross-chain-identity/CredentialRegistry.sol";
// import {
//     CredentialRegistryIdentityValidatorPolicy
// } from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidatorPolicy.sol";
// import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";

import {SenderExtractor} from "../../src/modules/extractors/SenderExtractor.sol";
import {TerminalAllowPolicy} from "../../src/modules/policies/TerminalAllowPolicy.sol";

contract DeployParentVault is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();

        (PolicyEngine policyEngine, IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry) =
            _deployACEComponents(networkConfig.initialOwner);

        AdapterRegistry adapterRegistry = new AdapterRegistry(msg.sender);
        Yieldcoin yieldcoin = new Yieldcoin(); // @review replace this with compliance-ready token

        BaseVault.ConstructorParams memory baseVaultParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            usdc: networkConfig.tokens.usdc,
            share: address(yieldcoin),
            ccipRouter: networkConfig.ccipRouter,
            defaultAdmin: networkConfig.defaultAdmin,
            pauser: networkConfig.pauser,
            unpauser: networkConfig.unpauser,
            configOperator: networkConfig.configOperator,
            complianceOperator: networkConfig.complianceOperator,
            policyEngine: address(policyEngine),
            adapterRegistry: address(adapterRegistry),
            thisChainSelector: networkConfig.thisChainSelector
        });
        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        ParentVault parentVault =  new ParentVault(baseVaultParams, networkConfig.treasury);
        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            address(parentVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
        );
        adapterRegistry.setAdapter(aaveV3ProtocolId, address(aaveV3Adapter));
        parentVault.setInitialActiveProtocolAdapter(aaveV3ProtocolId);

        adapterRegistry.transferOwnership(networkConfig.initialOwner);

        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                                  ACE
    //////////////////////////////////////////////////////////////*/
    function _deployACEComponents(address initialOwner)
        internal
        returns (PolicyEngine policyEngine, IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry)
    {
        // --- 1. Deploy Core Infrastructure ---
        // The PolicyEngine is the central orchestrator for all compliance rules.
        // We set its default to allow (true) for this tutorial, meaning any action
        // not explicitly rejected by a policy will be permitted.
        PolicyEngine policyEngineImpl = new PolicyEngine();
        bytes memory policyEngineData = abi.encodeWithSelector(PolicyEngine.initialize.selector, true, initialOwner);
        ERC1967Proxy policyEngineProxy = new ERC1967Proxy(address(policyEngineImpl), policyEngineData);
        policyEngine = PolicyEngine(address(policyEngineProxy));

        // --- 2. Deploy Identity & Credential Registries and Secure Them ---
        // These registries are the databases for our identity system.
        // Crucially, we set the PolicyEngine as their owner, so all administrative
        // actions MUST go through the policy system.
        IdentityRegistry identityRegistryImpl = new IdentityRegistry();
        bytes memory identityRegistryData =
            abi.encodeWithSelector(IdentityRegistry.initialize.selector, address(policyEngine), initialOwner);
        ERC1967Proxy identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), identityRegistryData);
        identityRegistry = IdentityRegistry(address(identityRegistryProxy));

        CredentialRegistry credentialRegistryImpl = new CredentialRegistry();
        bytes memory credentialRegistryData =
            abi.encodeWithSelector(CredentialRegistry.initialize.selector, address(policyEngine), initialOwner);
        ERC1967Proxy credentialRegistryProxy = new ERC1967Proxy(address(credentialRegistryImpl), credentialRegistryData);
        credentialRegistry = CredentialRegistry(address(credentialRegistryProxy));
    }
}
