// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseWorkflowRouterUnitTest} from "../BaseWorkflowRouterUnitTest.t.sol";
import {WorkflowRouter} from "../../../../src/modules/WorkflowRouter.sol";
import {IWorkflowRouter} from "../../../../src/interfaces/IWorkflowRouter.sol";
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

    function test_WorkflowRouter_constructor_RevertWhen_PauserIsZeroAddress() public {
        WorkflowRouter.ConstructorParams memory params = _workflowRouterParams();
        params.pauser = address(0);

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroAddress.selector);
        new WorkflowRouter(params);
    }

    function test_WorkflowRouter_constructor_RevertWhen_UnpauserIsZeroAddress() public {
        WorkflowRouter.ConstructorParams memory params = _workflowRouterParams();
        params.unpauser = address(0);

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroAddress.selector);
        new WorkflowRouter(params);
    }

    function test_WorkflowRouter_constructor_RevertWhen_ConfigOperatorIsZeroAddress() public {
        WorkflowRouter.ConstructorParams memory params = _workflowRouterParams();
        params.configOperator = address(0);

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroAddress.selector);
        new WorkflowRouter(params);
    }

    function test_WorkflowRouter_constructor_RevertWhen_KeystoneForwarderIsZeroAddress() public {
        WorkflowRouter.ConstructorParams memory params = _workflowRouterParams();
        params.keystoneForwarder = address(0);

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroAddress.selector);
        new WorkflowRouter(params);
    }

    function test_WorkflowRouter_constructor_RevertWhen_VaultIsZeroAddress() public {
        WorkflowRouter.ConstructorParams memory params = _workflowRouterParams();
        params.vault = address(0);

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroAddress.selector);
        new WorkflowRouter(params);
    }

    function _workflowRouterParams() internal view returns (WorkflowRouter.ConstructorParams memory params) {
        params = WorkflowRouter.ConstructorParams({
            initialDelay: 0,
            defaultAdmin: i_owner,
            pauser: i_pauser,
            unpauser: i_unpauser,
            configOperator: i_configOperator,
            keystoneForwarder: i_keystoneForwarder,
            vault: address(s_target)
        });
    }
}
