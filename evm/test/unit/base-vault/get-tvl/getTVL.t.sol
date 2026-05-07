// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";

abstract contract BaseVault_GetTVLUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    uint256 internal constant TVL = 1_000 * 1e6;

    function test_BaseVault_getTVL_RevertWhen_NoActiveAdapter() external {
        _clearActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_vault.getTVL();
    }

    function test_BaseVault_getTVL_Success() external {
        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);

        assertEq(s_vault.getTVL(), TVL);
    }

    function _setActiveAdapter() internal virtual;
    function _clearActiveAdapter() internal virtual;
}

contract ParentVault_GetTVLUnitTest is BaseVault_GetTVLUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }

    function _setActiveAdapter() internal override {}

    function _clearActiveAdapter() internal override {
        _clearParentActiveAdapter();
    }
}

contract ChildVault_GetTVLUnitTest is BaseVault_GetTVLUnitTest {
    function setUp() public {
        s_vault = s_childVault;
    }

    function _setActiveAdapter() internal override {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
    }

    function _clearActiveAdapter() internal override {}
}
