// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseWorkflowRouterUnitTest, Vm} from "../BaseWorkflowRouterUnitTest.t.sol";

import {IWorkflowRouter} from "../../../../src/interfaces/IWorkflowRouter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract WorkflowRouter_SetWorkflowSelectorsUnitTest is BaseWorkflowRouterUnitTest {
    bytes32 internal constant WORKFLOW_ID = keccak256("workflow-1");
    bytes4 internal constant SELECTOR_1 = bytes4(keccak256("deposit(uint256)"));
    bytes4 internal constant SELECTOR_2 = bytes4(keccak256("withdraw(uint256)"));

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_WorkflowRouter_setWorkflowSelectors_RevertWhen_CallerDoesNotHaveConfigOperatorRole() external {
        _changePrank(i_nonOwner);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SELECTOR_1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);
    }

    function test_WorkflowRouter_setWorkflowSelectors_RevertWhen_WorkflowIdIsZero() external {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SELECTOR_1;

        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroWorkflowId.selector);
        s_workflowRouter.setWorkflowSelectors(bytes32(0), selectors, true);
    }

    function test_WorkflowRouter_setWorkflowSelectors_Success_AllowlistsSelector() external {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SELECTOR_1;

        vm.recordLogs();
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);

        assertEq(s_workflowRouter.getAllowlistedWorkflowSelector(WORKFLOW_ID, SELECTOR_1), true);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WorkflowSelectorSet(bytes32,bytes4,bool)"), address(s_workflowRouter));
        assertEq(log.topics[1], WORKFLOW_ID);
        assertEq(log.topics[2], bytes32(SELECTOR_1));
        assertEq(log.topics[3], bytes32(uint256(1)));
    }

    function test_WorkflowRouter_setWorkflowSelectors_Success_RemovesSelectorFromAllowlist() external {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SELECTOR_1;
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);

        vm.recordLogs();
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, false);

        assertEq(s_workflowRouter.getAllowlistedWorkflowSelector(WORKFLOW_ID, SELECTOR_1), false);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WorkflowSelectorSet(bytes32,bytes4,bool)"), address(s_workflowRouter));
        assertEq(log.topics[1], WORKFLOW_ID);
        assertEq(log.topics[2], bytes32(SELECTOR_1));
        assertEq(log.topics[3], bytes32(0));
    }

    function test_WorkflowRouter_setWorkflowSelectors_Success_MultipleSelectors() external {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SELECTOR_1;
        selectors[1] = SELECTOR_2;

        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);

        assertEq(s_workflowRouter.getAllowlistedWorkflowSelector(WORKFLOW_ID, SELECTOR_1), true);
        assertEq(s_workflowRouter.getAllowlistedWorkflowSelector(WORKFLOW_ID, SELECTOR_2), true);
    }
}
