// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest} from "../BaseWorkflowRouterUnitTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

contract WorkflowRouter_ConstructorUnitTest is BaseWorkflowRouterUnitTest {
    function test_WorkflowRouter_constructor_SetsVault() public {
        assertEq(s_workflowRouter.getVault(), address(s_target));
        assertEq(s_workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator), true);
    }
}
