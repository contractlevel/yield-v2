// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../BaseIntegrationTest.t.sol";

import {Roles} from "../../../src/libraries/Roles.sol";

contract ParentVault_DeploymentIntegrationTest is BaseIntegrationTest {
    function setUp() public override {
        super.setUp();
        _deployParent();
    }

    function test_ParentVault_deployment_GrantsExpectedVaultRoles() external view {
        assertEq(parent.vault.defaultAdmin(), address(this));
        assertTrue(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
        assertTrue(parent.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer));
        assertTrue(parent.vault.hasRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator));
        assertTrue(parent.vault.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(parent.vault.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(parent.vault.hasRole(Roles.POLICY_ENGINE_MANAGER_ROLE, networkConfig.roles.policyEngineManager));
    }

    function test_ParentVault_deployment_HandsOffVaultDefaultAdmin() external view {
        (address pendingAdmin, uint48 schedule) = parent.vault.pendingDefaultAdmin();

        assertEq(parent.vault.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + parent.vault.defaultAdminDelay());
    }

    function test_ParentVault_deployment_ConfiguresCoreAddresses() external view {
        assertEq(parent.vault.getAdapterRegistry(), address(parent.adapterRegistry));
        assertEq(parent.vault.getShare(), address(parent.share));
        assertEq(parent.vault.getTreasury(), networkConfig.treasury);
        assertEq(parent.vault.getUsdc(), parent.usdc);
        assertEq(parent.vault.getLink(), parent.link);
        assertEq(parent.vault.getThisChainSelector(), networkConfig.ccip.parentChainSelector);
    }

    function test_ParentVault_deployment_ConfiguresShareInitialState() external view {
        assertGt(address(parent.shareImpl).code.length, 0);
        assertGt(address(parent.share).code.length, 0);
        assertNotEq(address(parent.shareImpl), address(parent.share));
        assertEq(parent.share.getPolicyEngine(), address(parent.policyEngine));
        assertEq(parent.share.getCCIPAdmin(), networkConfig.roles.configOperator);
    }

    function test_ParentVault_deployment_RegistersAdapters() external view {
        _assertAdapterRegistered(parent.adapterRegistry, AAVE_V3_PROTOCOL_ID, address(parent.aaveV3Adapter));
        _assertAdapterRegistered(parent.adapterRegistry, AAVE_V4_PROTOCOL_ID, address(parent.aaveV4Adapter));
    }

    function test_ParentVault_deployment_ConfiguresAdapters() external view {
        _assertProtocolAdapterConfigured(parent.aaveV3Adapter, address(parent.vault), parent.usdc);
        assertEq(parent.aaveV3Adapter.getPoolAddressesProvider(), parent.aaveV3PoolAddressesProvider);

        _assertProtocolAdapterConfigured(parent.aaveV4Adapter, address(parent.vault), parent.usdc);
        assertEq(parent.aaveV4Adapter.getProtocolPool(), parent.aaveV4Spoke);
        assertEq(parent.aaveV4Adapter.getReserveId(), parent.aaveV4ReserveId);
    }

    function test_ParentVault_deployment_ConfiguresAdapterRegistryRoles() external view {
        (address pendingAdmin, uint48 schedule) = parent.adapterRegistry.pendingDefaultAdmin();

        assertEq(parent.adapterRegistry.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + parent.adapterRegistry.defaultAdminDelay());
        assertTrue(parent.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(parent.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
    }

    function test_ParentVault_deployment_SetsInitialActiveAdapter() external view {
        assertTrue(parent.vault.getInitialActiveProtocolAdapterSet());
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
    }

    function test_ParentVault_deployment_ConfiguresWorkflowRouter() external view {
        assertEq(parent.workflowRouter.getVault(), address(parent.vault));
        assertEq(parent.workflowRouter.defaultAdmin(), networkConfig.roles.defaultAdmin);
        assertEq(parent.workflowRouter.defaultAdminDelay(), INITIAL_DEFAULT_ADMIN_DELAY);
        assertTrue(parent.workflowRouter.hasRole(Roles.DEFAULT_ADMIN_ROLE, networkConfig.roles.defaultAdmin));
        assertTrue(parent.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(parent.workflowRouter.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(parent.workflowRouter.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(parent.workflowRouter.hasRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder));
    }

    function test_ParentVault_deployment_ConfiguresACEComponents() external view {
        assertEq(parent.vault.getPolicyEngine(), address(parent.policyEngine));
        assertEq(parent.share.getPolicyEngine(), address(parent.policyEngine));
        assertTrue(
            parent.policyEngine.hasRole(parent.policyEngine.DEFAULT_ADMIN_ROLE(), networkConfig.roles.defaultAdmin)
        );
        assertTrue(parent.policyEngine.hasRole(parent.policyEngine.ADMIN_ROLE(), networkConfig.roles.policyAdmin));
        assertTrue(
            parent.policyEngine
                .hasRole(parent.policyEngine.POLICY_CONFIG_ADMIN_ROLE(), networkConfig.roles.policyConfigAdmin)
        );
    }

    function test_ParentVault_deployment_RegistersParentVaultKyc() external view {
        bytes32 ccid = parent.vaultCcid;

        assertEq(parent.identityRegistry.getIdentity(address(parent.vault)), ccid);
        assertTrue(parent.vaultKycPolicy.validate(address(parent.vault), ""));
        assertTrue(parent.shareKycPolicy.validate(address(parent.vault), ""));
    }

    function test_ParentVault_deployment_RemovesTemporaryRegistryProvider() external view {
        assertTrue(parent.providerPolicy.senderAuthorized(networkConfig.kycProvider));
        assertFalse(parent.providerPolicy.senderAuthorized(address(this)));
    }

    function test_ParentVault_deployment_HandsOffACERoles() external view {
        assertTrue(
            parent.policyEngine.hasRole(parent.policyEngine.DEFAULT_ADMIN_ROLE(), networkConfig.roles.defaultAdmin)
        );
        assertTrue(parent.policyEngine.hasRole(parent.policyEngine.ADMIN_ROLE(), networkConfig.roles.policyAdmin));
        assertTrue(
            parent.policyEngine
                .hasRole(parent.policyEngine.POLICY_CONFIG_ADMIN_ROLE(), networkConfig.roles.policyConfigAdmin)
        );

        assertFalse(parent.policyEngine.hasRole(parent.policyEngine.DEFAULT_ADMIN_ROLE(), address(this)));
        assertFalse(parent.policyEngine.hasRole(parent.policyEngine.ADMIN_ROLE(), address(this)));
        assertFalse(parent.policyEngine.hasRole(parent.policyEngine.POLICY_CONFIG_ADMIN_ROLE(), address(this)));

        assertEq(parent.identityRegistry.owner(), address(parent.policyEngine));
        assertEq(parent.identityRegistry.getPolicyEngine(), address(parent.policyEngine));
        assertEq(parent.credentialRegistry.owner(), address(parent.policyEngine));
        assertEq(parent.credentialRegistry.getPolicyEngine(), address(parent.policyEngine));
    }
}
