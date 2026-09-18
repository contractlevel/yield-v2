// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAllowlistUnitTest, Vm} from "../BaseAllowlistUnitTest.t.sol";

import {IAllowlist} from "../../../../src/interfaces/modules/IAllowlist.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract Allowlist_SetAllowlistEnabledUnitTest is BaseAllowlistUnitTest {
    function setUp() public {
        _changePrank(i_allowlistOperator);
    }

    function test_Allowlist_setAllowlistEnabled_RevertWhen_CallerDoesNotHaveALLOWLIST_OPERATOR_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistEnabled(true);
    }

    function test_Allowlist_setAllowlistEnabled_RevertWhen_AdminDoesNotHaveOperatorRole() external {
        _changePrank(i_owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_owner, Roles.ALLOWLIST_OPERATOR_ROLE
            )
        );
        s_allowlist.setAllowlistEnabled(true);
    }

    function test_Allowlist_setAllowlistEnabled_RevertWhen_OperatorRoleRevoked() external {
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
        s_allowlist.setAllowlistEnabled(true);
    }

    function test_Allowlist_setAllowlistEnabled_Success_EnablesAllowlist() external {
        s_allowlist.setAllowlistEnabled(true);

        assertTrue(s_allowlist.getAllowlistEnabled());
    }

    function test_Allowlist_setAllowlistEnabled_Success_DisablesAllowlist() external {
        s_allowlist.setAllowlistEnabled(true);

        s_allowlist.setAllowlistEnabled(false);

        assertFalse(s_allowlist.getAllowlistEnabled());
    }

    function test_Allowlist_setAllowlistEnabled_Success_PreservesMembership() external {
        _setAllowlistedUser(i_depositor, true);
        s_allowlist.setAllowlistEnabled(true);

        s_allowlist.setAllowlistEnabled(false);

        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
        assertFalse(s_allowlist.getAllowlistedUser(i_recipient1));

        s_allowlist.setAllowlistEnabled(true);

        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
        assertFalse(s_allowlist.getAllowlistedUser(i_recipient1));
    }

    function test_Allowlist_setAllowlistEnabled_Success_EmitsAllowlistEnabledSet() external {
        vm.recordLogs();

        s_allowlist.setAllowlistEnabled(true);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistEnabledSet(bool)"), address(s_allowlist));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_Allowlist_setAllowlistEnabled_Success_EmitsWhenAlreadyEnabled() external {
        s_allowlist.setAllowlistEnabled(true);
        vm.recordLogs();

        s_allowlist.setAllowlistEnabled(true);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistEnabledSet(bool)"), address(s_allowlist));
        assertEq(uint256(log.topics[1]), 1);
    }

    function test_Allowlist_setAllowlistEnabled_Success_EmitsWhenAlreadyDisabled() external {
        vm.recordLogs();

        s_allowlist.setAllowlistEnabled(false);

        Vm.Log memory log = _assertEmittedBy(keccak256("AllowlistEnabledSet(bool)"), address(s_allowlist));
        assertEq(uint256(log.topics[1]), 0);
    }
}
