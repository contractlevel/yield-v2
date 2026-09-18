// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAllowlistUnitTest, Vm} from "../BaseAllowlistUnitTest.t.sol";

import {IAllowlist} from "../../../../src/interfaces/modules/IAllowlist.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract Allowlist_SetAllowlistedUsersUnitTest is BaseAllowlistUnitTest {
    address[] internal s_users;

    function setUp() public {
        _changePrank(i_allowlistOperator);
        s_users.push(i_depositor);
        s_users.push(i_recipient1);
    }

    function test_Allowlist_setAllowlistedUsers_RevertWhen_CallerDoesNotHaveALLOWLIST_OPERATOR_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistedUsers(s_users, true);
    }

    function test_Allowlist_setAllowlistedUsers_RevertWhen_AdminDoesNotHaveOperatorRole() external {
        _changePrank(i_owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_owner, Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistedUsers(s_users, true);
    }

    function test_Allowlist_setAllowlistedUsers_RevertWhen_OperatorRoleRevoked() external {
        _changePrank(i_owner);
        s_allowlist.revokeRole(Roles.ALLOWLIST_OPERATOR_ROLE, i_allowlistOperator);
        _changePrank(i_allowlistOperator);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                i_allowlistOperator,
                Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistedUsers(s_users, true);
    }

    function test_Allowlist_setAllowlistedUsers_RevertWhen_EmptyBatchAndUnauthorized() external {
        _changePrank(i_nonOwner);
        address[] memory users = new address[](0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistedUsers(users, true);
    }

    function test_Allowlist_setAllowlistedUsers_Success_AddsUsers() external {
        s_allowlist.setAllowlistedUsers(s_users, true);

        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
        assertTrue(s_allowlist.getAllowlistedUser(i_recipient1));
    }

    function test_Allowlist_setAllowlistedUsers_Success_RemovesUsers() external {
        s_allowlist.setAllowlistedUsers(s_users, true);

        s_allowlist.setAllowlistedUsers(s_users, false);

        assertFalse(s_allowlist.getAllowlistedUser(i_depositor));
        assertFalse(s_allowlist.getAllowlistedUser(i_recipient1));
    }

    function test_Allowlist_setAllowlistedUsers_Success_PreservesOtherUsers() external {
        _setAllowlistedUser(i_recipient2, true);

        s_allowlist.setAllowlistedUsers(s_users, true);
        s_allowlist.setAllowlistedUsers(s_users, false);

        assertTrue(s_allowlist.getAllowlistedUser(i_recipient2));
        assertFalse(s_allowlist.getAllowlistedUser(i_nonOwner));
    }

    function test_Allowlist_setAllowlistedUsers_Success_DoesNotEnableAllowlist() external {
        s_allowlist.setAllowlistedUsers(s_users, true);

        assertFalse(s_allowlist.getAllowlistEnabled());
    }

    function test_Allowlist_setAllowlistedUsers_Success_UpdatesWhileEnabled() external {
        s_allowlist.setAllowlistEnabled(true);

        s_allowlist.setAllowlistedUsers(s_users, true);

        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
        assertTrue(s_allowlist.getAllowlistedUser(i_recipient1));
        assertTrue(s_allowlist.getAllowlistEnabled());
    }

    function test_Allowlist_setAllowlistedUsers_Success_AcceptsEmptyBatch() external {
        address[] memory users = new address[](0);
        vm.recordLogs();

        s_allowlist.setAllowlistedUsers(users, true);

        assertEq(vm.getRecordedLogs().length, 0);
        assertFalse(s_allowlist.getAllowlistedUser(i_depositor));
    }

    function test_Allowlist_setAllowlistedUsers_Success_AcceptsZeroAddress() external {
        _setAllowlistedUser(address(0), true);

        assertTrue(s_allowlist.getAllowlistedUser(address(0)));
    }

    function test_Allowlist_setAllowlistedUsers_Success_EmitsForEachUserInOrder() external {
        vm.recordLogs();

        s_allowlist.setAllowlistedUsers(s_users, true);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(logs[0].emitter, address(s_allowlist));
        assertEq(logs[1].emitter, address(s_allowlist));
        assertEq(logs[0].topics[0], keccak256("AllowlistedUserSet(address,bool)"));
        assertEq(logs[1].topics[0], keccak256("AllowlistedUserSet(address,bool)"));
        assertEq(address(uint160(uint256(logs[0].topics[1]))), i_depositor);
        assertEq(address(uint160(uint256(logs[1].topics[1]))), i_recipient1);
        assertEq(uint256(logs[0].topics[2]), 1);
        assertEq(uint256(logs[1].topics[2]), 1);
    }

    function test_Allowlist_setAllowlistedUsers_Success_EmitsWhenRemovingUser() external {
        _setAllowlistedUser(i_depositor, true);
        vm.recordLogs();

        _setAllowlistedUser(i_depositor, false);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistedUserSet(address,bool)"), address(s_allowlist));
        assertEq(address(uint160(uint256(log.topics[1]))), i_depositor);
        assertEq(uint256(log.topics[2]), 0);
    }

    function test_Allowlist_setAllowlistedUsers_Success_EmitsForDuplicateUser() external {
        address[] memory users = new address[](2);
        users[0] = i_depositor;
        users[1] = i_depositor;
        vm.recordLogs();

        s_allowlist.setAllowlistedUsers(users, true);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        assertEq(address(uint160(uint256(logs[0].topics[1]))), i_depositor);
        assertEq(address(uint160(uint256(logs[1].topics[1]))), i_depositor);
        assertEq(uint256(logs[0].topics[2]), 1);
        assertEq(uint256(logs[1].topics[2]), 1);
        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
    }

    function test_Allowlist_setAllowlistedUsers_Success_EmitsWhenAlreadyAllowed() external {
        _setAllowlistedUser(i_depositor, true);
        vm.recordLogs();

        _setAllowlistedUser(i_depositor, true);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistedUserSet(address,bool)"), address(s_allowlist));
        assertEq(address(uint160(uint256(log.topics[1]))), i_depositor);
        assertEq(uint256(log.topics[2]), 1);
    }

    function test_Allowlist_setAllowlistedUsers_Success_EmitsWhenAlreadyDisallowed() external {
        vm.recordLogs();

        _setAllowlistedUser(i_depositor, false);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistedUserSet(address,bool)"), address(s_allowlist));
        assertEq(address(uint160(uint256(log.topics[1]))), i_depositor);
        assertEq(uint256(log.topics[2]), 0);
    }

    function testFuzz_Allowlist_setAllowlistedUsers_Success_SetsMembership(address user, bool allowed) external {
        _setAllowlistedUser(user, allowed);

        assertEq(s_allowlist.getAllowlistedUser(user), allowed);
    }
}
