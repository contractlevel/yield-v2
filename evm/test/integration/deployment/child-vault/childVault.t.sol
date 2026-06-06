// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

contract ChildVault_DeploymentIntegrationTest is BaseIntegrationTest {
    function setUp() public override {
        super.setUp();
        _deployChild();
    }

    function test_ChildVault_deployment_GrantsExpectedVaultRoles() external view {
        assertEq(child.vault.defaultAdmin(), address(this));
        assertTrue(child.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(child.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
        assertTrue(child.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(child.workflowRouter)));
        assertTrue(child.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(child.workflowRouter)));
        assertTrue(child.vault.hasRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer));
        assertTrue(child.vault.hasRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator));
        assertTrue(child.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, networkConfig.roles.donateOperator));
        assertFalse(child.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, address(this)));
        assertEq(child.vault.getEmergencyReceiver(), networkConfig.emergencyReceiver);
        assertTrue(child.vault.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(child.vault.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
    }

    function test_ChildVault_deployment_HandsOffVaultDefaultAdmin() external view {
        (address pendingAdmin, uint48 schedule) = child.vault.pendingDefaultAdmin();

        assertEq(child.vault.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + child.vault.defaultAdminDelay());
    }

    function test_ChildVault_deployment_ConfiguresCoreAddresses() external view {
        assertEq(child.vault.getAdapterRegistry(), address(child.adapterRegistry));
        assertEq(child.vault.getUsdc(), child.usdc);
        assertEq(child.vault.getLink(), child.link);
        assertEq(child.vault.getThisChainSelector(), networkConfig.ccip.thisChainSelector);
        assertEq(child.vault.getParentChainSelector(), networkConfig.ccip.parentChainSelector);
    }

    function test_ChildVault_deployment_SetsDefaultCcipGasLimit() external view {
        assertEq(child.vault.getDefaultCcipGasLimit(), networkConfig.ccip.initialDefaultCcipGasLimit);
    }

    function test_ChildVault_deployment_RegistersAdapters() external view {
        _assertOptionalAaveV3Adapter(
            child.adapterRegistry,
            child.aaveV3Adapter,
            child.aaveV3PoolAddressesProvider,
            address(child.vault),
            child.usdc
        );
        _assertOptionalAaveV4Adapter(
            child.adapterRegistry, child.aaveV4Adapter, child.aaveV4Spoke, address(child.vault), child.usdc
        );
        _assertOptionalCompoundV3Adapter(
            child.adapterRegistry, child.compoundV3Adapter, child.compoundV3Comet, address(child.vault), child.usdc
        );
    }

    function test_ChildVault_deployment_ConfiguresAdapters() external view {
        _assertOptionalAaveV3Adapter(
            child.adapterRegistry,
            child.aaveV3Adapter,
            child.aaveV3PoolAddressesProvider,
            address(child.vault),
            child.usdc
        );
        _assertOptionalAaveV4Adapter(
            child.adapterRegistry, child.aaveV4Adapter, child.aaveV4Spoke, address(child.vault), child.usdc
        );
        _assertOptionalCompoundV3Adapter(
            child.adapterRegistry, child.compoundV3Adapter, child.compoundV3Comet, address(child.vault), child.usdc
        );
    }

    function test_ChildVault_deployment_ConfiguresAdapterRegistryRoles() external view {
        (address pendingAdmin, uint48 schedule) = child.adapterRegistry.pendingDefaultAdmin();

        assertEq(child.adapterRegistry.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + child.adapterRegistry.defaultAdminDelay());
        assertTrue(child.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(child.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
    }

    function test_ChildVault_deployment_ConfiguresWorkflowRouter() external view {
        assertEq(child.workflowRouter.getVault(), address(child.vault));
        assertEq(child.workflowRouter.defaultAdmin(), networkConfig.roles.defaultAdmin);
        assertEq(child.workflowRouter.defaultAdminDelay(), INITIAL_DEFAULT_ADMIN_DELAY);
        assertTrue(child.workflowRouter.hasRole(Roles.DEFAULT_ADMIN_ROLE, networkConfig.roles.defaultAdmin));
        assertTrue(child.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(child.workflowRouter.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(child.workflowRouter.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(child.workflowRouter.hasRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder));
    }
}
