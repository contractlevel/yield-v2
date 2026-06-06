// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

abstract contract BaseVault_ConstructorUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function _expectedChainSelector() internal virtual returns (uint64);

    function test_BaseVault_constructor() public {
        assertEq(s_vault.getThisChainSelector(), _expectedChainSelector());
        assertEq(address(s_vault.getLink()), address(s_mockLink));
        assertEq(address(s_vault.getUsdc()), address(s_mockUsdc));
        assertEq(address(s_vault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(s_vault.getAdapterRegistry()), address(s_adapterRegistry));
        assertEq(s_vault.getEmergencyReceiver(), i_emergencyReceiver);
        assertEq(s_vault.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner), true);
        assertEq(s_vault.hasRole(Roles.PAUSER_ROLE, i_pauser), true);
        assertEq(s_vault.hasRole(Roles.UNPAUSER_ROLE, i_unpauser), true);
        assertEq(s_vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator), true);
        assertEq(s_vault.getDefaultCcipGasLimit(), DEFAULT_CCIP_GAS_LIMIT);
    }
}

contract ParentVault_ConstructorUnitTest is BaseVault_ConstructorUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }

    function _expectedChainSelector() internal pure override returns (uint64) {
        return PARENT_CHAIN_SELECTOR;
    }
}

contract ChildVault_ConstructorUnitTest is BaseVault_ConstructorUnitTest {
    function setUp() public {
        s_vault = s_childVault;
    }

    function _expectedChainSelector() internal pure override returns (uint64) {
        return CHILD_CHAIN_SELECTOR;
    }
}
