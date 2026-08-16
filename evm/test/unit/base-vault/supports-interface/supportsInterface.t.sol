// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {IAny2EVMMessageReceiverV2} from "@chainlink/contracts-ccip/contracts/interfaces/IAny2EVMMessageReceiverV2.sol";

abstract contract BaseVault_SupportsInterfaceUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_supportsInterface() public view {
        assertTrue(s_vault.supportsInterface(type(IERC165).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IAccessControl).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IAccessControlDefaultAdminRules).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IAny2EVMMessageReceiver).interfaceId));
        assertTrue(s_vault.supportsInterface(type(IAny2EVMMessageReceiverV2).interfaceId));
    }

    function test_BaseVault_supportsInterface_ReturnsFalse_WhenInterfaceIsNotSupported() public view {
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
