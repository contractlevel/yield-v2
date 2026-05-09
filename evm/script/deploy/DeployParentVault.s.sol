// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.28;

// import {Script} from "forge-std/Script.sol";
// import {HelperConfig} from "../HelperConfig.s.sol";

// import {ParentVault, BaseVault} from "../../src/vaults/ParentVault.sol";
// import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
// import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
// import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
// import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
// import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
// import {Roles} from "../../src/libraries/Roles.sol";

// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
// import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
// import {Policy} from "@chainlink/policy-management/core/Policy.sol";
// import {OnlyAuthorizedSenderPolicy} from "@chainlink/policy-management/policies/OnlyAuthorizedSenderPolicy.sol";
// import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";
// import {IdentityRegistry} from "@chainlink/cross-chain-identity/IdentityRegistry.sol";
// import {CredentialRegistry} from "@chainlink/cross-chain-identity/CredentialRegistry.sol";
// import {
//     CredentialRegistryIdentityValidatorPolicy
// } from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidatorPolicy.sol";
// import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";

// import {SenderExtractor} from "../../src/modules/extractors/SenderExtractor.sol";
// import {TerminalAllowPolicy} from "../../src/modules/policies/TerminalAllowPolicy.sol";

// /// @title DeployParentVault
// /// @author @contractlevel
// /// @notice Script to deploy the ParentVault and its modules
// contract DeployParentVault is Script {
//     /*//////////////////////////////////////////////////////////////
//                                   RUN
//     //////////////////////////////////////////////////////////////*/
//     function run() external {
//         HelperConfig helperConfig = new HelperConfig();

//         vm.startBroadcast();
//         HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
//         address deployer = msg.sender;

//         (PolicyEngine policyEngine, IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry) =
//             _deployACEComponents(deployer);

//         AdapterRegistry adapterRegistry = new AdapterRegistry(deployer);

//         /// @dev Deploy the YieldcoinShare
//         YieldcoinShare yieldcoinImpl = new YieldcoinShare();
//         ERC1967Proxy yieldcoinProxy = new ERC1967Proxy(
//             address(yieldcoinImpl), abi.encodeWithSelector(YieldcoinShare.initialize.selector, address(policyEngine))
//         );
//         YieldcoinShare yieldcoin = YieldcoinShare(address(yieldcoinProxy));

//         /// @dev Deploy the ParentVault
//         BaseVault.ConstructorParams memory baseVaultParams = BaseVault.ConstructorParams({
//             link: networkConfig.tokens.link,
//             usdc: networkConfig.tokens.usdc,
//             ccipRouter: networkConfig.ccip.router,
//             defaultAdmin: deployer,
//             pauser: networkConfig.roles.pauser,
//             unpauser: networkConfig.roles.unpauser,
//             configOperator: deployer,
//             adapterRegistry: address(adapterRegistry),
//             thisChainSelector: networkConfig.ccip.parentChainSelector
//         });
//         ParentVault parentVault = new ParentVault(
//             baseVaultParams,
//             networkConfig.treasury,
//             address(yieldcoin),
//             networkConfig.roles.complianceOperator,
//             address(policyEngine)
//         );
//         /// @dev Deploy the Aave v3 Adapter
//         bytes32 aaveV3ProtocolId = keccak256("aave-v3");
//         AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
//             address(parentVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
//         );
//         adapterRegistry.setAdapter(aaveV3ProtocolId, address(aaveV3Adapter));
//         /// @dev Deploy the Aave v4 Adapter
//         bytes32 aaveV4ProtocolId = keccak256("aave-v4");
//         AaveV4Adapter aaveV4Adapter = new AaveV4Adapter(
//             address(parentVault),
//             networkConfig.tokens.usdc,
//             networkConfig.protocols.aaveV4Spoke,
//             networkConfig.protocols.aaveV4ReserveId
//         );
//         adapterRegistry.setAdapter(aaveV4ProtocolId, address(aaveV4Adapter));
//         parentVault.setInitialActiveProtocolAdapter(aaveV3ProtocolId);

//         /// @dev Deploy the WorkflowRouter
//         WorkflowRouter workflowRouter = new WorkflowRouter(
//             0, /// @dev Initial delay for the default admin role
//             deployer,
//             address(parentVault)
//         );
//         parentVault.setWorkflowRouter(address(workflowRouter));

//         TerminalAllowPolicy terminalAllow = _deployTerminalAllowPolicy(policyEngine);

//         _configureVaultKycPolicies(policyEngine, identityRegistry, credentialRegistry, parentVault, terminalAllow);
//         _configureRegistryProviderPolicies(
//             policyEngine, identityRegistry, credentialRegistry, terminalAllow, networkConfig.kycProvider
//         );

//         // @review we want to restrict all user functions in the YieldcoinShare to users who have completed KYC
//         _configureShareSupplyPolicies(policyEngine, yieldcoin, parentVault, deployer, networkConfig.roles.defaultAdmin);

//         parentVault.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
//         parentVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(workflowRouter));
//         parentVault.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(workflowRouter));
//         parentVault.grantRole(Roles.RECOVERY_OPERATOR_ROLE, address(workflowRouter));
//         parentVault.grantRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer);
//         parentVault.grantRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator);

//         workflowRouter.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
//         workflowRouter.grantRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser);
//         workflowRouter.grantRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser);
//         workflowRouter.grantRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder);

//         parentVault.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
//         workflowRouter.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

//         /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
//         ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
//         if (deployer != networkConfig.roles.defaultAdmin) {
//             parentVault.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
//         }

//         /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
//         ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
//         if (deployer != networkConfig.roles.defaultAdmin) {
//             workflowRouter.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
//         }

//         /// @dev Transfer ownership of the AdapterRegistry to the config operator.
//         /// @notice The configOperator address needs to accept the ownership transfer.
//         adapterRegistry.transferOwnership(networkConfig.roles.configOperator);
//         _handoffACERoles(
//             policyEngine,
//             identityRegistry,
//             credentialRegistry,
//             deployer,
//             networkConfig.roles.defaultAdmin,
//             networkConfig.roles.complianceOperator
//         );

//         vm.stopBroadcast();
//     }

//     /*//////////////////////////////////////////////////////////////
//                                   ACE
//     //////////////////////////////////////////////////////////////*/
//     function _deployACEComponents(address temporaryOwner)
//         internal
//         returns (PolicyEngine policyEngine, IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry)
//     {
//         /// @dev Deploy PolicyEngine
//         PolicyEngine policyEngineImpl = new PolicyEngine();
//         /// @dev We set the default to false to reject by default.
//         ///      This requires a Terminal policy that explicitly allows the action, otherwise the policy protected action would revert by default.
//         bytes memory policyEngineData = abi.encodeWithSelector(PolicyEngine.initialize.selector, false, temporaryOwner);
//         ERC1967Proxy policyEngineProxy = new ERC1967Proxy(address(policyEngineImpl), policyEngineData);
//         policyEngine = PolicyEngine(address(policyEngineProxy));

//         /// @dev Deploy IdentityRegistry
//         IdentityRegistry identityRegistryImpl = new IdentityRegistry();
//         bytes memory identityRegistryData =
//             abi.encodeWithSelector(IdentityRegistry.initialize.selector, address(policyEngine), temporaryOwner);
//         ERC1967Proxy identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), identityRegistryData);
//         identityRegistry = IdentityRegistry(address(identityRegistryProxy));
//         /// @dev Deploy CredentialRegistry
//         CredentialRegistry credentialRegistryImpl = new CredentialRegistry();
//         bytes memory credentialRegistryData =
//             abi.encodeWithSelector(CredentialRegistry.initialize.selector, address(policyEngine), temporaryOwner);
//         ERC1967Proxy credentialRegistryProxy = new ERC1967Proxy(address(credentialRegistryImpl), credentialRegistryData);
//         credentialRegistry = CredentialRegistry(address(credentialRegistryProxy));
//     }

//     function _deployTerminalAllowPolicy(PolicyEngine policyEngine)
//         internal
//         returns (TerminalAllowPolicy terminalAllow)
//     {
//         TerminalAllowPolicy terminalAllowImpl = new TerminalAllowPolicy();
//         ERC1967Proxy terminalAllowProxy = new ERC1967Proxy(
//             address(terminalAllowImpl),
//             abi.encodeWithSelector(
//                 Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
//             )
//         );
//         terminalAllow = TerminalAllowPolicy(address(terminalAllowProxy));
//     }

//     function _configureVaultKycPolicies(
//         PolicyEngine policyEngine,
//         IdentityRegistry identityRegistry,
//         CredentialRegistry credentialRegistry,
//         ParentVault parentVault,
//         TerminalAllowPolicy terminalAllow
//     ) internal {
//         /// @dev Values used in CredentialRegistryIdentityValidatorPolicyTest.t.sol
//         bytes32 kycCredential = keccak256("common.kyc");
//         bytes32 kycRequirement = keccak256("KYC");

//         /// @dev Credential sources
//         ICredentialRequirements.CredentialSourceInput[] memory sources =
//             new ICredentialRequirements.CredentialSourceInput[](1);
//         sources[0] = ICredentialRequirements.CredentialSourceInput({
//             credentialTypeId: kycCredential,
//             identityRegistry: address(identityRegistry),
//             credentialRegistry: address(credentialRegistry),
//             dataValidator: address(0)
//         });
//         /// @dev Credential requirements
//         bytes32[] memory requiredCredentials = new bytes32[](1);
//         requiredCredentials[0] = kycCredential;
//         ICredentialRequirements.CredentialRequirementInput[] memory requirements =
//             new ICredentialRequirements.CredentialRequirementInput[](1);
//         requirements[0] = ICredentialRequirements.CredentialRequirementInput({
//             requirementId: kycRequirement, credentialTypeIds: requiredCredentials, minValidations: 1, invert: false
//         });
//         /// @dev KYC Policy
//         CredentialRegistryIdentityValidatorPolicy kycPolicyImpl = new CredentialRegistryIdentityValidatorPolicy();
//         ERC1967Proxy kycPolicyProxy = new ERC1967Proxy(
//             address(kycPolicyImpl),
//             abi.encodeWithSelector(
//                 Policy.initialize.selector,
//                 address(policyEngine),
//                 address(policyEngine),
//                 abi.encode(sources, requirements)
//             )
//         );
//         CredentialRegistryIdentityValidatorPolicy kycPolicy =
//             CredentialRegistryIdentityValidatorPolicy(address(kycPolicyProxy));

//         /// @dev Extract msg.sender from the policy engine payload
//         SenderExtractor senderExtractor = new SenderExtractor();

//         /// @dev ParentVault selectors to be protected by the KYC Policy
//         bytes4[] memory selectors = new bytes4[](6);
//         selectors[0] = ParentVault.deposit.selector;
//         selectors[1] = ParentVault.withdraw.selector;
//         selectors[2] = ParentVault.claimShares.selector;
//         selectors[3] = ParentVault.claimUsdc.selector;
//         selectors[4] = ParentVault.cancelDeposit.selector;
//         selectors[5] = ParentVault.cancelWithdraw.selector;

//         /// @dev Extract msg.sender for each of those selectors
//         policyEngine.setExtractors(selectors, address(senderExtractor));
//         bytes32[] memory senderParameter = new bytes32[](1);
//         senderParameter[0] = senderExtractor.PARAM_SENDER();

//         bytes32[] memory noParameters = new bytes32[](0);
//         for (uint256 i; i < selectors.length; ++i) {
//             policyEngine.addPolicy(address(parentVault), selectors[i], address(kycPolicy), senderParameter);
//             policyEngine.addPolicy(address(parentVault), selectors[i], address(terminalAllow), noParameters);
//         }
//     }

//     function _configureShareSupplyPolicies(
//         PolicyEngine policyEngine,
//         YieldcoinShare yieldcoin,
//         ParentVault parentVault,
//         address deployer,
//         address defaultAdmin
//     ) internal {
//         RoleBasedAccessControlPolicy shareSupplyPolicyImpl = new RoleBasedAccessControlPolicy();
//         ERC1967Proxy shareSupplyPolicyProxy = new ERC1967Proxy(
//             address(shareSupplyPolicyImpl),
//             abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), deployer, new bytes(0))
//         );
//         RoleBasedAccessControlPolicy shareSupplyPolicy =
//             RoleBasedAccessControlPolicy(address(shareSupplyPolicyProxy));

//         shareSupplyPolicy.grantOperationAllowanceToRole(ComplianceTokenERC3643.mint.selector, Roles.MINTER_ROLE);
//         shareSupplyPolicy.grantOperationAllowanceToRole(ComplianceTokenERC3643.burn.selector, Roles.BURNER_ROLE);
//         shareSupplyPolicy.grantRole(Roles.MINTER_ROLE, address(parentVault));
//         shareSupplyPolicy.grantRole(Roles.BURNER_ROLE, address(parentVault));

//         bytes32[] memory noParameters = new bytes32[](0);
//         policyEngine.addPolicy(
//             address(yieldcoin), ComplianceTokenERC3643.mint.selector, address(shareSupplyPolicy), noParameters
//         );
//         policyEngine.addPolicy(
//             address(yieldcoin), ComplianceTokenERC3643.burn.selector, address(shareSupplyPolicy), noParameters
//         );

//         if (deployer != defaultAdmin) {
//             shareSupplyPolicy.transferOwnership(defaultAdmin);
//         }
//     }

//     function _configureRegistryProviderPolicies(
//         PolicyEngine policyEngine,
//         IdentityRegistry identityRegistry,
//         CredentialRegistry credentialRegistry,
//         TerminalAllowPolicy terminalAllow,
//         address provider
//     ) internal {
//         OnlyAuthorizedSenderPolicy providerPolicyImpl = new OnlyAuthorizedSenderPolicy();
//         ERC1967Proxy providerPolicyProxy = new ERC1967Proxy(
//             address(providerPolicyImpl),
//             abi.encodeWithSelector(
//                 Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
//             )
//         );
//         OnlyAuthorizedSenderPolicy providerPolicy = OnlyAuthorizedSenderPolicy(address(providerPolicyProxy));

//         policyEngine.setPolicyConfiguration(
//             address(providerPolicy),
//             policyEngine.getPolicyConfigVersion(address(providerPolicy)),
//             OnlyAuthorizedSenderPolicy.authorizeSender.selector,
//             abi.encode(provider)
//         );

//         bytes4[] memory identitySelectors = new bytes4[](3);
//         identitySelectors[0] = IdentityRegistry.registerIdentity.selector;
//         identitySelectors[1] = IdentityRegistry.registerIdentities.selector;
//         identitySelectors[2] = IdentityRegistry.removeIdentity.selector;

//         bytes4[] memory credentialSelectors = new bytes4[](4);
//         credentialSelectors[0] = CredentialRegistry.registerCredential.selector;
//         credentialSelectors[1] = CredentialRegistry.registerCredentials.selector;
//         credentialSelectors[2] = CredentialRegistry.removeCredential.selector;
//         credentialSelectors[3] = CredentialRegistry.renewCredential.selector;

//         bytes32[] memory noParameters = new bytes32[](0);
//         for (uint256 i; i < identitySelectors.length; ++i) {
//             policyEngine.addPolicy(
//                 address(identityRegistry), identitySelectors[i], address(providerPolicy), noParameters
//             );
//             policyEngine.addPolicy(
//                 address(identityRegistry), identitySelectors[i], address(terminalAllow), noParameters
//             );
//         }
//         for (uint256 i; i < credentialSelectors.length; ++i) {
//             policyEngine.addPolicy(
//                 address(credentialRegistry), credentialSelectors[i], address(providerPolicy), noParameters
//             );
//             policyEngine.addPolicy(
//                 address(credentialRegistry), credentialSelectors[i], address(terminalAllow), noParameters
//             );
//         }
//     }

//     function _handoffACERoles(
//         PolicyEngine policyEngine,
//         IdentityRegistry identityRegistry,
//         CredentialRegistry credentialRegistry,
//         address deployer,
//         address finalDefaultAdmin,
//         address finalComplianceOperator
//     ) internal {
//         if (deployer != finalDefaultAdmin) {
//             policyEngine.grantRole(policyEngine.DEFAULT_ADMIN_ROLE(), finalDefaultAdmin);
//         }
//         if (deployer != finalComplianceOperator) {
//             policyEngine.grantRole(policyEngine.ADMIN_ROLE(), finalComplianceOperator);
//             policyEngine.grantRole(policyEngine.POLICY_CONFIG_ADMIN_ROLE(), finalComplianceOperator);
//         }

//         if (deployer != finalComplianceOperator) {
//             policyEngine.revokeRole(policyEngine.ADMIN_ROLE(), deployer);
//             policyEngine.revokeRole(policyEngine.POLICY_CONFIG_ADMIN_ROLE(), deployer);
//         }
//         if (deployer != finalDefaultAdmin) {
//             policyEngine.revokeRole(policyEngine.DEFAULT_ADMIN_ROLE(), deployer);
//         }

//         identityRegistry.transferOwnership(finalComplianceOperator);
//         credentialRegistry.transferOwnership(finalComplianceOperator);
//     }
// }
