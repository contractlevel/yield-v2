// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest} from "../BaseWorkflowRouterUnitTest.t.sol";

contract WorkflowRouter_ConstructorUnitTest is BaseWorkflowRouterUnitTest {
    function test_WorkflowRouter_constructor_SetsVault() public view {
        assertEq(s_workflowRouter.getVault(), address(s_target));
    }
}
