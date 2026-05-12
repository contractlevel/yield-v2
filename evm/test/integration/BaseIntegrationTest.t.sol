// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTest} from "../BaseTest.t.sol";

import {DeployParent} from "../../script/deploy/DeployParent.s.sol";
import {DeployChild} from "../../script/deploy/DeployChild.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {ParentVault} from "../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";
import {Roles} from "../../src/libraries/Roles.sol";

import {CredentialRegistry} from "@chainlink/cross-chain-identity/CredentialRegistry.sol";
import {IdentityRegistry} from "@chainlink/cross-chain-identity/IdentityRegistry.sol";
import {
    CredentialRegistryIdentityValidatorPolicy
} from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidatorPolicy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {OnlyAuthorizedSenderPolicy} from "@chainlink/policy-management/policies/OnlyAuthorizedSenderPolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";

import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {TerminalAllowPolicy} from "../../src/modules/policies/TerminalAllowPolicy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseIntegrationTest is BaseTest {
    struct Parent {
        address link;
        address usdc;
        bytes32 vaultCcid;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        uint256 aaveV4ReserveId;
        AdapterRegistry adapterRegistry;
        YieldcoinShare shareImpl;
        YieldcoinShare share;
        ParentVault vault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        WorkflowRouter workflowRouter;
        PolicyEngine policyEngine;
        IdentityRegistry identityRegistry;
        CredentialRegistry credentialRegistry;
        CredentialRegistryIdentityValidatorPolicy vaultKycPolicy;
        CredentialRegistryAccountListValidatorPolicy shareKycPolicy;
        RoleBasedAccessControlPolicy shareSupplyPolicy;
        OnlyAuthorizedSenderPolicy providerPolicy;
        TerminalAllowPolicy terminalAllow;
    }

    struct Child {
        address link;
        address usdc;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        uint256 aaveV4ReserveId;
        AdapterRegistry adapterRegistry;
        ChildVault vault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        WorkflowRouter workflowRouter;
    }

    Parent internal parent;
    Child internal child;

    HelperConfig internal helperConfig;
    HelperConfig.NetworkConfig internal networkConfig;

    function setUp() public virtual {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getActiveNetworkConfig();

        DeployParent.Deployment memory parentDeployment = new DeployParent().run();
        parent = Parent({
            link: parentDeployment.link,
            usdc: parentDeployment.usdc,
            vaultCcid: parentDeployment.vaultCcid,
            aaveV3PoolAddressesProvider: parentDeployment.aaveV3PoolAddressesProvider,
            aaveV4Spoke: parentDeployment.aaveV4Spoke,
            aaveV4ReserveId: parentDeployment.aaveV4ReserveId,
            adapterRegistry: parentDeployment.adapterRegistry,
            shareImpl: parentDeployment.yieldcoinImpl,
            share: parentDeployment.yieldcoinProxy,
            vault: parentDeployment.parentVault,
            aaveV3Adapter: parentDeployment.aaveV3Adapter,
            aaveV4Adapter: parentDeployment.aaveV4Adapter,
            workflowRouter: parentDeployment.workflowRouter,
            policyEngine: parentDeployment.policyEngine,
            identityRegistry: parentDeployment.identityRegistry,
            credentialRegistry: parentDeployment.credentialRegistry,
            vaultKycPolicy: parentDeployment.vaultKycPolicy,
            shareKycPolicy: parentDeployment.shareKycPolicy,
            shareSupplyPolicy: parentDeployment.shareSupplyPolicy,
            providerPolicy: parentDeployment.providerPolicy,
            terminalAllow: parentDeployment.terminalAllow
        });

        DeployChild.Deployment memory childDeployment = new DeployChild().run();
        child = Child({
            link: childDeployment.link,
            usdc: childDeployment.usdc,
            aaveV3PoolAddressesProvider: childDeployment.aaveV3PoolAddressesProvider,
            aaveV4Spoke: childDeployment.aaveV4Spoke,
            aaveV4ReserveId: childDeployment.aaveV4ReserveId,
            adapterRegistry: childDeployment.adapterRegistry,
            vault: childDeployment.childVault,
            aaveV3Adapter: childDeployment.aaveV3Adapter,
            aaveV4Adapter: childDeployment.aaveV4Adapter,
            workflowRouter: childDeployment.workflowRouter
        });

        _labelIntegrationContracts();
    }

    function _expectPolicyRevert() internal {
        vm.expectPartialRevert(IPolicyEngine.PolicyRunRejected.selector);
    }

    function _registerKyc(address account) internal {
        bytes32 ccid = keccak256(abi.encodePacked(account));

        _changePrank(networkConfig.kycProvider);
        parent.identityRegistry.registerIdentity(ccid, account, "");
        parent.credentialRegistry.registerCredential(ccid, KYC_CREDENTIAL, 0, "", "");
        vm.stopPrank();
    }

    function _fundAndApproveUsdc(address account, uint256 amount) internal {
        deal(parent.vault.getUsdc(), account, amount);
        _changePrank(account);
        IERC20(parent.vault.getUsdc()).approve(address(parent.vault), amount);
        vm.stopPrank();
    }

    function _mintShares(address account, uint256 amount) internal {
        _changePrank(address(parent.vault));
        parent.share.mint(account, amount);
        vm.stopPrank();
    }

    function _approveShares(address owner, address spender, uint256 amount) internal {
        _changePrank(owner);
        parent.share.approve(spender, amount);
        vm.stopPrank();
    }

    function _assertAdapterRegistered(AdapterRegistry registry, bytes32 protocolId, address adapter) internal view {
        assertEq(registry.getAdapter(protocolId), adapter);
    }

    function _assertProtocolAdapterConfigured(IProtocolAdapter adapter, address vault, address usdc) internal view {
        assertEq(adapter.getVault(), vault);
        assertEq(adapter.getUsdc(), usdc);
    }

    function _assertPolicyPair(address target, bytes4 selector, address firstPolicy) internal view {
        address[] memory policies = parent.policyEngine.getPolicies(target, selector);
        assertEq(policies.length, 2);
        assertEq(policies[0], firstPolicy);
        assertEq(policies[1], address(parent.terminalAllow));
    }

    function _assertParentVaultKycPolicy(bytes4 selector) internal view {
        _assertPolicyPair(address(parent.vault), selector, address(parent.vaultKycPolicy));
    }

    function _assertShareKycPolicy(bytes4 selector) internal view {
        _assertPolicyPair(address(parent.share), selector, address(parent.shareKycPolicy));
    }

    function _assertShareRbacPolicy(bytes4 selector, bytes32 role, address account) internal view {
        _assertPolicyPair(address(parent.share), selector, address(parent.shareSupplyPolicy));
        assertTrue(parent.shareSupplyPolicy.hasAllowedRole(selector, account));
        assertTrue(parent.shareSupplyPolicy.hasRole(role, account));
    }

    function _labelIntegrationContracts() internal {
        vm.label(address(parent.vault), "Integration ParentVault");
        vm.label(address(parent.share), "Integration YieldcoinShare");
        vm.label(address(parent.policyEngine), "Integration PolicyEngine");
        vm.label(address(parent.identityRegistry), "Integration IdentityRegistry");
        vm.label(address(parent.credentialRegistry), "Integration CredentialRegistry");
        vm.label(address(parent.vaultKycPolicy), "Integration ParentVault KYC Policy");
        vm.label(address(parent.shareKycPolicy), "Integration Share KYC Policy");
        vm.label(address(parent.shareSupplyPolicy), "Integration Share RBAC Policy");
        vm.label(address(parent.terminalAllow), "Integration TerminalAllowPolicy");
        vm.label(address(child.vault), "Integration ChildVault");
    }

    function test_baseIntegrationTest() public virtual {}
}
