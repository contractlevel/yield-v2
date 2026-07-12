// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseWorkflowRouterUnitTest, WorkflowRouter, Vm, Target} from "../BaseWorkflowRouterUnitTest.t.sol";

import {IWorkflowRouter} from "../../../../src/interfaces/modules/IWorkflowRouter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract WorkflowRouter_OnReportUnitTest is BaseWorkflowRouterUnitTest {
    bytes32 internal constant WORKFLOW_ID = keccak256("workflow-1");
    bytes4 internal constant SELECTOR = bytes4(keccak256("deposit()"));
    bytes4 internal constant FAIL_SELECTOR = bytes4(keccak256("fail()"));

    function setUp() public {
        _changePrank(i_configOperator);
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, s_workflowName, i_owner);

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SELECTOR;
        selectors[1] = FAIL_SELECTOR;
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);

        _changePrank(i_keystoneForwarder);
    }

    function test_WorkflowRouter_onReport_RevertWhen_Paused()
        external
        givenContractIsPaused(address(s_workflowRouter))
    {
        vm.expectRevert(Pausable.EnforcedPause.selector);
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_CallerDoesNotHaveKeystoneForwarderRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.KEYSTONE_FORWARDER_ROLE
            )
        );
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_WorkflowIdIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataZero.selector, bytes32(0), s_workflowName, i_owner
            )
        );
        s_workflowRouter.onReport(_buildMetadata(bytes32(0), s_workflowName, i_owner), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_WorkflowNameIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataZero.selector, WORKFLOW_ID, bytes10(0), i_owner
            )
        );
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, bytes10(0), i_owner), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_WorkflowOwnerIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataZero.selector, WORKFLOW_ID, s_workflowName, address(0)
            )
        );
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, address(0)), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_WorkflowMetadataDoesNotMatch() external {
        bytes32 unknownWorkflow = keccak256("unknown");
        bytes10 unknownName = _createWorkflowName("unknown");
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataMismatch.selector, unknownWorkflow, unknownName, i_nonOwner
            )
        );
        s_workflowRouter.onReport(_buildMetadata(unknownWorkflow, unknownName, i_nonOwner), abi.encodePacked(SELECTOR));
    }

    function test_WorkflowRouter_onReport_RevertWhen_ReportIsTooShort() external {
        bytes memory shortReport = new bytes(3);
        vm.expectRevert(
            abi.encodeWithSelector(IWorkflowRouter.WorkflowRouter__ReportTooShort.selector, shortReport.length)
        );
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), shortReport);
    }

    function test_WorkflowRouter_onReport_RevertWhen_SelectorIsNotAllowlisted() external {
        bytes4 unknownSelector = bytes4(keccak256("unknown()"));
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__SelectorNotAllowlisted.selector, WORKFLOW_ID, unknownSelector
            )
        );
        s_workflowRouter.onReport(
            _buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), abi.encodePacked(unknownSelector)
        );
    }

    function test_WorkflowRouter_onReport_RevertWhen_CallFails() external {
        bytes memory targetError = abi.encodeWithSelector(Target.Target__Fail.selector);
        vm.expectRevert(abi.encodeWithSelector(IWorkflowRouter.WorkflowRouter__CallFailed.selector, targetError));
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), abi.encodePacked(FAIL_SELECTOR));
    }

    function test_WorkflowRouter_onReport_Success() external {
        vm.recordLogs();
        s_workflowRouter.onReport(_buildMetadata(WORKFLOW_ID, s_workflowName, i_owner), abi.encodePacked(SELECTOR));
        _assertEmittedBy(keccak256("TargetDepositSuccess()"), address(s_target));
    }
}
