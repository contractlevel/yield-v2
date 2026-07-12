// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";

contract ParentVault_ConstructorUnitTest is BaseUnitTest {
    function test_ParentVault_constructor() public {
        ParentVault parentVault = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));

        assertEq(parentVault.getThisChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(address(parentVault.getLink()), address(s_mockLink));
        assertEq(address(parentVault.getAsset()), address(s_mockUsdc));
        assertEq(parentVault.getAssetPrecision(), 10 ** uint256(s_mockUsdc.decimals()));
        assertEq(parentVault.getSharePrecision(), 1e18 / parentVault.getAssetPrecision());
        assertEq(parentVault.getMinDepositAmount(), 1 * parentVault.getAssetPrecision());
        assertEq(address(parentVault.getShare()), address(s_yieldcoin));
        assertEq(address(parentVault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(parentVault.getAdapterRegistry()), address(s_adapterRegistry));
    }

    function test_ParentVault_constructor_RevertWhen_ShareIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(0));
    }
}
