// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract BaseVault_InitializeUnitTest is BaseUnitTest {
    function _deployVault(BaseVault.InitParams memory params) internal virtual returns (BaseVault vault);

    function _deployImplementation() internal virtual returns (address implementation);

    function _deployProxy(address implementation, BaseVault.InitParams memory params)
        internal
        virtual
        returns (BaseVault vault);

    function _initializeVault(BaseVault vault, BaseVault.InitParams memory params) internal virtual;

    function _initializeImplementation(address implementation, BaseVault.InitParams memory params) internal virtual;

    function test_BaseVault_initialize_Success_SetsMutableState() external {
        BaseVault vault = _deployVault(_baseVaultInitParams());

        assertEq(vault.getDefaultCcipGasLimit(), DEFAULT_CCIP_GAS_LIMIT);
        assertEq(uint256(vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
        assertEq(vault.paused(), false);
    }

    function test_BaseVault_initialize_Success_GrantsRoles() external {
        BaseVault vault = _deployVault(_baseVaultInitParams());

        assertTrue(vault.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner));
        assertTrue(vault.hasRole(Roles.PAUSER_ROLE, i_pauser));
        assertTrue(vault.hasRole(Roles.UNPAUSER_ROLE, i_unpauser));
        assertTrue(vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator));
        assertTrue(vault.hasRole(Roles.UPGRADER_ROLE, i_upgrader));
    }

    function test_BaseVault_initialize_RevertWhen_DefaultAdminIsZeroAddress() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.defaultAdmin = address(0);
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_PauserIsZeroAddress() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.pauser = address(0);
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_UnpauserIsZeroAddress() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.unpauser = address(0);
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_ConfigOperatorIsZeroAddress() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.configOperator = address(0);
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_UpgraderIsZeroAddress() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.upgrader = address(0);
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_InitialDefaultCcipGasLimitIsZero() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        params.initialDefaultCcipGasLimit = 0;
        address implementation = _deployImplementation();

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        _deployProxy(implementation, params);
    }

    function test_BaseVault_initialize_RevertWhen_AlreadyInitialized() external {
        BaseVault.InitParams memory params = _baseVaultInitParams();
        BaseVault vault = _deployVault(params);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _initializeVault(vault, params);
    }

    function test_BaseVault_initialize_RevertWhen_CalledOnImplementation() external {
        address implementation = _deployImplementation();

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _initializeImplementation(implementation, _baseVaultInitParams());
    }
}

contract ParentVault_BaseVaultInitializeUnitTest is BaseVault_InitializeUnitTest {
    function _deployVault(BaseVault.InitParams memory params) internal override returns (BaseVault vault) {
        vault = _deployProxy(_deployImplementation(), params);
    }

    function _deployImplementation() internal override returns (address implementation) {
        implementation = address(new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin)));
    }

    function _deployProxy(address implementation, BaseVault.InitParams memory params)
        internal
        override
        returns (BaseVault vault)
    {
        ERC1967Proxy parentVaultProxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSelector(
                ParentVault.initialize.selector,
                params,
                i_treasury,
                i_policyEngineManager,
                address(s_mockPolicyEngine),
                i_cancelDepositOperator
            )
        );
        vault = BaseVault(address(parentVaultProxy));
    }

    function _initializeVault(BaseVault vault, BaseVault.InitParams memory params) internal override {
        ParentVault(address(vault))
            .initialize(params, i_treasury, i_policyEngineManager, address(s_mockPolicyEngine), i_cancelDepositOperator);
    }

    function _initializeImplementation(address implementation, BaseVault.InitParams memory params) internal override {
        ParentVault(implementation)
            .initialize(params, i_treasury, i_policyEngineManager, address(s_mockPolicyEngine), i_cancelDepositOperator);
    }
}

contract ChildVault_BaseVaultInitializeUnitTest is BaseVault_InitializeUnitTest {
    function _deployVault(BaseVault.InitParams memory params) internal override returns (BaseVault vault) {
        vault = _deployProxy(_deployImplementation(), params);
    }

    function _deployImplementation() internal override returns (address implementation) {
        implementation = address(new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR));
    }

    function _deployProxy(address implementation, BaseVault.InitParams memory params)
        internal
        override
        returns (BaseVault vault)
    {
        ERC1967Proxy childVaultProxy =
            new ERC1967Proxy(implementation, abi.encodeWithSelector(ChildVault.initialize.selector, params));
        vault = BaseVault(address(childVaultProxy));
    }

    function _initializeVault(BaseVault vault, BaseVault.InitParams memory params) internal override {
        ChildVault(address(vault)).initialize(params);
    }

    function _initializeImplementation(address implementation, BaseVault.InitParams memory params) internal override {
        ChildVault(implementation).initialize(params);
    }
}
