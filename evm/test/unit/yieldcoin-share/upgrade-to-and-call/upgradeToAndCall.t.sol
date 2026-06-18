// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract YieldcoinShare_UpgradeToAndCallUnitTest is BaseUnitTest {
    function test_YieldcoinShare_upgradeToAndCall_Success() external {
        YieldcoinShare newImpl = new YieldcoinShare();

        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_CallerIsNotOwner() external {
        YieldcoinShare newImpl = new YieldcoinShare();

        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, i_nonOwner));
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_CalledOnImplementation() external {
        YieldcoinShare yieldcoinImpl = new YieldcoinShare();
        YieldcoinShare newImpl = new YieldcoinShare();

        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        yieldcoinImpl.upgradeToAndCall(address(newImpl), "");
    }
}
