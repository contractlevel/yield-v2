// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest, Vm} from "../BaseWorkflowRouterUnitTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract WorkflowRouter_PauseUnitTest is BaseWorkflowRouterUnitTest {
    function setUp() public {
        _changePrank(i_pauser);
    }

    function test_WorkflowRouter_pause_RevertWhen_CallerDoesNotHavePauserRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.PAUSER_ROLE
            )
        );
        s_workflowRouter.pause();
    }

    function test_WorkflowRouter_pause_Success() external {
        vm.recordLogs();
        s_workflowRouter.pause();

        assertEq(s_workflowRouter.paused(), true);

        Vm.Log memory log = _assertEmittedBy(keccak256("Paused(address)"), address(s_workflowRouter));
        assertEq(abi.decode(log.data, (address)), i_pauser);
    }
}
