// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";

abstract contract BaseVault_OwnerUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_owner_Success() external view {
        assertEq(s_vault.owner(), address(i_owner));
    }
}

contract ParentVault_OwnerUnitTest is BaseVault_OwnerUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }
}

contract ChildVault_OwnerUnitTest is BaseVault_OwnerUnitTest {
    function setUp() public {
        s_vault = s_childVault;
    }
}
