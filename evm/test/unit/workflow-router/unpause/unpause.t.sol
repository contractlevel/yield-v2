// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseWorkflowRouterUnitTest, Vm} from "../BaseWorkflowRouterUnitTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract WorkflowRouter_UnpauseUnitTest is BaseWorkflowRouterUnitTest {
    function setUp() public givenContractIsPaused(address(s_workflowRouter)) {
        _changePrank(i_unpauser);
    }

    function test_WorkflowRouter_unpause_RevertWhen_CallerDoesNotHaveUnpauserRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UNPAUSER_ROLE
            )
        );
        s_workflowRouter.unpause();
    }

    function test_WorkflowRouter_unpause_Success() external {
        vm.recordLogs();
        s_workflowRouter.unpause();

        assertEq(s_workflowRouter.paused(), false);

        Vm.Log memory log = _assertEmittedBy(keccak256("Unpaused(address)"), address(s_workflowRouter));
        assertEq(abi.decode(log.data, (address)), i_unpauser);
    }
}
