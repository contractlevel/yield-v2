// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

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
        WorkflowRouter.ConstructorParams memory params = WorkflowRouter.ConstructorParams({
            initialDelay: 0,
            defaultAdmin: i_owner,
            pauser: i_pauser,
            unpauser: i_unpauser,
            configOperator: i_configOperator,
            keystoneForwarder: i_keystoneForwarder,
            vault: address(s_target)
        });
        s_workflowRouter = new WorkflowRouter(params);

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

    function fail() external pure {
        revert Target__Fail();
    }
}
