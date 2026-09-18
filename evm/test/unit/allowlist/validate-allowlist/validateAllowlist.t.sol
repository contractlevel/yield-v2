// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAllowlistUnitTest} from "../BaseAllowlistUnitTest.t.sol";

import {IAllowlist} from "../../../../src/interfaces/modules/IAllowlist.sol";

contract Allowlist_ValidateAllowlistUnitTest is BaseAllowlistUnitTest {
    function setUp() public {
        _changePrank(i_allowlistOperator);
        s_allowlist.setAllowlistEnabled(true);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_UserNotAllowlisted() external {
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_depositor));
        s_allowlist.validate(i_depositor);
    }

    function test_Allowlist_validateAllowlist_Success_UserAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);

        s_allowlist.validate(i_depositor);
    }

    function test_Allowlist_validateAllowlist_Success_SingleUserAllowlistDisabled() external {
        s_allowlist.setAllowlistEnabled(false);

        s_allowlist.validate(i_depositor);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_CallerNotAllowlisted() external {
        _setAllowlistedUser(i_recipient1, true);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_depositor));
        s_allowlist.validate(i_depositor, i_recipient1);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_BeneficiaryNotAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_recipient1));
        s_allowlist.validate(i_depositor, i_recipient1);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_BothNotAllowlistedReportsCaller() external {
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_depositor));
        s_allowlist.validate(i_depositor, i_recipient1);
    }

    function test_Allowlist_validateAllowlist_Success_CallerAndBeneficiaryAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);
        _setAllowlistedUser(i_recipient1, true);

        s_allowlist.validate(i_depositor, i_recipient1);
    }

    function test_Allowlist_validateAllowlist_Success_CallerAndBeneficiaryAllowlistDisabled() external {
        s_allowlist.setAllowlistEnabled(false);

        s_allowlist.validate(i_depositor, i_recipient1);
    }

    function test_Allowlist_validateAllowlist_Success_IdenticalAddressesAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);

        s_allowlist.validate(i_depositor, i_depositor);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_IdenticalAddressesNotAllowlisted() external {
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_depositor));
        s_allowlist.validate(i_depositor, i_depositor);
    }

    function test_Allowlist_validateAllowlist_Success_IdenticalAddressesAllowlistDisabled() external {
        s_allowlist.setAllowlistEnabled(false);

        s_allowlist.validate(i_depositor, i_depositor);
    }

    function test_Allowlist_validateAllowlist_RevertWhen_ZeroUserNotAllowlisted() external {
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, address(0)));
        s_allowlist.validate(address(0));
    }

    function test_Allowlist_validateAllowlist_Success_ZeroUserAllowlisted() external {
        _setAllowlistedUser(address(0), true);

        s_allowlist.validate(address(0));
    }

    function test_Allowlist_validateAllowlist_RevertWhen_ZeroBeneficiaryNotAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, address(0)));
        s_allowlist.validate(i_depositor, address(0));
    }

    function test_Allowlist_validateAllowlist_Success_ZeroBeneficiaryAllowlisted() external {
        _setAllowlistedUser(i_depositor, true);
        _setAllowlistedUser(address(0), true);

        s_allowlist.validate(i_depositor, address(0));
    }

    function test_Allowlist_validateAllowlist_Success_DoesNotChangeState() external {
        _setAllowlistedUser(i_depositor, true);
        _setAllowlistedUser(i_recipient1, true);

        s_allowlist.validate(i_depositor);
        s_allowlist.validate(i_depositor, i_recipient1);

        assertTrue(s_allowlist.getAllowlistEnabled());
        assertTrue(s_allowlist.getAllowlistedUser(i_depositor));
        assertTrue(s_allowlist.getAllowlistedUser(i_recipient1));
        assertFalse(s_allowlist.getAllowlistedUser(i_nonOwner));
    }

    function testFuzz_Allowlist_validateAllowlist_Success_AllowedUser(address user) external {
        _setAllowlistedUser(user, true);

        s_allowlist.validate(user);
    }
}
