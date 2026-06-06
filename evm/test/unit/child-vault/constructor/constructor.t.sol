// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

contract ChildVault_ConstructorUnitTest is BaseUnitTest {
    function test_ChildVault_constructor() public view {
        assertEq(s_childVault.getThisChainSelector(), CHILD_CHAIN_SELECTOR);
        assertEq(s_childVault.getParentChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(address(s_childVault.getLink()), address(s_mockLink));
        assertEq(address(s_childVault.getUsdc()), address(s_mockUsdc));
        assertEq(address(s_childVault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(s_childVault.getAdapterRegistry()), address(s_adapterRegistry));
        assertEq(s_childVault.getEmergencyReceiver(), i_emergencyReceiver);
        assertEq(s_childVault.hasRole(Roles.DEFAULT_ADMIN_ROLE, address(i_owner)), true);
        assertEq(s_childVault.hasRole(Roles.PAUSER_ROLE, i_pauser), true);
        assertEq(s_childVault.hasRole(Roles.UNPAUSER_ROLE, i_unpauser), true);
        assertEq(s_childVault.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(i_configOperator)), true);
        assertEq(s_childVault.getDefaultCcipGasLimit(), DEFAULT_CCIP_GAS_LIMIT);
    }
}
