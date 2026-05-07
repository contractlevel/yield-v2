// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_UnpauseUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_unpause_RevertWhen_CallerDoesNotHaveUNPAUSER_ROLE() external whenCallerIsNotAdmin {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UNPAUSER_ROLE
            )
        );
        s_vault.unpause();
    }

    function test_BaseVault_unpause_Success() external {
        _changePrank(i_pauser);
        s_vault.pause();

        _changePrank(i_unpauser);
        vm.recordLogs();
        s_vault.unpause();

        assertEq(s_vault.paused(), false);
        assertEq(s_vault.getPausedAt(), 0);

        Vm.Log memory log = _assertEmittedBy(keccak256("Unpaused(address)"), address(s_vault));
        assertEq(abi.decode(log.data, (address)), i_unpauser);
    }
}

contract ParentVault_UnpauseUnitTest is BaseVault_UnpauseUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_unpauser);
    }
}

contract ChildVault_UnpauseUnitTest is BaseVault_UnpauseUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_unpauser);
    }
}
