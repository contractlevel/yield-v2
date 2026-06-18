// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";

abstract contract BaseVault_ConstructorUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function _expectedChainSelector() internal virtual returns (uint64);

    function test_BaseVault_constructor() public {
        assertEq(s_vault.getThisChainSelector(), _expectedChainSelector());
        assertEq(address(s_vault.getLink()), address(s_mockLink));
        assertEq(address(s_vault.getAsset()), address(s_mockUsdc));
        assertEq(s_vault.getAssetPrecision(), 10 ** uint256(s_mockUsdc.decimals()));
        assertEq(address(s_vault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(s_vault.getAdapterRegistry()), address(s_adapterRegistry));
    }
}

contract ParentVault_ConstructorUnitTest is BaseVault_ConstructorUnitTest {
    function setUp() public {
        s_vault = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));
    }

    function _expectedChainSelector() internal pure override returns (uint64) {
        return PARENT_CHAIN_SELECTOR;
    }
}

contract ChildVault_ConstructorUnitTest is BaseVault_ConstructorUnitTest {
    function setUp() public {
        s_vault = new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR);
    }

    function _expectedChainSelector() internal pure override returns (uint64) {
        return CHILD_CHAIN_SELECTOR;
    }
}

contract BaseVault_ConstructorValidationUnitTest is BaseUnitTest {
    function test_BaseVault_constructor_RevertWhen_LinkIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.link = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_AssetIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.asset = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_CcipRouterIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.ccipRouter = address(0);

        vm.expectRevert(abi.encodeWithSelector(CCIPReceiver.InvalidRouter.selector, address(0)));
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_AdapterRegistryIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.adapterRegistry = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_ThisChainSelectorIsZero() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.thisChainSelector = 0;

        vm.expectRevert(IBaseVault.BaseVault__NoZeroChainSelector.selector);
        _deployParentVault(params);
    }

    function _deployParentVault(BaseVault.ConstructorParams memory params) internal {
        new ParentVault(params, address(s_yieldcoin));
    }
}
