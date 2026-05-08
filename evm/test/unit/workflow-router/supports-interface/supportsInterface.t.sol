// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest} from "../BaseWorkflowRouterUnitTest.t.sol";

import {IReceiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract WorkflowRouter_SupportsInterfaceUnitTest is BaseWorkflowRouterUnitTest {
    function test_WorkflowRouter_supportsInterface_IReceiver() public view {
        assertEq(s_workflowRouter.supportsInterface(type(IReceiver).interfaceId), true);
    }

    function test_WorkflowRouter_supportsInterface_IAccessControl() public view {
        assertEq(s_workflowRouter.supportsInterface(type(IAccessControl).interfaceId), true);
    }

    function test_WorkflowRouter_supportsInterface_ReturnsFalseForUnknownInterface() public view {
        assertEq(s_workflowRouter.supportsInterface(bytes4(0xdeadbeef)), false);
    }
}
