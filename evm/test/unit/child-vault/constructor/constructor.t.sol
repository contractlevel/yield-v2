// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IChildVault} from "../../../../src/interfaces/IChildVault.sol";

contract ChildVault_ConstructorUnitTest is BaseUnitTest {
    function test_ChildVault_constructor() public {
        ChildVault childVault = new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR);

        assertEq(childVault.getThisChainSelector(), CHILD_CHAIN_SELECTOR);
        assertEq(childVault.getParentChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(address(childVault.getLink()), address(s_mockLink));
        assertEq(address(childVault.getAsset()), address(s_mockUsdc));
        assertEq(childVault.getAssetPrecision(), 10 ** uint256(s_mockUsdc.decimals()));
        assertEq(address(childVault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(childVault.getAdapterRegistry()), address(s_adapterRegistry));
    }

    function test_ChildVault_constructor_RevertWhen_ParentChainSelectorIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroChainSelector.selector);
        new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), 0);
    }

    function test_ChildVault_constructor_RevertWhen_ParentChainSelectorEqualsThisChainSelector() public {
        vm.expectRevert(IChildVault.ChildVault__InvalidParentChainSelector.selector);
        new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), CHILD_CHAIN_SELECTOR);
    }
}
