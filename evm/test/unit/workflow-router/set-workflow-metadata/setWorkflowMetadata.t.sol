// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseWorkflowRouterUnitTest, Vm} from "../BaseWorkflowRouterUnitTest.t.sol";

import {WorkflowRouter} from "../../../../src/modules/WorkflowRouter.sol";
import {IWorkflowRouter} from "../../../../src/interfaces/IWorkflowRouter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract WorkflowRouter_SetWorkflowMetadataUnitTest is BaseWorkflowRouterUnitTest {
    bytes32 internal constant WORKFLOW_ID = keccak256("workflow-1");

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_WorkflowRouter_setWorkflowMetadata_RevertWhen_CallerDoesNotHaveConfigOperatorRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, s_workflowName, i_owner);
    }

    function test_WorkflowRouter_setWorkflowMetadata_RevertWhen_WorkflowIdIsZero() external {
        vm.expectRevert(IWorkflowRouter.WorkflowRouter__NoZeroWorkflowId.selector);
        s_workflowRouter.setWorkflowMetadata(bytes32(0), s_workflowName, i_owner);
    }

    function test_WorkflowRouter_setWorkflowMetadata_RevertWhen_WorkflowNameIsZeroAndOwnerIsNonzero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataZero.selector, WORKFLOW_ID, bytes10(0), i_owner
            )
        );
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, bytes10(0), i_owner);
    }

    function test_WorkflowRouter_setWorkflowMetadata_RevertWhen_WorkflowOwnerIsZeroAndNameIsNonzero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IWorkflowRouter.WorkflowRouter__MetadataZero.selector, WORKFLOW_ID, s_workflowName, address(0)
            )
        );
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, s_workflowName, address(0));
    }

    function test_WorkflowRouter_setWorkflowMetadata_Success_SetsWorkflowMetadata() external {
        vm.recordLogs();
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, s_workflowName, i_owner);

        WorkflowRouter.WorkflowMetadata memory metadata = s_workflowRouter.getWorkflowMetadata(WORKFLOW_ID);
        assertEq(metadata.owner, i_owner);
        assertEq(metadata.name, s_workflowName);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WorkflowMetadataSet(bytes32,bytes10,address)"), address(s_workflowRouter));
        assertEq(log.topics[1], WORKFLOW_ID);
        assertEq(log.topics[2], bytes32(s_workflowName));
        assertEq(log.topics[3], bytes32(uint256(uint160(i_owner))));
    }

    function test_WorkflowRouter_setWorkflowMetadata_Success_WhenMetadataIsZero_RemovesWorkflowMetadata() external {
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, s_workflowName, i_owner);

        vm.recordLogs();
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, bytes10(0), address(0));

        WorkflowRouter.WorkflowMetadata memory metadata = s_workflowRouter.getWorkflowMetadata(WORKFLOW_ID);
        assertEq(metadata.owner, address(0));
        assertEq(metadata.name, bytes10(0));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WorkflowMetadataSet(bytes32,bytes10,address)"), address(s_workflowRouter));
        assertEq(log.topics[1], WORKFLOW_ID);
        assertEq(log.topics[2], bytes32(0));
        assertEq(log.topics[3], bytes32(0));
    }
}
