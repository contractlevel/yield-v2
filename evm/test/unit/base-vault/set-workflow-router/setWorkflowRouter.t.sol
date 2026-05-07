// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_SetWorkflowRouterUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    address internal immutable i_newWorkflowRouter = makeAddr("newWorkflowRouter");

    function test_BaseVault_setWorkflowRouter_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_vault.setWorkflowRouter(address(0));
    }

    function test_BaseVault_setWorkflowRouter_Success() external {
        vm.recordLogs();
        s_vault.setWorkflowRouter(i_newWorkflowRouter);

        Vm.Log memory log = _assertEmittedBy(keccak256("WorkflowRouterSet(address)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_newWorkflowRouter);
        assertEq(s_vault.getWorkflowRouter(), i_newWorkflowRouter);
    }
}

contract ParentVault_SetWorkflowRouterUnitTest is BaseVault_SetWorkflowRouterUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_configOperator);
    }
}

contract ChildVault_SetWorkflowRouterUnitTest is BaseVault_SetWorkflowRouterUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_configOperator);
    }
}
