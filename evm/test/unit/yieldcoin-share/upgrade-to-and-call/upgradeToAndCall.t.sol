// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract YieldcoinShareV2 is YieldcoinShare {
    function upgradeTestVersion() external pure returns (uint256) {
        return 2;
    }
}

contract YieldcoinShareInvalidProxiableUUID {
    function proxiableUUID() external pure returns (bytes32) {
        return bytes32(uint256(1));
    }
}

contract YieldcoinShare_UpgradeToAndCallUnitTest is BaseUnitTest {
    struct YieldcoinShareState {
        string name;
        string symbol;
        uint8 decimals;
        address ccipAdmin;
        uint256 supply;
        uint256 balance;
        uint256 allowance;
        address defaultAdmin;
        bool hasPauserRole;
        bool hasUnpauserRole;
        bool hasConfigOperatorRole;
        bool hasUpgraderRole;
        bool hasMinterRole;
        bool hasBurnerRole;
    }

    function test_YieldcoinShare_upgradeToAndCall_Success() external {
        YieldcoinShare newImpl = new YieldcoinShare();

        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_UPGRADE_007_upgradeToAndCall_Success_PreservesState() external {
        uint256 balance = 100e18;
        uint256 allowance = 40e18;

        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_owner, balance);
        _changePrank(i_owner);
        s_yieldcoin.approve(i_nonOwner, allowance);
        _changePrank(i_pauser);
        s_yieldcoin.pause();

        YieldcoinShareState memory stateBefore = YieldcoinShareState({
            name: s_yieldcoin.name(),
            symbol: s_yieldcoin.symbol(),
            decimals: s_yieldcoin.decimals(),
            ccipAdmin: s_yieldcoin.getCCIPAdmin(),
            supply: s_yieldcoin.totalSupply(),
            balance: s_yieldcoin.balanceOf(i_owner),
            allowance: s_yieldcoin.allowance(i_owner, i_nonOwner),
            defaultAdmin: s_yieldcoin.defaultAdmin(),
            hasPauserRole: s_yieldcoin.hasRole(Roles.PAUSER_ROLE, i_pauser),
            hasUnpauserRole: s_yieldcoin.hasRole(Roles.UNPAUSER_ROLE, i_unpauser),
            hasConfigOperatorRole: s_yieldcoin.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator),
            hasUpgraderRole: s_yieldcoin.hasRole(Roles.UPGRADER_ROLE, i_upgrader),
            hasMinterRole: s_yieldcoin.hasRole(Roles.MINTER_ROLE, address(s_parentVault)),
            hasBurnerRole: s_yieldcoin.hasRole(Roles.BURNER_ROLE, address(s_parentVault))
        });

        YieldcoinShare newImpl = new YieldcoinShareV2();
        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");

        assertEq(YieldcoinShareV2(address(s_yieldcoin)).upgradeTestVersion(), 2);
        assertEq(s_yieldcoin.name(), stateBefore.name);
        assertEq(s_yieldcoin.symbol(), stateBefore.symbol);
        assertEq(s_yieldcoin.decimals(), stateBefore.decimals);
        assertEq(s_yieldcoin.getCCIPAdmin(), stateBefore.ccipAdmin);
        assertEq(s_yieldcoin.totalSupply(), stateBefore.supply);
        assertEq(s_yieldcoin.balanceOf(i_owner), stateBefore.balance);
        assertEq(s_yieldcoin.allowance(i_owner, i_nonOwner), stateBefore.allowance);
        assertTrue(s_yieldcoin.paused());
        assertEq(s_yieldcoin.defaultAdmin(), stateBefore.defaultAdmin);
        assertEq(s_yieldcoin.hasRole(Roles.PAUSER_ROLE, i_pauser), stateBefore.hasPauserRole);
        assertEq(s_yieldcoin.hasRole(Roles.UNPAUSER_ROLE, i_unpauser), stateBefore.hasUnpauserRole);
        assertEq(s_yieldcoin.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator), stateBefore.hasConfigOperatorRole);
        assertEq(s_yieldcoin.hasRole(Roles.UPGRADER_ROLE, i_upgrader), stateBefore.hasUpgraderRole);
        assertEq(s_yieldcoin.hasRole(Roles.MINTER_ROLE, address(s_parentVault)), stateBefore.hasMinterRole);
        assertEq(s_yieldcoin.hasRole(Roles.BURNER_ROLE, address(s_parentVault)), stateBefore.hasBurnerRole);
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_CallerLacksUpgraderRole() external {
        YieldcoinShare newImpl = new YieldcoinShare();

        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UPGRADER_ROLE
            )
        );
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_CalledOnImplementation() external {
        YieldcoinShare yieldcoinImpl = new YieldcoinShare();
        YieldcoinShare newImpl = new YieldcoinShare();

        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        yieldcoinImpl.upgradeToAndCall(address(newImpl), "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_NewImplementationHasNoCode() external {
        address newImpl = makeAddr("new implementation");

        _changePrank(i_upgrader);
        vm.expectRevert();
        s_yieldcoin.upgradeToAndCall(newImpl, "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_ProxiableUUIDIsInvalid() external {
        address newImpl = address(new YieldcoinShareInvalidProxiableUUID());

        _changePrank(i_upgrader);
        vm.expectRevert(
            abi.encodeWithSelector(UUPSUpgradeable.UUPSUnsupportedProxiableUUID.selector, bytes32(uint256(1)))
        );
        s_yieldcoin.upgradeToAndCall(newImpl, "");
    }

    function test_YieldcoinShare_upgradeToAndCall_RevertWhen_ReinitializeAfterUpgrade() external {
        YieldcoinShare newImpl = new YieldcoinShare();
        _changePrank(i_upgrader);
        s_yieldcoin.upgradeToAndCall(address(newImpl), "");

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        s_yieldcoin.initialize(i_owner, i_pauser, i_unpauser, i_configOperator, i_configOperator, i_upgrader);
    }
}
