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

/// @title DeployParentVault
/// @author @contractlevel
/// @notice Script to deploy the ParentVault and its modules
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
        ParentVault parentVault = new ParentVault(baseVaultParams, networkConfig.treasury);
        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            address(parentVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
        );
        adapterRegistry.setAdapter(aaveV3ProtocolId, address(aaveV3Adapter));
        parentVault.setInitialActiveProtocolAdapter(aaveV3ProtocolId);

        _configureVaultKycPolicies(
            policyEngine, identityRegistry, credentialRegistry, parentVault, networkConfig.initialOwner
        );

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
        /// @dev Deploy PolicyEngine
        PolicyEngine policyEngineImpl = new PolicyEngine();
        /// @dev We set the default to false to reject by default.
        ///      This requires a Terminal policy that explicitly allows the action, otherwise the policy protected action would revert by default.
        bytes memory policyEngineData = abi.encodeWithSelector(PolicyEngine.initialize.selector, false, initialOwner);
        ERC1967Proxy policyEngineProxy = new ERC1967Proxy(address(policyEngineImpl), policyEngineData);
        policyEngine = PolicyEngine(address(policyEngineProxy));

        /// @dev Deploy IdentityRegistry
        IdentityRegistry identityRegistryImpl = new IdentityRegistry();
        bytes memory identityRegistryData =
            abi.encodeWithSelector(IdentityRegistry.initialize.selector, address(policyEngine), initialOwner);
        ERC1967Proxy identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), identityRegistryData);
        identityRegistry = IdentityRegistry(address(identityRegistryProxy));
        /// @dev Deploy CredentialRegistry
        CredentialRegistry credentialRegistryImpl = new CredentialRegistry();
        bytes memory credentialRegistryData =
            abi.encodeWithSelector(CredentialRegistry.initialize.selector, address(policyEngine), initialOwner);
        ERC1967Proxy credentialRegistryProxy = new ERC1967Proxy(address(credentialRegistryImpl), credentialRegistryData);
        credentialRegistry = CredentialRegistry(address(credentialRegistryProxy));
    }

    function _configureVaultKycPolicies(
        PolicyEngine policyEngine,
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        ParentVault parentVault,
        address initialOwner
    ) internal {
        bytes32 kycCredential = keccak256("common.kyc");

        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = ICredentialRequirements.CredentialSourceInput({
            credentialTypeId: kycCredential,
            identityRegistry: address(identityRegistry),
            credentialRegistry: address(credentialRegistry),
            dataValidator: address(0)
        });
        bytes32[] memory requiredCredentials = new bytes32[](1);
        requiredCredentials[0] = kycCredential;
        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = ICredentialRequirements.CredentialRequirementInput({
            requirementId: keccak256("requirement.KYC"),
            credentialTypeIds: requiredCredentials,
            minValidations: 1,
            invert: false
        });
        CredentialRegistryIdentityValidatorPolicy kycPolicyImpl = new CredentialRegistryIdentityValidatorPolicy();
        ERC1967Proxy kycPolicyProxy = new ERC1967Proxy(
            address(kycPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector, address(policyEngine), initialOwner, abi.encode(sources, requirements)
            )
        );
        CredentialRegistryIdentityValidatorPolicy kycPolicy =
            CredentialRegistryIdentityValidatorPolicy(address(kycPolicyProxy));
            
        SenderExtractor senderExtractor = new SenderExtractor();
        TerminalAllowPolicy terminalAllowImpl = new TerminalAllowPolicy();
        ERC1967Proxy terminalAllowProxy = new ERC1967Proxy(
            address(terminalAllowImpl),
            abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), initialOwner, new bytes(0))
        );
        TerminalAllowPolicy terminalAllow = TerminalAllowPolicy(address(terminalAllowProxy));
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = ParentVault.deposit.selector;
        selectors[1] = ParentVault.withdraw.selector;
        selectors[2] = ParentVault.claimShares.selector;
        selectors[3] = ParentVault.claimUsdc.selector;
        selectors[4] = ParentVault.cancelDeposit.selector;
        selectors[5] = ParentVault.cancelWithdraw.selector;

        policyEngine.setExtractors(selectors, address(senderExtractor));

        bytes32[] memory senderParameter = new bytes32[](1);
        senderParameter[0] = senderExtractor.PARAM_SENDER();

        bytes32[] memory noParameters = new bytes32[](0);
        for (uint256 i = 0; i < selectors.length; i++) {
            policyEngine.addPolicy(address(parentVault), selectors[i], address(kycPolicy), senderParameter);
            policyEngine.addPolicy(address(parentVault), selectors[i], address(terminalAllow), noParameters);
        }
    }
}
