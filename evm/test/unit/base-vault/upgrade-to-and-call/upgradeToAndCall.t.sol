// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BaseVault_UpgradeToAndCallUnitTest is BaseUnitTest {
    function _deployImplementation() internal virtual returns (address);

    function _getProxy() internal virtual returns (BaseVault);

    function _callInitializeOnProxy(BaseVault proxy) internal virtual;

    function test_BaseVault_upgradeToAndCall_Success() external {
        address newImpl = _deployImplementation();

        _changePrank(i_upgrader);
        _getProxy().upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_Success_PreservesState() external {
        BaseVault proxy = _getProxy();
        address emergencyReceiverBefore = proxy.getEmergencyReceiver();
        uint256 defaultCcipGasLimitBefore = proxy.getDefaultCcipGasLimit();
        bool hasPauserRole = proxy.hasRole(Roles.PAUSER_ROLE, i_pauser);
        bool hasUpgraderRole = proxy.hasRole(Roles.UPGRADER_ROLE, i_upgrader);
        bool hasDefaultAdminRole = proxy.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner);

        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        proxy.upgradeToAndCall(newImpl, "");

        assertEq(proxy.getEmergencyReceiver(), emergencyReceiverBefore);
        assertEq(proxy.getDefaultCcipGasLimit(), defaultCcipGasLimitBefore);
        assertEq(proxy.hasRole(Roles.PAUSER_ROLE, i_pauser), hasPauserRole);
        assertEq(proxy.hasRole(Roles.UPGRADER_ROLE, i_upgrader), hasUpgraderRole);
        assertEq(proxy.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner), hasDefaultAdminRole);
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_CallerDoesNotHaveUPGRADER_ROLE() external {
        address newImpl = _deployImplementation();

        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UPGRADER_ROLE
            )
        );
        _getProxy().upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_CalledOnImplementation() external {
        address implementation = _deployImplementation();
        address newImpl = _deployImplementation();

        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        BaseVault(payable(implementation)).upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_ReinitializeAfterUpgrade() external {
        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        _getProxy().upgradeToAndCall(newImpl, "");

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _callInitializeOnProxy(_getProxy());
    }
}

contract ParentVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    function _deployImplementation() internal override returns (address) {
        return address(new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin)));
    }

    function _getProxy() internal view override returns (BaseVault) {
        return s_parentVault;
    }

    function _callInitializeOnProxy(BaseVault proxy) internal override {
        ParentVault(address(proxy)).initialize(
            _baseVaultInitParams(), i_treasury, i_policyEngineManager, address(s_mockPolicyEngine)
        );
    }
}

contract ChildVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    function _deployImplementation() internal override returns (address) {
        return address(new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR));
    }

    function _getProxy() internal view override returns (BaseVault) {
        return s_childVault;
    }

    function _callInitializeOnProxy(BaseVault proxy) internal override {
        ChildVault(address(proxy)).initialize(_baseVaultInitParams());
    }
}
