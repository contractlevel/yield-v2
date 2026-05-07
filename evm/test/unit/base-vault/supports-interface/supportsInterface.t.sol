// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
import {IPolicyProtected} from "@chainlink/policy-management/core/PolicyProtected.sol";

abstract contract BaseVault_SupportsInterfaceUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_supportsInterface() public {
        assertTrue(s_vault.supportsInterface(type(IAccessControlDefaultAdminRules).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IAny2EVMMessageReceiver).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IPolicyProtected).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IERC165).interfaceId));
    }

    function test_BaseVault_supportsInterface_ReturnsFalse_WhenInterfaceIsNotSupported() public {
        assertFalse(s_vault.supportsInterface(bytes4(0xdeadbeef)));
    }
}

contract ParentVault_SupportsInterfaceUnitTest is BaseVault_SupportsInterfaceUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }
}

contract ChildVault_SupportsInterfaceUnitTest is BaseVault_SupportsInterfaceUnitTest {
    function setUp() public {
        s_vault = s_childVault;
    }
}

