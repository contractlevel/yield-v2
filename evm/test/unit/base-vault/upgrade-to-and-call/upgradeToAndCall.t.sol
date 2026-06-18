// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BaseVault_UpgradeToAndCallUnitTest is BaseUnitTest {
    function _deployImplementation() internal virtual returns (address);

    function _getProxy() internal virtual returns (BaseVault);

    function test_BaseVault_upgradeToAndCall_Success() external {
        address newImpl = _deployImplementation();

        _changePrank(i_upgrader);
        _getProxy().upgradeToAndCall(newImpl, "");
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
}

contract ParentVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    function _deployImplementation() internal override returns (address) {
        return address(new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin)));
    }

    function _getProxy() internal override returns (BaseVault) {
        return s_parentVault;
    }
}

contract ChildVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    function _deployImplementation() internal override returns (address) {
        return address(new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR));
    }

    function _getProxy() internal override returns (BaseVault) {
        return s_childVault;
    }
}
