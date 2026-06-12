// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_ConstructorUnitTest is BaseUnitTest {
    function test_ParentVault_constructor() public {
        ParentVault parentVault = new ParentVault(
            _baseVaultParams(PARENT_CHAIN_SELECTOR),
            i_treasury,
            address(s_yieldcoin),
            i_policyEngineManager,
            address(s_mockPolicyEngine)
        );
        assertEq(parentVault.getThisChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(address(parentVault.getLink()), address(s_mockLink));
        assertEq(address(parentVault.getAsset()), address(s_mockUsdc));
        assertEq(parentVault.getAssetPrecision(), 10 ** uint256(s_mockUsdc.decimals()));
        assertEq(parentVault.getSharePrecision(), 1e18 / parentVault.getAssetPrecision());
        assertEq(parentVault.getMinDepositAmount(), 100 * parentVault.getAssetPrecision());
        assertEq(address(parentVault.getShare()), address(s_yieldcoin));
        assertEq(address(parentVault.getTreasury()), address(i_treasury));
        assertEq(address(parentVault.getRouter()), address(s_mockCcipRouter));
        assertEq(address(parentVault.getPolicyEngine()), address(s_mockPolicyEngine));
        assertEq(address(parentVault.getAdapterRegistry()), address(s_adapterRegistry));
        assertEq(parentVault.getEmergencyReceiver(), i_emergencyReceiver);
        assertEq(parentVault.hasRole(Roles.DEFAULT_ADMIN_ROLE, address(i_owner)), true);
        assertEq(parentVault.hasRole(Roles.PAUSER_ROLE, i_pauser), true);
        assertEq(parentVault.hasRole(Roles.UNPAUSER_ROLE, i_unpauser), true);
        assertEq(parentVault.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(i_configOperator)), true);
        assertEq(parentVault.hasRole(Roles.POLICY_ENGINE_MANAGER_ROLE, address(i_policyEngineManager)), true);
        assertEq(parentVault.getRebalance().nonce, 1);
        assertEq(parentVault.getPerformanceFeeHighWaterMark(), parentVault.getSharePrecision());
        assertEq(parentVault.getEpochNonce(), 1);
        assertEq(uint256(parentVault.getEpoch(1).status), uint256(Types.EpochStatus.OPEN));
        assertEq(parentVault.getEpoch(1).openedAtTimestamp, block.timestamp);
        assertEq(parentVault.getRebalance().lastRebalanceCompletedTimestamp, block.timestamp);
        assertEq(parentVault.getInitialActiveProtocolAdapterSet(), false);
        assertEq(parentVault.getRebalance().activeStrategy.protocolId, bytes32(0));
        assertEq(parentVault.getRebalance().activeStrategy.chainSelector, 0);
        assertEq(parentVault.getActiveProtocolAdapter(), address(0));
        assertEq(parentVault.getDefaultCcipGasLimit(), DEFAULT_CCIP_GAS_LIMIT);
    }

    function test_ParentVault_constructor_RevertWhen_TreasuryIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        new ParentVault(
            _baseVaultParams(PARENT_CHAIN_SELECTOR),
            address(0),
            address(s_yieldcoin),
            i_policyEngineManager,
            address(s_mockPolicyEngine)
        );
    }

    function test_ParentVault_constructor_RevertWhen_ShareIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        new ParentVault(
            _baseVaultParams(PARENT_CHAIN_SELECTOR),
            i_treasury,
            address(0),
            i_policyEngineManager,
            address(s_mockPolicyEngine)
        );
    }

    function test_ParentVault_constructor_RevertWhen_PolicyEngineManagerIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        new ParentVault(
            _baseVaultParams(PARENT_CHAIN_SELECTOR),
            i_treasury,
            address(s_yieldcoin),
            address(0),
            address(s_mockPolicyEngine)
        );
    }
}
