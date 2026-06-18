// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract YieldcoinShare_UpgradeToAndCallUnitTest is BaseUnitTest {
    function test_YieldcoinShare_upgradeToAndCall_Success() external {
        YieldcoinShare newImpl = new YieldcoinShare();

        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_upgradeToAndCall_Success_PreservesState() external {
        string memory nameBefore = s_yieldcoin.name();
        string memory symbolBefore = s_yieldcoin.symbol();
        uint8 decimalsBefore = s_yieldcoin.decimals();
        address ccipAdminBefore = s_yieldcoin.getCCIPAdmin();
        address policyEngineBefore = s_yieldcoin.getPolicyEngine();
        address ownerBefore = s_yieldcoin.owner();

        YieldcoinShare newImpl = new YieldcoinShare();
        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");

        assertEq(s_yieldcoin.name(), nameBefore);
        assertEq(s_yieldcoin.symbol(), symbolBefore);
        assertEq(s_yieldcoin.decimals(), decimalsBefore);
        assertEq(s_yieldcoin.getCCIPAdmin(), ccipAdminBefore);
        assertEq(s_yieldcoin.getPolicyEngine(), policyEngineBefore);
        assertEq(s_yieldcoin.owner(), ownerBefore);
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

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_ReinitializeAfterUpgrade() external {
        YieldcoinShare newImpl = new YieldcoinShare();
        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        s_yieldcoin.initialize(address(s_mockPolicyEngine), i_configOperator, i_upgrader);
    }
}
