// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {TestnetProtocolConfigurator} from "./TestnetProtocolConfigurator.sol";

import {ParentVault, BaseVault} from "../../src/vaults/ParentVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../src/modules/adapters/CompoundV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
import {Roles} from "../../src/libraries/Roles.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {OnlyAuthorizedSenderPolicy} from "@chainlink/policy-management/policies/OnlyAuthorizedSenderPolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";
import {IdentityRegistry} from "@chainlink/cross-chain-identity/IdentityRegistry.sol";
import {CredentialRegistry} from "@chainlink/cross-chain-identity/CredentialRegistry.sol";
import {
    CredentialRegistryIdentityValidatorPolicy
} from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidatorPolicy.sol";
import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";

import {SenderExtractor} from "../../src/modules/extractors/SenderExtractor.sol";
import {YieldcoinShareKycExtractor} from "../../src/modules/extractors/YieldcoinShareKycExtractor.sol";
import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {TerminalAllowPolicy} from "../../src/modules/policies/TerminalAllowPolicy.sol";
import {YieldcoinShareFrozenAccountPolicy} from "../../src/modules/policies/YieldcoinShareFrozenAccountPolicy.sol";

/// @title DeployParentVault Script
/// @author @contractlevel
/// @notice Script to deploy the ParentVault and its modules
/// @notice This script's correctness is critical to the security of the Yieldcoin v2 system.
/// @dev This script deploys and sets Chainlink ACE components for the ParentVault and the YieldcoinShare token.
/// @dev The YieldcoinShare is a ComplianceTokenERC3643, so access control must be run as a policy.
/// @dev All user-facing functions for ParentVault and YieldcoinShare require the user to have completed KYC with a registered provider.
///      This includes:
///      ParentVault: deposit, withdraw, claimShares, claimAsset, cancelDeposit, and cancelWithdraw functions.
///      YieldcoinShare: transfer, transferFrom, batchTransfer, approve, increaseAllowance, and decreaseAllowance functions.
///      Both the caller and the relevant counterparty addresses (recipient, spender) must be KYC-approved.
/// @dev YieldcoinShare mint and burn functions are protected by a RoleBasedAccessControlPolicy.
///      The RoleBasedAccessControlPolicy is configured to grant the MINTER_ROLE and BURNER_ROLE to the ParentVault contract.
///      RoleBasedAccessControlPolicy (as opposed to OZ's AccessControlDefaultAdminRules) is used for YieldcoinShare mint and burn because these functions could not be overridden as a ComplianceTokenERC3643.
/// @dev This script assigns roles to contracts/actors in the Yieldcoin v2 system. By the end of this script, roles should be as follows:
///      ParentVault.DEFAULT_ADMIN_ROLE: deployer/msg.sender, pending transfer to networkConfig.roles.defaultAdmin
///      ParentVault.CONFIG_OPERATOR_ROLE: networkConfig.roles.configOperator
///      ParentVault.EPOCH_OPERATOR_ROLE: address(workflowRouter)
///      ParentVault.REBALANCE_OPERATOR_ROLE: address(workflowRouter)
///      ParentVault.LINK_OPERATOR_ROLE: networkConfig.roles.linkOperator
///      ParentVault.REWARDS_OPERATOR_ROLE: networkConfig.roles.rewardsOperator
///      ParentVault.CANCEL_DEPOSIT_OPERATOR_ROLE: networkConfig.roles.cancelDepositOperator (granted directly in initialize)
///      ParentVault.POLICY_ENGINE_MANAGER_ROLE: networkConfig.roles.policy.engineManager
///      ParentVault.PAUSER_ROLE: networkConfig.roles.pauser
///      ParentVault.UNPAUSER_ROLE: networkConfig.roles.unpauser
///      WorkflowRouter.DEFAULT_ADMIN_ROLE: networkConfig.roles.defaultAdmin
///      WorkflowRouter.CONFIG_OPERATOR_ROLE: networkConfig.roles.configOperator
///      WorkflowRouter.PAUSER_ROLE: networkConfig.roles.pauser
///      WorkflowRouter.UNPAUSER_ROLE: networkConfig.roles.unpauser
///      WorkflowRouter.KEYSTONE_FORWARDER_ROLE: networkConfig.cre.keystoneForwarder
///      AdapterRegistry.DEFAULT_ADMIN_ROLE: deployer/msg.sender, pending transfer to networkConfig.roles.defaultAdmin
///      AdapterRegistry.CONFIG_OPERATOR_ROLE: networkConfig.roles.configOperator
///      YieldcoinShare owner() (UUPS upgrade authority): networkConfig.roles.upgrader
///      YieldcoinShare CCIP admin: networkConfig.roles.configOperator
///      YieldcoinShare CONFIG_OPERATOR_ROLE: networkConfig.roles.configOperator through ACE RBAC (setCCIPAdmin, setName, setSymbol)
///      YieldcoinShare POLICY_ENGINE_MANAGER_ROLE: networkConfig.roles.policy.engineManager through ACE RBAC (attachPolicyEngine)
///      YieldcoinShare PAUSER_ROLE: networkConfig.roles.pauser through ACE RBAC (pause)
///      YieldcoinShare UNPAUSER_ROLE: networkConfig.roles.unpauser through ACE RBAC (unpause)
///      YieldcoinShare COMPLIANCE_OPERATOR_ROLE: networkConfig.roles.complianceOperator through ACE RBAC (forcedTransfer, freeze/unfreeze, setAddressFrozen)
///      PolicyEngine.DEFAULT_ADMIN_ROLE: networkConfig.roles.defaultAdmin
///      PolicyEngine.ADMIN_ROLE: networkConfig.roles.policy.admin
///      PolicyEngine.POLICY_CONFIG_ADMIN_ROLE: networkConfig.roles.policy.configAdmin
/// @notice After running this script, networkConfig.roles.defaultAdmin must call acceptDefaultAdminTransfer() on ParentVault and AdapterRegistry ASAP.
/// @notice WorkflowRouter is deployed directly with networkConfig.roles.defaultAdmin and an initial 3-day default admin delay.
contract DeployParent is Script {
    bytes4 private constant RBAC_GRANT_ROLE_SELECTOR = bytes4(keccak256("grantRole(bytes32,address)"));
    /// @dev YieldcoinShare.initialize is overloaded with ComplianceTokenERC3643's own initializer,
    ///      so `YieldcoinShare.initialize.selector` is ambiguous and must be computed explicitly.
    bytes4 private constant YIELDCOIN_SHARE_INITIALIZE_SELECTOR =
        bytes4(keccak256("initialize(address,address,address)"));
    bytes4 private constant AUTHORIZE_SENDER_SELECTOR = OnlyAuthorizedSenderPolicy.authorizeSender.selector;
    bytes4 private constant UNAUTHORIZE_SENDER_SELECTOR = OnlyAuthorizedSenderPolicy.unauthorizeSender.selector;
    bytes32 private constant KYC_CREDENTIAL = keccak256("common.kyc");
    /// @notice CCID used to register the ParentVault as a system identity in ACE registries.
    /// @dev Coordinate this value with the KYC provider before production deployment.
    ///      It is intentionally script-owned because only the parent deployment consumes it.
    bytes32 public constant PARENT_VAULT_CCID = keccak256("yield-v2.parent-vault");
    /// @notice CCID used to register the treasury as a system identity in ACE registries.
    /// @dev Coordinate this value with the KYC provider before production deployment.
    ///      It is intentionally script-owned because only the parent deployment consumes it.
    bytes32 public constant TREASURY_CCID = keccak256("yield-v2.treasury");

    struct Deployment {
        address link;
        address asset;
        bytes32 vaultCcid;
        bytes32 treasuryCcid;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
        AdapterRegistry adapterRegistry;
        YieldcoinShare yieldcoinImpl;
        YieldcoinShare yieldcoinProxy;
        ParentVault parentVaultImpl;
        ParentVault parentVaultProxy;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
        WorkflowRouter workflowRouter;
        PolicyEngine policyEngine;
        IdentityRegistry identityRegistry;
        CredentialRegistry credentialRegistry;
        YieldcoinShareFrozenAccountPolicy vaultFrozenAccountPolicy;
        CredentialRegistryIdentityValidatorPolicy vaultKycPolicy;
        CredentialRegistryAccountListValidatorPolicy shareKycPolicy;
        RoleBasedAccessControlPolicy shareSupplyPolicy;
        OnlyAuthorizedSenderPolicy providerPolicy;
        TerminalAllowPolicy terminalAllow;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external returns (Deployment memory deploy) {
        HelperConfig helperConfig = new HelperConfig();

        address deployer = msg.sender;
        vm.startBroadcast(deployer);
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        deploy = deployWithConfig(networkConfig, deployer);
        vm.stopBroadcast();
    }

    function deployWithConfig(HelperConfig.NetworkConfig memory networkConfig, address deployer)
        public
        returns (Deployment memory deploy)
    {
        deploy.link = networkConfig.tokens.link;
        deploy.asset = networkConfig.tokens.usdc;
        deploy.vaultCcid = PARENT_VAULT_CCID;
        deploy.treasuryCcid = TREASURY_CCID;
        deploy.aaveV3PoolAddressesProvider = networkConfig.protocols.aaveV3PoolAddressesProvider;
        deploy.aaveV4Spoke = networkConfig.protocols.aaveV4Spoke;
        deploy.compoundV3Comet = networkConfig.protocols.compoundV3Comet;
        deploy.compoundV3CometRewards = networkConfig.protocols.compoundV3CometRewards;

        /// @dev Deploy the PolicyEngine, IdentityRegistry, and CredentialRegistry
        (deploy.policyEngine, deploy.identityRegistry, deploy.credentialRegistry) = _deployACEComponents(deployer);

        /// @dev Deploy the AdapterRegistry
        deploy.adapterRegistry = new AdapterRegistry(
            0, /// @dev Initial delay for the default admin role
            deployer
        );
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev Deploy the YieldcoinShare
        YieldcoinShare yieldcoinImpl = new YieldcoinShare();
        deploy.yieldcoinImpl = yieldcoinImpl;
        ERC1967Proxy yieldcoinProxy = new ERC1967Proxy(
            address(yieldcoinImpl),
            abi.encodeWithSelector(
                YIELDCOIN_SHARE_INITIALIZE_SELECTOR,
                address(deploy.policyEngine),
                networkConfig.roles.configOperator,
                networkConfig.roles.upgrader
            )
        );
        deploy.yieldcoinProxy = YieldcoinShare(address(yieldcoinProxy));

        /// @dev Deploy the ParentVault implementation with immutable params, then initialize proxy state atomically.
        BaseVault.ConstructorParams memory baseVaultConstructorParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            asset: networkConfig.tokens.usdc,
            ccipRouter: networkConfig.ccip.router,
            adapterRegistry: address(deploy.adapterRegistry),
            thisChainSelector: networkConfig.ccip.parentChainSelector
        });
        BaseVault.InitParams memory baseVaultInitParams = BaseVault.InitParams({
            defaultAdmin: deployer,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: deployer,
            initialDefaultCcipGasLimit: networkConfig.ccip.initialDefaultCcipGasLimit,
            upgrader: networkConfig.roles.upgrader
        });
        /// @dev ParentVault linked libraries are handled by Solidity/Foundry and are not constructor state.
        deploy.parentVaultImpl = new ParentVault(baseVaultConstructorParams, address(deploy.yieldcoinProxy));
        ERC1967Proxy parentVaultProxy = new ERC1967Proxy(
            address(deploy.parentVaultImpl),
            abi.encodeWithSelector(
                ParentVault.initialize.selector,
                baseVaultInitParams,
                networkConfig.treasury,
                networkConfig.roles.policy.engineManager,
                address(deploy.policyEngine),
                networkConfig.roles.cancelDepositOperator
            )
        );
        deploy.parentVaultProxy = ParentVault(address(parentVaultProxy));
        bytes32 initialActiveProtocolId;

        /// @dev Deploy optional protocol adapters only when the configured protocol address exists on this chain.
        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        if (networkConfig.protocols.aaveV3PoolAddressesProvider != address(0)) {
            deploy.aaveV3Adapter = new AaveV3Adapter(
                address(deploy.parentVaultProxy), networkConfig.protocols.aaveV3PoolAddressesProvider
            );
            deploy.adapterRegistry.setAdapter(aaveV3ProtocolId, address(deploy.aaveV3Adapter));
            initialActiveProtocolId = aaveV3ProtocolId;
        }

        bytes32 aaveV4ProtocolId = keccak256("aave-v4");
        if (networkConfig.protocols.aaveV4Spoke != address(0)) {
            deploy.aaveV4Adapter =
                new AaveV4Adapter(address(deploy.parentVaultProxy), networkConfig.protocols.aaveV4Spoke);
            deploy.adapterRegistry.setAdapter(aaveV4ProtocolId, address(deploy.aaveV4Adapter));
            if (initialActiveProtocolId == bytes32(0)) initialActiveProtocolId = aaveV4ProtocolId;
        }

        bytes32 compoundV3ProtocolId = keccak256("compound-v3");
        if (networkConfig.protocols.compoundV3Comet != address(0)) {
            deploy.compoundV3Adapter = new CompoundV3Adapter(
                address(deploy.parentVaultProxy),
                networkConfig.protocols.compoundV3Comet,
                networkConfig.protocols.compoundV3CometRewards
            );
            deploy.adapterRegistry.setAdapter(compoundV3ProtocolId, address(deploy.compoundV3Adapter));
            if (initialActiveProtocolId == bytes32(0)) initialActiveProtocolId = compoundV3ProtocolId;
        }

        TestnetProtocolConfigurator.authorizeAdapters(
            networkConfig.protocols,
            address(deploy.aaveV3Adapter),
            address(deploy.aaveV4Adapter),
            address(deploy.compoundV3Adapter)
        );

        if (initialActiveProtocolId != bytes32(0)) {
            deploy.parentVaultProxy.setInitialActiveProtocolAdapter(initialActiveProtocolId);
        }

        deploy.parentVaultProxy.setSupportedProtocol(aaveV3ProtocolId, true);
        deploy.parentVaultProxy.setSupportedProtocol(aaveV4ProtocolId, true);
        deploy.parentVaultProxy.setSupportedProtocol(compoundV3ProtocolId, true);

        /// @dev Deploy the WorkflowRouter
        uint48 initialDelay = 259200; // 3 days
        WorkflowRouter.ConstructorParams memory workflowRouterParams = WorkflowRouter.ConstructorParams({
            initialDelay: initialDelay,
            defaultAdmin: networkConfig.roles.defaultAdmin,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: networkConfig.roles.configOperator,
            keystoneForwarder: networkConfig.cre.keystoneForwarder,
            vault: address(deploy.parentVaultProxy)
        });
        deploy.workflowRouter = new WorkflowRouter(workflowRouterParams);

        deploy.terminalAllow = _deployTerminalAllowPolicy(deploy.policyEngine);
        deploy.vaultFrozenAccountPolicy =
            _deployYieldcoinShareFrozenAccountPolicy(deploy.policyEngine, deploy.yieldcoinProxy);

        deploy.vaultKycPolicy = _configureVaultKycPolicies(
            deploy.policyEngine,
            deploy.identityRegistry,
            deploy.credentialRegistry,
            deploy.vaultFrozenAccountPolicy,
            deploy.parentVaultProxy,
            deploy.terminalAllow
        );
        deploy.providerPolicy = _configureRegistryProviderPolicies(
            deploy.policyEngine,
            deploy.identityRegistry,
            deploy.credentialRegistry,
            deploy.terminalAllow,
            networkConfig.kycProvider,
            deployer
        );
        _registerSystemKyc(
            deploy.identityRegistry, deploy.credentialRegistry, PARENT_VAULT_CCID, address(deploy.parentVaultProxy)
        );
        _registerSystemKyc(deploy.identityRegistry, deploy.credentialRegistry, TREASURY_CCID, networkConfig.treasury);
        _removeTemporaryRegistryProvider(
            deploy.policyEngine, deploy.providerPolicy, deployer, networkConfig.kycProvider
        );

        deploy.shareKycPolicy = _configureShareKycPolicies(
            deploy.policyEngine,
            deploy.identityRegistry,
            deploy.credentialRegistry,
            deploy.yieldcoinProxy,
            deploy.terminalAllow
        );

        deploy.shareSupplyPolicy = _configureSharePolicies(
            deploy.policyEngine,
            deploy.yieldcoinProxy,
            deploy.parentVaultProxy,
            deploy.terminalAllow,
            networkConfig.roles.configOperator,
            networkConfig.roles.policy.engineManager,
            networkConfig.roles.complianceOperator,
            networkConfig.roles.pauser,
            networkConfig.roles.unpauser
        );

        deploy.parentVaultProxy.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.parentVaultProxy.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.parentVaultProxy.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.parentVaultProxy.grantRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator);
        deploy.parentVaultProxy.grantRole(Roles.REWARDS_OPERATOR_ROLE, networkConfig.roles.rewardsOperator);

        deploy.parentVaultProxy.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        deploy.adapterRegistry.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.parentVaultProxy.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.adapterRegistry.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }
        _handoffACERoles(
            deploy.policyEngine,
            deploy.identityRegistry,
            deploy.credentialRegistry,
            deployer,
            networkConfig.roles.defaultAdmin,
            networkConfig.roles.policy.admin,
            networkConfig.roles.policy.configAdmin
        );
    }

    /*//////////////////////////////////////////////////////////////
                                  ACE
    //////////////////////////////////////////////////////////////*/
    function _deployACEComponents(address temporaryOwner)
        internal
        returns (PolicyEngine policyEngine, IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry)
    {
        /// @dev Deploy PolicyEngine
        PolicyEngine policyEngineImpl = new PolicyEngine();
        /// @dev We set the default to false to reject by default.
        ///      This requires a Terminal policy that explicitly allows the action, otherwise the policy protected action would revert by default.
        bytes memory policyEngineData = abi.encodeWithSelector(PolicyEngine.initialize.selector, false, temporaryOwner);
        ERC1967Proxy policyEngineProxy = new ERC1967Proxy(address(policyEngineImpl), policyEngineData);
        policyEngine = PolicyEngine(address(policyEngineProxy));

        /// @dev Deploy IdentityRegistry
        IdentityRegistry identityRegistryImpl = new IdentityRegistry();
        bytes memory identityRegistryData =
            abi.encodeWithSelector(IdentityRegistry.initialize.selector, address(policyEngine), temporaryOwner);
        ERC1967Proxy identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), identityRegistryData);
        identityRegistry = IdentityRegistry(address(identityRegistryProxy));
        /// @dev Deploy CredentialRegistry
        CredentialRegistry credentialRegistryImpl = new CredentialRegistry();
        bytes memory credentialRegistryData =
            abi.encodeWithSelector(CredentialRegistry.initialize.selector, address(policyEngine), temporaryOwner);
        ERC1967Proxy credentialRegistryProxy = new ERC1967Proxy(address(credentialRegistryImpl), credentialRegistryData);
        credentialRegistry = CredentialRegistry(address(credentialRegistryProxy));
    }

    function _deployTerminalAllowPolicy(PolicyEngine policyEngine)
        internal
        returns (TerminalAllowPolicy terminalAllow)
    {
        TerminalAllowPolicy terminalAllowImpl = new TerminalAllowPolicy();
        ERC1967Proxy terminalAllowProxy = new ERC1967Proxy(
            address(terminalAllowImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
            )
        );
        terminalAllow = TerminalAllowPolicy(address(terminalAllowProxy));
    }

    function _deployYieldcoinShareFrozenAccountPolicy(PolicyEngine policyEngine, YieldcoinShare yieldcoin)
        internal
        returns (YieldcoinShareFrozenAccountPolicy frozenAccountPolicy)
    {
        YieldcoinShareFrozenAccountPolicy frozenAccountPolicyImpl =
            new YieldcoinShareFrozenAccountPolicy(address(yieldcoin));
        ERC1967Proxy frozenAccountPolicyProxy = new ERC1967Proxy(
            address(frozenAccountPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
            )
        );
        frozenAccountPolicy = YieldcoinShareFrozenAccountPolicy(address(frozenAccountPolicyProxy));
    }

    function _buildKycCredentialRequirements(IdentityRegistry identityRegistry, CredentialRegistry credentialRegistry)
        internal
        pure
        returns (
            ICredentialRequirements.CredentialSourceInput[] memory sources,
            ICredentialRequirements.CredentialRequirementInput[] memory requirements
        )
    {
        /// @dev Values used in CredentialRegistryIdentityValidatorPolicyTest.t.sol
        bytes32 kycCredential = keccak256("common.kyc");
        bytes32 kycRequirement = keccak256("KYC");

        sources = new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = ICredentialRequirements.CredentialSourceInput({
            credentialTypeId: kycCredential,
            identityRegistry: address(identityRegistry),
            credentialRegistry: address(credentialRegistry),
            /// @dev address(0) means credential existence is sufficient — no data-field validation.
            ///      To enforce jurisdiction, accreditation type, or other content-level checks,
            ///      replace this with a custom CredentialDataValidator implementation.
            dataValidator: address(0)
        });

        bytes32[] memory requiredCredentials = new bytes32[](1);
        requiredCredentials[0] = kycCredential;
        requirements = new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = ICredentialRequirements.CredentialRequirementInput({
            requirementId: kycRequirement, credentialTypeIds: requiredCredentials, minValidations: 1, invert: false
        });
    }

    function _configureVaultKycPolicies(
        PolicyEngine policyEngine,
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        YieldcoinShareFrozenAccountPolicy frozenAccountPolicy,
        ParentVault parentVault,
        TerminalAllowPolicy terminalAllow
    ) internal returns (CredentialRegistryIdentityValidatorPolicy kycPolicy) {
        (
            ICredentialRequirements.CredentialSourceInput[] memory sources,
            ICredentialRequirements.CredentialRequirementInput[] memory requirements
        ) = _buildKycCredentialRequirements(identityRegistry, credentialRegistry);

        /// @dev KYC Policy
        CredentialRegistryIdentityValidatorPolicy kycPolicyImpl = new CredentialRegistryIdentityValidatorPolicy();
        ERC1967Proxy kycPolicyProxy = new ERC1967Proxy(
            address(kycPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector,
                address(policyEngine),
                address(policyEngine),
                abi.encode(sources, requirements)
            )
        );
        kycPolicy = CredentialRegistryIdentityValidatorPolicy(address(kycPolicyProxy));

        /// @dev Extract msg.sender from the policy engine payload
        SenderExtractor senderExtractor = new SenderExtractor();

        /// @dev ParentVault selectors to be protected by the KYC Policy
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = ParentVault.deposit.selector;
        selectors[1] = ParentVault.withdraw.selector;
        selectors[2] = ParentVault.claimShares.selector;
        selectors[3] = ParentVault.claimAsset.selector;
        selectors[4] = ParentVault.cancelDeposit.selector;
        selectors[5] = ParentVault.cancelWithdraw.selector;

        /// @dev Extract msg.sender for each of those selectors
        policyEngine.setExtractors(selectors, address(senderExtractor));
        bytes32[] memory senderParameter = new bytes32[](1);
        senderParameter[0] = senderExtractor.PARAM_SENDER();

        bytes32[] memory noParameters = new bytes32[](0);
        for (uint256 i; i < selectors.length; ++i) {
            policyEngine.addPolicy(address(parentVault), selectors[i], address(frozenAccountPolicy), senderParameter);
            policyEngine.addPolicy(address(parentVault), selectors[i], address(kycPolicy), senderParameter);
            policyEngine.addPolicy(address(parentVault), selectors[i], address(terminalAllow), noParameters);
        }
    }

    function _configureShareKycPolicies(
        PolicyEngine policyEngine,
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        YieldcoinShare yieldcoin,
        TerminalAllowPolicy terminalAllow
    ) internal returns (CredentialRegistryAccountListValidatorPolicy shareKycPolicy) {
        (
            ICredentialRequirements.CredentialSourceInput[] memory sources,
            ICredentialRequirements.CredentialRequirementInput[] memory requirements
        ) = _buildKycCredentialRequirements(identityRegistry, credentialRegistry);

        CredentialRegistryAccountListValidatorPolicy shareKycPolicyImpl =
            new CredentialRegistryAccountListValidatorPolicy();
        ERC1967Proxy shareKycPolicyProxy = new ERC1967Proxy(
            address(shareKycPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector,
                address(policyEngine),
                address(policyEngine),
                abi.encode(sources, requirements)
            )
        );
        shareKycPolicy = CredentialRegistryAccountListValidatorPolicy(address(shareKycPolicyProxy));

        YieldcoinShareKycExtractor extractor = new YieldcoinShareKycExtractor();

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = ComplianceTokenERC3643.transfer.selector;
        selectors[1] = ComplianceTokenERC3643.transferFrom.selector;
        selectors[2] = ComplianceTokenERC3643.batchTransfer.selector;
        selectors[3] = ComplianceTokenERC3643.approve.selector;
        selectors[4] = ComplianceTokenERC3643.increaseAllowance.selector;
        selectors[5] = ComplianceTokenERC3643.decreaseAllowance.selector;

        policyEngine.setExtractors(selectors, address(extractor));

        bytes32[] memory kycAccounts = new bytes32[](1);
        kycAccounts[0] = extractor.PARAM_KYC_ACCOUNTS();

        bytes32[] memory noParameters = new bytes32[](0);
        for (uint256 i; i < selectors.length; ++i) {
            policyEngine.addPolicy(address(yieldcoin), selectors[i], address(shareKycPolicy), kycAccounts);
            policyEngine.addPolicy(address(yieldcoin), selectors[i], address(terminalAllow), noParameters);
        }
    }

    function _configureSharePolicies(
        PolicyEngine policyEngine,
        YieldcoinShare yieldcoin,
        ParentVault parentVault,
        TerminalAllowPolicy terminalAllow,
        address configOperator,
        address policyEngineManager,
        address complianceOperator,
        address pauser,
        address unpauser
    ) internal returns (RoleBasedAccessControlPolicy shareSupplyPolicy) {
        RoleBasedAccessControlPolicy shareSupplyPolicyImpl = new RoleBasedAccessControlPolicy();
        ERC1967Proxy shareSupplyPolicyProxy = new ERC1967Proxy(
            address(shareSupplyPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
            )
        );
        shareSupplyPolicy = RoleBasedAccessControlPolicy(address(shareSupplyPolicyProxy));

        // Supply
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.mint.selector,
            Roles.MINTER_ROLE,
            address(parentVault)
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.burn.selector,
            Roles.BURNER_ROLE,
            address(parentVault)
        );
        // Admin
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            YieldcoinShare.setCCIPAdmin.selector,
            Roles.CONFIG_OPERATOR_ROLE,
            configOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            YieldcoinShare.attachPolicyEngine.selector,
            Roles.POLICY_ENGINE_MANAGER_ROLE,
            policyEngineManager
        );
        // Metadata setters
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.setName.selector,
            Roles.CONFIG_OPERATOR_ROLE,
            configOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.setSymbol.selector,
            Roles.CONFIG_OPERATOR_ROLE,
            configOperator
        );
        // Pause/unpause
        _configureShareRole(
            policyEngine, shareSupplyPolicy, ComplianceTokenERC3643.pause.selector, Roles.PAUSER_ROLE, pauser
        );
        _configureShareRole(
            policyEngine, shareSupplyPolicy, ComplianceTokenERC3643.unpause.selector, Roles.UNPAUSER_ROLE, unpauser
        );
        // Compliance operations (batch selectors wired separately: runPolicy uses msg.sig of the outer call)
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.forcedTransfer.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.batchForcedTransfer.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.batchSetAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.freezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.batchFreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.unfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );
        _configureShareRole(
            policyEngine,
            shareSupplyPolicy,
            ComplianceTokenERC3643.batchUnfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            complianceOperator
        );

        bytes32[] memory noParameters = new bytes32[](0);
        bytes4[] memory protectedSelectors = new bytes4[](16);
        protectedSelectors[0] = ComplianceTokenERC3643.mint.selector;
        protectedSelectors[1] = ComplianceTokenERC3643.burn.selector;
        protectedSelectors[2] = YieldcoinShare.setCCIPAdmin.selector;
        protectedSelectors[3] = YieldcoinShare.attachPolicyEngine.selector;
        protectedSelectors[4] = ComplianceTokenERC3643.setName.selector;
        protectedSelectors[5] = ComplianceTokenERC3643.setSymbol.selector;
        protectedSelectors[6] = ComplianceTokenERC3643.pause.selector;
        protectedSelectors[7] = ComplianceTokenERC3643.unpause.selector;
        protectedSelectors[8] = ComplianceTokenERC3643.forcedTransfer.selector;
        protectedSelectors[9] = ComplianceTokenERC3643.batchForcedTransfer.selector;
        protectedSelectors[10] = ComplianceTokenERC3643.setAddressFrozen.selector;
        protectedSelectors[11] = ComplianceTokenERC3643.batchSetAddressFrozen.selector;
        protectedSelectors[12] = ComplianceTokenERC3643.freezePartialTokens.selector;
        protectedSelectors[13] = ComplianceTokenERC3643.batchFreezePartialTokens.selector;
        protectedSelectors[14] = ComplianceTokenERC3643.unfreezePartialTokens.selector;
        protectedSelectors[15] = ComplianceTokenERC3643.batchUnfreezePartialTokens.selector;
        for (uint256 i; i < protectedSelectors.length; ++i) {
            _addSharePolicyPair(
                policyEngine, yieldcoin, terminalAllow, protectedSelectors[i], address(shareSupplyPolicy), noParameters
            );
        }
    }

    function _configureShareRole(
        PolicyEngine policyEngine,
        RoleBasedAccessControlPolicy policy,
        bytes4 selector,
        bytes32 role,
        address account
    ) internal {
        policyEngine.setPolicyConfiguration(
            address(policy),
            policyEngine.getPolicyConfigVersion(address(policy)),
            RoleBasedAccessControlPolicy.grantOperationAllowanceToRole.selector,
            abi.encode(selector, role)
        );
        policyEngine.setPolicyConfiguration(
            address(policy),
            policyEngine.getPolicyConfigVersion(address(policy)),
            RBAC_GRANT_ROLE_SELECTOR,
            abi.encode(role, account)
        );
    }

    function _addSharePolicyPair(
        PolicyEngine policyEngine,
        YieldcoinShare yieldcoin,
        TerminalAllowPolicy terminalAllow,
        bytes4 selector,
        address rbacPolicy,
        bytes32[] memory noParameters
    ) internal {
        policyEngine.addPolicy(address(yieldcoin), selector, rbacPolicy, noParameters);
        policyEngine.addPolicy(address(yieldcoin), selector, address(terminalAllow), noParameters);
    }

    function _configureRegistryProviderPolicies(
        PolicyEngine policyEngine,
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        TerminalAllowPolicy terminalAllow,
        address provider,
        address temporaryProvider
    ) internal returns (OnlyAuthorizedSenderPolicy providerPolicy) {
        OnlyAuthorizedSenderPolicy providerPolicyImpl = new OnlyAuthorizedSenderPolicy();
        ERC1967Proxy providerPolicyProxy = new ERC1967Proxy(
            address(providerPolicyImpl),
            abi.encodeWithSelector(
                Policy.initialize.selector, address(policyEngine), address(policyEngine), new bytes(0)
            )
        );
        providerPolicy = OnlyAuthorizedSenderPolicy(address(providerPolicyProxy));

        policyEngine.setPolicyConfiguration(
            address(providerPolicy),
            policyEngine.getPolicyConfigVersion(address(providerPolicy)),
            AUTHORIZE_SENDER_SELECTOR,
            abi.encode(provider)
        );
        if (temporaryProvider != provider) {
            policyEngine.setPolicyConfiguration(
                address(providerPolicy),
                policyEngine.getPolicyConfigVersion(address(providerPolicy)),
                AUTHORIZE_SENDER_SELECTOR,
                abi.encode(temporaryProvider)
            );
        }

        bytes4[] memory identitySelectors = new bytes4[](3);
        identitySelectors[0] = IdentityRegistry.registerIdentity.selector;
        identitySelectors[1] = IdentityRegistry.registerIdentities.selector;
        identitySelectors[2] = IdentityRegistry.removeIdentity.selector;

        bytes4[] memory credentialSelectors = new bytes4[](4);
        credentialSelectors[0] = CredentialRegistry.registerCredential.selector;
        credentialSelectors[1] = CredentialRegistry.registerCredentials.selector;
        credentialSelectors[2] = CredentialRegistry.removeCredential.selector;
        credentialSelectors[3] = CredentialRegistry.renewCredential.selector;

        bytes32[] memory noParameters = new bytes32[](0);
        for (uint256 i; i < identitySelectors.length; ++i) {
            policyEngine.addPolicy(
                address(identityRegistry), identitySelectors[i], address(providerPolicy), noParameters
            );
            policyEngine.addPolicy(
                address(identityRegistry), identitySelectors[i], address(terminalAllow), noParameters
            );
        }
        for (uint256 i; i < credentialSelectors.length; ++i) {
            policyEngine.addPolicy(
                address(credentialRegistry), credentialSelectors[i], address(providerPolicy), noParameters
            );
            policyEngine.addPolicy(
                address(credentialRegistry), credentialSelectors[i], address(terminalAllow), noParameters
            );
        }
    }

    function _registerSystemKyc(
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        bytes32 ccid,
        address account
    ) internal {
        /// @dev `ccid` is supplied by HelperConfig so production deployments can coordinate
        ///      the ParentVault system identity with the KYC provider instead of deriving it onchain.
        identityRegistry.registerIdentity(ccid, account, "");
        credentialRegistry.registerCredential(ccid, KYC_CREDENTIAL, 0, "", "");
    }

    function _removeTemporaryRegistryProvider(
        PolicyEngine policyEngine,
        OnlyAuthorizedSenderPolicy providerPolicy,
        address temporaryProvider,
        address provider
    ) internal {
        if (temporaryProvider == provider) return;

        policyEngine.setPolicyConfiguration(
            address(providerPolicy),
            policyEngine.getPolicyConfigVersion(address(providerPolicy)),
            UNAUTHORIZE_SENDER_SELECTOR,
            abi.encode(temporaryProvider)
        );
    }

    function _handoffACERoles(
        PolicyEngine policyEngine,
        IdentityRegistry identityRegistry,
        CredentialRegistry credentialRegistry,
        address deployer,
        address finalDefaultAdmin,
        address finalPolicyAdmin,
        address finalPolicyConfigAdmin
    ) internal {
        if (deployer != finalDefaultAdmin) {
            policyEngine.grantRole(policyEngine.DEFAULT_ADMIN_ROLE(), finalDefaultAdmin);
        }
        if (deployer != finalPolicyAdmin) {
            policyEngine.grantRole(policyEngine.ADMIN_ROLE(), finalPolicyAdmin);
        }
        if (deployer != finalPolicyConfigAdmin) {
            policyEngine.grantRole(policyEngine.POLICY_CONFIG_ADMIN_ROLE(), finalPolicyConfigAdmin);
        }

        if (deployer != finalPolicyAdmin) {
            policyEngine.revokeRole(policyEngine.ADMIN_ROLE(), deployer);
        }
        if (deployer != finalPolicyConfigAdmin) {
            policyEngine.revokeRole(policyEngine.POLICY_CONFIG_ADMIN_ROLE(), deployer);
        }
        if (deployer != finalDefaultAdmin) {
            policyEngine.revokeRole(policyEngine.DEFAULT_ADMIN_ROLE(), deployer);
        }

        identityRegistry.transferOwnership(address(policyEngine));
        credentialRegistry.transferOwnership(address(policyEngine));
    }
}
