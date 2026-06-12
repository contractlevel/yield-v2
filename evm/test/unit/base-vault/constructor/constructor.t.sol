// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

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

    function test_BaseVault_constructor_RevertWhen_PauserIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.pauser = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_UnpauserIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.unpauser = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_ConfigOperatorIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.configOperator = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
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

    function test_BaseVault_constructor_RevertWhen_EmergencyReceiverIsZeroAddress() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.emergencyReceiver = address(0);

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVault(params);
    }

    function test_BaseVault_constructor_RevertWhen_InitialDefaultCcipGasLimitIsZero() external {
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        params.initialDefaultCcipGasLimit = 0;

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        _deployParentVault(params);
    }

    function _deployParentVault(BaseVault.ConstructorParams memory params) internal {
        new ParentVault(params, i_treasury, address(s_yieldcoin), i_policyEngineManager, address(s_mockPolicyEngine));
    }
}
