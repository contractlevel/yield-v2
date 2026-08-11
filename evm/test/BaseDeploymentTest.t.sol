// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseTest} from "./BaseTest.t.sol";

import {DeployParent} from "../script/deploy/DeployParent.s.sol";
import {DeployChild} from "../script/deploy/DeployChild.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

import {BaseVault} from "../src/vaults/BaseVault.sol";
import {ParentVault} from "../src/vaults/ParentVault.sol";
import {ChildVault} from "../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../src/modules/adapters/CompoundV3Adapter.sol";
import {WorkflowRouter} from "../src/modules/WorkflowRouter.sol";
import {YieldcoinShare} from "../src/token/YieldcoinShare.sol";
import {IProtocolAdapter} from "../src/interfaces/adapters/IProtocolAdapter.sol";
import {IAaveV4Spoke} from "../src/interfaces/external/IAaveV4Spoke.sol";
import {Roles} from "../src/libraries/Roles.sol";

abstract contract BaseDeploymentTest is BaseTest {
    struct Parent {
        address link;
        address asset;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
        AdapterRegistry adapterRegistry;
        YieldcoinShare shareImpl;
        YieldcoinShare share;
        ParentVault vaultImpl;
        ParentVault vault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
        WorkflowRouter workflowRouter;
    }

    struct Child {
        address link;
        address asset;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
        AdapterRegistry adapterRegistry;
        ChildVault vaultImpl;
        ChildVault vault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
        WorkflowRouter workflowRouter;
    }

    Parent internal parent;
    Child internal child;
    Child internal remoteChild;

    HelperConfig internal helperConfig;
    HelperConfig.NetworkConfig internal networkConfig;

    function setUp() public virtual {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getActiveNetworkConfig();
    }

    function _deployParent() internal {
        DeployParent.Deployment memory parentDeployment = new DeployParent().run();
        parent = _parentFromDeployment(parentDeployment);
        _labelParentIntegrationContracts();
    }

    function _deployChild() internal {
        DeployChild.Deployment memory childDeployment = new DeployChild().run();
        child = _childFromDeployment(childDeployment);
        _labelChildIntegrationContracts();
    }

    function _deployParentAndChild() internal {
        _deployParent();
        _deployChild();
    }

    function _parentFromDeployment(DeployParent.Deployment memory parentDeployment)
        internal
        pure
        returns (Parent memory parent_)
    {
        parent_ = Parent({
            link: parentDeployment.link,
            asset: parentDeployment.asset,
            aaveV3PoolAddressesProvider: parentDeployment.aaveV3PoolAddressesProvider,
            aaveV4Spoke: parentDeployment.aaveV4Spoke,
            compoundV3Comet: parentDeployment.compoundV3Comet,
            compoundV3CometRewards: parentDeployment.compoundV3CometRewards,
            adapterRegistry: parentDeployment.adapterRegistry,
            shareImpl: parentDeployment.yieldcoinImpl,
            share: parentDeployment.yieldcoinProxy,
            vaultImpl: parentDeployment.parentVaultImpl,
            vault: parentDeployment.parentVaultProxy,
            aaveV3Adapter: parentDeployment.aaveV3Adapter,
            aaveV4Adapter: parentDeployment.aaveV4Adapter,
            compoundV3Adapter: parentDeployment.compoundV3Adapter,
            workflowRouter: parentDeployment.workflowRouter
        });
    }

    function _childFromDeployment(DeployChild.Deployment memory childDeployment)
        internal
        pure
        returns (Child memory child_)
    {
        child_ = Child({
            link: childDeployment.link,
            asset: childDeployment.asset,
            aaveV3PoolAddressesProvider: childDeployment.aaveV3PoolAddressesProvider,
            aaveV4Spoke: childDeployment.aaveV4Spoke,
            compoundV3Comet: childDeployment.compoundV3Comet,
            compoundV3CometRewards: childDeployment.compoundV3CometRewards,
            adapterRegistry: childDeployment.adapterRegistry,
            vaultImpl: childDeployment.childVaultImpl,
            vault: childDeployment.childVaultProxy,
            aaveV3Adapter: childDeployment.aaveV3Adapter,
            aaveV4Adapter: childDeployment.aaveV4Adapter,
            compoundV3Adapter: childDeployment.compoundV3Adapter,
            workflowRouter: childDeployment.workflowRouter
        });
    }

    function _setCrosschainVault(BaseVault vault, uint64 chainSelector, address crosschainVault) internal {
        uint64[] memory chainSelectors = new uint64[](1);
        address[] memory vaults = new address[](1);
        chainSelectors[0] = chainSelector;
        vaults[0] = crosschainVault;

        _changePrank(networkConfig.roles.configOperator);
        vault.setCrosschainVaults(chainSelectors, vaults);
    }

    function _assertAdapterRegistered(AdapterRegistry registry, bytes32 protocolId, address adapter) internal view {
        assertEq(registry.getAdapter(protocolId), adapter);
    }

    function _assertProtocolAdapterConfigured(IProtocolAdapter adapter, address vault, address asset) internal view {
        assertEq(adapter.getVault(), vault);
        assertEq(adapter.getAsset(), asset);
    }

    function _assertOptionalAaveV3Adapter(
        AdapterRegistry registry,
        AaveV3Adapter adapter,
        address configuredProvider,
        address vault,
        address asset
    ) internal view {
        if (configuredProvider == address(0)) {
            assertEq(address(adapter), address(0));
            assertEq(registry.getAdapter(AAVE_V3_PROTOCOL_ID), address(0));
            return;
        }

        _assertAdapterRegistered(registry, AAVE_V3_PROTOCOL_ID, address(adapter));
        _assertProtocolAdapterConfigured(adapter, vault, asset);
        assertEq(adapter.getPoolAddressesProvider(), configuredProvider);
    }

    function _assertOptionalAaveV4Adapter(
        AdapterRegistry registry,
        AaveV4Adapter adapter,
        address configuredSpoke,
        address vault,
        address asset
    ) internal view {
        if (configuredSpoke == address(0)) {
            assertEq(address(adapter), address(0));
            assertEq(registry.getAdapter(AAVE_V4_PROTOCOL_ID), address(0));
            return;
        }

        _assertAdapterRegistered(registry, AAVE_V4_PROTOCOL_ID, address(adapter));
        _assertProtocolAdapterConfigured(adapter, vault, asset);
        assertEq(adapter.getProtocolPool(), configuredSpoke);
        assertEq(IAaveV4Spoke(configuredSpoke).getReserve(adapter.getReserveId()).underlying, asset);
    }

    function _assertOptionalCompoundV3Adapter(
        AdapterRegistry registry,
        CompoundV3Adapter adapter,
        address configuredComet,
        address configuredCometRewards,
        address vault,
        address asset
    ) internal view {
        if (configuredComet == address(0)) {
            assertEq(address(adapter), address(0));
            assertEq(registry.getAdapter(COMPOUND_V3_PROTOCOL_ID), address(0));
            return;
        }

        _assertAdapterRegistered(registry, COMPOUND_V3_PROTOCOL_ID, address(adapter));
        _assertProtocolAdapterConfigured(adapter, vault, asset);
        assertEq(adapter.getProtocolPool(), configuredComet);
        assertEq(adapter.getCometRewards(), configuredCometRewards);
    }

    function _labelParentIntegrationContracts() internal virtual {
        vm.label(address(parent.vault), "Integration ParentVault");
        vm.label(address(parent.share), "Integration YieldcoinShare");
    }

    function _labelChildIntegrationContracts() internal virtual {
        vm.label(address(child.vault), "Integration ChildVault");
    }

    function _labelRemoteChildIntegrationContracts() internal virtual {
        vm.label(address(remoteChild.vault), "Integration RemoteChildVault");
    }

    function test_baseDeploymentTest() public virtual {}
}
