// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_PauseUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_pause_RevertWhen_CallerDoesNotHavePAUSER_ROLE() external whenCallerIsNotAdmin {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.PAUSER_ROLE
            )
        );
        s_vault.pause();
    }

    function test_BaseVault_pause_Success() external {
        vm.recordLogs();
        s_vault.pause();

        assertEq(s_vault.paused(), true);
        assertEq(s_vault.getPausedAt(), block.timestamp);

        Vm.Log memory log = _assertEmittedBy(keccak256("Paused(address)"), address(s_vault));
        assertEq(abi.decode(log.data, (address)), i_pauser);
    }
}

contract ParentVault_PauseUnitTest is BaseVault_PauseUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_pauser);
    }
}

contract ChildVault_PauseUnitTest is BaseVault_PauseUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_pauser);
    }
}
