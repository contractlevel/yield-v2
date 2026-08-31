// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

contract ParentVault_DeploymentIntegrationTest is BaseIntegrationTest {
    function setUp() public override {
        super.setUp();
        _deployParent();
    }

    function test_ParentVault_deployment_GrantsExpectedVaultRoles() external view {
        assertEq(parent.vault.defaultAdmin(), address(this));
        assertTrue(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
        assertTrue(parent.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator));
        assertTrue(parent.vault.hasRole(Roles.REWARDS_OPERATOR_ROLE, networkConfig.roles.rewardsOperator));
        assertTrue(parent.vault.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(parent.vault.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(parent.vault.hasRole(Roles.UPGRADER_ROLE, networkConfig.roles.upgrader));
    }

    function test_ParentVault_deployment_DeploysVaultAsProxy() external view {
        assertGt(address(parent.vaultImpl).code.length, 0);
        assertGt(address(parent.vault).code.length, 0);
        assertNotEq(address(parent.vaultImpl), address(parent.vault));
    }

    function test_ParentVault_deployment_HandsOffVaultDefaultAdmin() external view {
        (address pendingAdmin, uint48 schedule) = parent.vault.pendingDefaultAdmin();

        assertEq(parent.vault.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + parent.vault.defaultAdminDelay());
    }

    function test_ParentVault_deployment_ConfiguresCoreAddresses() external view {
        assertEq(parent.vault.getAdapterRegistry(), address(parent.adapterRegistry));
        assertEq(parent.vault.getShare(), address(parent.share));
        assertEq(parent.vault.getTreasury(), networkConfig.treasury);
        assertEq(parent.vault.getAsset(), parent.asset);
        assertEq(parent.vault.getAssetPrecision(), 10 ** 6);
        assertEq(parent.vault.getSharePrecision(), 1e18);
        assertEq(parent.vault.getMinAssetAmount(), 1 * parent.vault.getAssetPrecision());
        assertEq(parent.vault.getLink(), parent.link);
        assertEq(parent.vault.getThisChainSelector(), networkConfig.ccip.parentChainSelector);
    }

    function test_ParentVault_deployment_ConfiguresShareInitialState() external view {
        assertGt(address(parent.shareImpl).code.length, 0);
        assertGt(address(parent.share).code.length, 0);
        assertNotEq(address(parent.shareImpl), address(parent.share));
        assertEq(parent.share.getCCIPAdmin(), networkConfig.roles.configOperator);
        assertEq(parent.share.defaultAdmin(), address(this));
        assertTrue(parent.share.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(parent.share.hasRole(Roles.UPGRADER_ROLE, networkConfig.roles.upgrader));
        assertTrue(parent.share.hasRole(Roles.MINTER_ROLE, address(parent.vault)));
        assertTrue(parent.share.hasRole(Roles.BURNER_ROLE, address(parent.vault)));
    }

    function test_ParentVault_deployment_RegistersAdapters() external view {
        _assertOptionalAaveV3Adapter(
            parent.adapterRegistry,
            parent.aaveV3Adapter,
            parent.aaveV3PoolAddressesProvider,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalAaveV4Adapter(
            parent.adapterRegistry, parent.aaveV4Adapter, parent.aaveV4Spoke, address(parent.vault), parent.asset
        );
        _assertOptionalCompoundV3Adapter(
            parent.adapterRegistry,
            parent.compoundV3Adapter,
            parent.compoundV3Comet,
            parent.compoundV3CometRewards,
            address(parent.vault),
            parent.asset
        );
    }

    function test_ParentVault_deployment_SetsSupportedProtocols() external view {
        assertTrue(parent.vault.getSupportedProtocol(AAVE_V3_PROTOCOL_ID));
        assertTrue(parent.vault.getSupportedProtocol(AAVE_V4_PROTOCOL_ID));
        assertTrue(parent.vault.getSupportedProtocol(COMPOUND_V3_PROTOCOL_ID));
    }

    function test_ParentVault_deployment_ConfiguresAdapters() external view {
        _assertOptionalAaveV3Adapter(
            parent.adapterRegistry,
            parent.aaveV3Adapter,
            parent.aaveV3PoolAddressesProvider,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalAaveV4Adapter(
            parent.adapterRegistry, parent.aaveV4Adapter, parent.aaveV4Spoke, address(parent.vault), parent.asset
        );
        _assertOptionalCompoundV3Adapter(
            parent.adapterRegistry,
            parent.compoundV3Adapter,
            parent.compoundV3Comet,
            parent.compoundV3CometRewards,
            address(parent.vault),
            parent.asset
        );
    }

    function test_ParentVault_deployment_ConfiguresAdapterRegistryRoles() external view {
        (address pendingAdmin, uint48 schedule) = parent.adapterRegistry.pendingDefaultAdmin();

        assertEq(parent.adapterRegistry.defaultAdmin(), address(this));
        assertEq(pendingAdmin, networkConfig.roles.defaultAdmin);
        assertEq(schedule, block.timestamp + parent.adapterRegistry.defaultAdminDelay());
        assertTrue(parent.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertFalse(parent.adapterRegistry.hasRole(Roles.CONFIG_OPERATOR_ROLE, address(this)));
    }

    function test_ParentVault_deployment_SetsDefaultCcipGasLimit() external view {
        assertEq(parent.vault.getDefaultCcipGasLimit(), networkConfig.ccip.initialDefaultCcipGasLimit);
    }

    function test_ParentVault_deployment_DoesNotSetParentAsCrosschainVault() external view {
        assertEq(parent.vault.getCrosschainVault(networkConfig.ccip.parentChainSelector), address(0));
    }

    function test_ParentVault_deployment_SetsInitialActiveAdapter() external view {
        assertTrue(parent.vault.getInitialActiveProtocolAdapterSet());
        if (parent.aaveV3PoolAddressesProvider != address(0)) {
            assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
        } else if (parent.aaveV4Spoke != address(0)) {
            assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV4Adapter));
        } else {
            assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.compoundV3Adapter));
        }
    }

    function test_ParentVault_deployment_ConfiguresWorkflowRouter() external view {
        assertEq(parent.workflowRouter.getVault(), address(parent.vault));
        assertEq(parent.workflowRouter.defaultAdmin(), networkConfig.roles.defaultAdmin);
        assertEq(parent.workflowRouter.defaultAdminDelay(), INITIAL_DEFAULT_ADMIN_DELAY);
        assertTrue(parent.workflowRouter.hasRole(Roles.DEFAULT_ADMIN_ROLE, networkConfig.roles.defaultAdmin));
        assertTrue(parent.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator));
        assertTrue(parent.workflowRouter.hasRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser));
        assertTrue(parent.workflowRouter.hasRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser));
        assertTrue(parent.workflowRouter.hasRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder));
    }
}
