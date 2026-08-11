// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract YieldcoinShare_UnpauseUnitTest is BaseUnitTest {
    function test_YieldcoinShare_unpause_RevertWhen_TokenIsUnpaused() external {
        _changePrank(i_unpauser);
        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        s_yieldcoin.unpause();
    }

    function test_YieldcoinShare_unpause_RevertWhen_CallerDoesNotHaveUNPAUSER_ROLE() external {
        _changePrank(i_pauser);
        s_yieldcoin.pause();

        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UNPAUSER_ROLE
            )
        );
        s_yieldcoin.unpause();
    }

    function test_YieldcoinShare_unpause_Success() external {
        _changePrank(i_pauser);
        s_yieldcoin.pause();

        _changePrank(i_unpauser);
        vm.recordLogs();
        s_yieldcoin.unpause();

        assertFalse(s_yieldcoin.paused());
        Vm.Log memory log = _assertEmittedBy(keccak256("Unpaused(address)"), address(s_yieldcoin));
        assertEq(abi.decode(log.data, (address)), i_unpauser);
    }
}
