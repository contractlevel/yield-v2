// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract YieldcoinShare_PauseUnitTest is BaseUnitTest {
    function test_YieldcoinShare_pause_RevertWhen_TokenIsPaused() external givenContractIsPaused(address(s_yieldcoin)) {
        _changePrank(i_pauser);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        s_yieldcoin.pause();
    }

    function test_YieldcoinShare_pause_RevertWhen_CallerDoesNotHavePAUSER_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.PAUSER_ROLE
            )
        );
        s_yieldcoin.pause();
    }

    function test_YieldcoinShare_pause_Success() external {
        _changePrank(i_pauser);
        vm.recordLogs();
        s_yieldcoin.pause();

        assertTrue(s_yieldcoin.paused());
        Vm.Log memory log = _assertEmittedBy(keccak256("Paused(address)"), address(s_yieldcoin));
        assertEq(abi.decode(log.data, (address)), i_pauser);
    }
}
