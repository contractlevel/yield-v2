// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

contract ChildVault_DeploymentIntegrationTest is BaseIntegrationTest {
    function test_ChildVault_deployment_GrantsExpectedVaultRoles() external view {
        assertTrue(child.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(child.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(child.workflowRouter)));
        assertTrue(child.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(child.workflowRouter)));
        assertTrue(child.vault.hasRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer));
        assertTrue(child.vault.hasRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator));
        assertTrue(child.vault.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(child.vault.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
    }

    function test_ChildVault_deployment_ConfiguresCoreAddresses() external view {
        assertEq(child.vault.getAdapterRegistry(), address(child.adapterRegistry));
        assertEq(child.vault.getUsdc(), child.usdc);
        assertEq(child.vault.getLink(), child.link);
        assertEq(child.vault.getThisChainSelector(), networkConfig.ccip.thisChainSelector);
        assertEq(child.vault.getParentChainSelector(), networkConfig.ccip.parentChainSelector);
    }

    function test_ChildVault_deployment_RegistersAdapters() external view {
        _assertAdapterRegistered(child.adapterRegistry, AAVE_V3_PROTOCOL_ID, address(child.aaveV3Adapter));
        _assertAdapterRegistered(child.adapterRegistry, AAVE_V4_PROTOCOL_ID, address(child.aaveV4Adapter));
    }

    function test_ChildVault_deployment_ConfiguresWorkflowRouter() external view {
        assertEq(child.workflowRouter.getVault(), address(child.vault));
        assertTrue(child.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(child.workflowRouter.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(child.workflowRouter.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(child.workflowRouter.hasRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder));
    }
}
