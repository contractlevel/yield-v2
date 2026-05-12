// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest} from "../BaseWorkflowRouterUnitTest.t.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

contract WorkflowRouter_ConstructorUnitTest is BaseWorkflowRouterUnitTest {
    function test_WorkflowRouter_constructor_SetsVault() public view {
        assertEq(s_workflowRouter.getVault(), address(s_target));
    }

    function test_WorkflowRouter_constructor_GrantsDefaultAdminRole() public view {
        assertTrue(s_workflowRouter.hasRole(DEFAULT_ADMIN_ROLE, i_owner));
    }

    function test_WorkflowRouter_constructor_GrantsPauserRole() public view {
        assertTrue(s_workflowRouter.hasRole(Roles.PAUSER_ROLE, i_pauser));
    }

    function test_WorkflowRouter_constructor_GrantsUnpauserRole() public view {
        assertTrue(s_workflowRouter.hasRole(Roles.UNPAUSER_ROLE, i_unpauser));
    }

    function test_WorkflowRouter_constructor_GrantsConfigOperatorRole() public view {
        assertTrue(s_workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator));
    }

    function test_WorkflowRouter_constructor_GrantsKeystoneForwarderRole() public view {
        assertTrue(s_workflowRouter.hasRole(Roles.KEYSTONE_FORWARDER_ROLE, i_keystoneForwarder));
    }
}
