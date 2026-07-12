// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ParentVault_InitializeUnitTest is BaseUnitTest {
    function test_ParentVault_initialize_Success_SetsParentState() external {
        ParentVault parentVault =
            _deployParentVaultProxy(_baseVaultInitParams(), i_treasury, i_policyEngineManager, i_cancelDepositOperator);
        Types.Rebalance memory rebalance = parentVault.getRebalance();
        Types.Epoch memory epoch = parentVault.getEpoch(1);

        assertEq(parentVault.getTreasury(), i_treasury);
        assertEq(parentVault.getPolicyEngine(), address(s_mockPolicyEngine));
        assertEq(parentVault.getPerformanceFeeHighWaterMark(), parentVault.getSharePrecision());
        assertEq(parentVault.getEpochNonce(), 1);
        assertEq(parentVault.getInitialActiveProtocolAdapterSet(), false);
        assertEq(parentVault.getActiveProtocolAdapter(), address(0));
        assertEq(rebalance.nonce, 1);
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.activeStrategy.protocolId, bytes32(0));
        assertEq(rebalance.activeStrategy.chainSelector, 0);
        assertEq(rebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(rebalance.pendingStrategy.chainSelector, 0);
        assertEq(rebalance.lastRebalanceCompletedTimestamp, block.timestamp);
        assertEq(uint256(epoch.status), uint256(Types.EpochStatus.OPEN));
        assertEq(epoch.openedAtTimestamp, block.timestamp);
        assertEq(epoch.closedAtTimestamp, 0);
    }

    function test_ParentVault_initialize_Success_GrantsPolicyEngineManagerRole() external {
        ParentVault parentVault =
            _deployParentVaultProxy(_baseVaultInitParams(), i_treasury, i_policyEngineManager, i_cancelDepositOperator);

        assertTrue(parentVault.hasRole(Roles.POLICY_ENGINE_MANAGER_ROLE, i_policyEngineManager));
    }

    function test_ParentVault_initialize_Success_GrantsCancelDepositOperatorRole() external {
        ParentVault parentVault =
            _deployParentVaultProxy(_baseVaultInitParams(), i_treasury, i_policyEngineManager, i_cancelDepositOperator);

        assertTrue(parentVault.hasRole(Roles.CANCEL_DEPOSIT_OPERATOR_ROLE, i_cancelDepositOperator));
    }

    function test_ParentVault_initialize_RevertWhen_TreasuryIsZeroAddress() external {
        ParentVault parentVaultImpl = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVaultProxy(
            address(parentVaultImpl), _baseVaultInitParams(), address(0), i_policyEngineManager, i_cancelDepositOperator
        );
    }

    function test_ParentVault_initialize_RevertWhen_PolicyEngineManagerIsZeroAddress() external {
        ParentVault parentVaultImpl = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVaultProxy(
            address(parentVaultImpl), _baseVaultInitParams(), i_treasury, address(0), i_cancelDepositOperator
        );
    }

    function test_ParentVault_initialize_RevertWhen_CancelDepositOperatorIsZeroAddress() external {
        ParentVault parentVaultImpl = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));

        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        _deployParentVaultProxy(
            address(parentVaultImpl), _baseVaultInitParams(), i_treasury, i_policyEngineManager, address(0)
        );
    }

    function test_ParentVault_initialize_RevertWhen_PolicyEngineIsZeroAddress() external {
        ParentVault parentVaultImpl = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));

        vm.expectRevert("Policy engine is zero address");
        new ERC1967Proxy(
            address(parentVaultImpl),
            abi.encodeWithSelector(
                ParentVault.initialize.selector,
                _baseVaultInitParams(),
                i_treasury,
                i_policyEngineManager,
                address(0),
                i_cancelDepositOperator
            )
        );
    }

    function _deployParentVaultProxy(
        BaseVault.InitParams memory initParams,
        address treasury,
        address policyEngineManager,
        address cancelDepositOperator
    ) internal returns (ParentVault parentVault) {
        ParentVault parentVaultImpl = new ParentVault(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin));
        parentVault = _deployParentVaultProxy(
            address(parentVaultImpl), initParams, treasury, policyEngineManager, cancelDepositOperator
        );
    }

    function _deployParentVaultProxy(
        address implementation,
        BaseVault.InitParams memory initParams,
        address treasury,
        address policyEngineManager,
        address cancelDepositOperator
    ) internal returns (ParentVault parentVault) {
        ERC1967Proxy parentVaultProxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSelector(
                ParentVault.initialize.selector,
                initParams,
                treasury,
                policyEngineManager,
                address(s_mockPolicyEngine),
                cancelDepositOperator
            )
        );
        parentVault = ParentVault(address(parentVaultProxy));
    }
}
