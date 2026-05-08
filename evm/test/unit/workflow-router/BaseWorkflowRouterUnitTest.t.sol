// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../BaseUnitTest.t.sol";

import {WorkflowRouter} from "../../../src/modules/WorkflowRouter.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

abstract contract BaseWorkflowRouterUnitTest is BaseUnitTest {
    address internal immutable i_keystoneForwarder = makeAddr("keystoneForwarder");

    WorkflowRouter internal s_workflowRouter;
    bytes10 internal s_workflowName;

    Target internal s_target;

    constructor() {
        s_workflowName = _createWorkflowName("workflow-1");
        s_target = new Target();
        s_workflowRouter = new WorkflowRouter(0, i_owner, address(s_target));

        _changePrank(i_owner);
        s_workflowRouter.grantRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator);
        s_workflowRouter.grantRole(Roles.PAUSER_ROLE, i_pauser);
        s_workflowRouter.grantRole(Roles.UNPAUSER_ROLE, i_unpauser);
        s_workflowRouter.grantRole(Roles.KEYSTONE_FORWARDER_ROLE, i_keystoneForwarder);

        vm.label(address(s_target), "Target");
        vm.label(address(s_workflowRouter), "WorkflowRouter");
        vm.label(i_keystoneForwarder, "KeystoneForwarder");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}
}

contract Target {
    event TargetDepositSuccess();

    error Target__Fail();

    function deposit() external {
        emit TargetDepositSuccess();
    }

    function fail() external {
        revert Target__Fail();
    }
}
