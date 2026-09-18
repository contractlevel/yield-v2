// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkTest} from "../BaseForkTest.t.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

abstract contract BaseForkDeploymentTest is BaseForkTest {
    function _assertParentForkDeployment() internal view {
        assertEq(parent.vault.defaultAdmin(), parentForkDeployer);
        assertTrue(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, baseConfig.roles.configOperator));
        assertTrue(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, parentForkDeployer));
        assertTrue(parent.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.LINK_OPERATOR_ROLE, baseConfig.roles.linkOperator));
        assertTrue(parent.vault.hasRole(Roles.PAUSER_ROLE, baseConfig.roles.pauser));
        assertTrue(parent.vault.hasRole(Roles.UNPAUSER_ROLE, baseConfig.roles.unpauser));
        assertTrue(parent.vault.hasRole(Roles.UPGRADER_ROLE, baseConfig.roles.upgrader));

        assertGt(address(parent.vaultImpl).code.length, 0);
        assertNotEq(address(parent.vaultImpl), address(parent.vault));
        assertEq(parent.share.defaultAdmin(), parentForkDeployer);
        assertTrue(parent.share.hasRole(Roles.UPGRADER_ROLE, baseConfig.roles.upgrader));
        assertTrue(parent.share.hasRole(Roles.MINTER_ROLE, address(parent.vault)));
        assertTrue(parent.share.hasRole(Roles.BURNER_ROLE, address(parent.vault)));

        assertEq(parent.vault.getAdapterRegistry(), address(parent.adapterRegistry));
        assertEq(parent.vault.getShare(), address(parent.share));
        assertEq(parent.vault.getTreasury(), baseConfig.treasury);
        assertEq(parent.vault.getAsset(), parent.asset);
        assertEq(parent.vault.getAssetPrecision(), 10 ** 6);
        assertEq(parent.vault.getSharePrecision(), 1e18);
        assertEq(parent.vault.getMinAssetAmount(), 1 * parent.vault.getAssetPrecision());
        assertEq(parent.vault.getLink(), parent.link);
        assertEq(parent.vault.getThisChainSelector(), baseConfig.ccip.parentChainSelector);
        assertEq(parent.vault.getDefaultCcipGasLimit(), baseConfig.ccip.initialDefaultCcipGasLimit);
        assertEq(parent.vault.getCrosschainVault(baseConfig.ccip.parentChainSelector), address(0));
        assertEq(parent.workflowRouter.getVault(), address(parent.vault));
        assertTrue(parent.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, parentForkDeployer));
        assertTrue(parent.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, baseConfig.roles.configOperator));
        assertEq(parent.workflowRouter.defaultAdminDelay(), 0);
        assertTrue(parent.vault.getSupportedProtocol(AAVE_V3_PROTOCOL_ID));
        assertTrue(parent.vault.getSupportedProtocol(AAVE_V4_PROTOCOL_ID));
        assertTrue(parent.vault.getSupportedProtocol(COMPOUND_V3_PROTOCOL_ID));

        _assertOptionalAaveV3Adapter(
            parent.adapterRegistry,
            parent.aaveV3Adapter,
            baseConfig.protocols.aaveV3PoolAddressesProvider,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalAaveV4Adapter(
            parent.adapterRegistry,
            parent.aaveV4Adapter,
            baseConfig.protocols.aaveV4Spoke,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalCompoundV3Adapter(
            parent.adapterRegistry,
            parent.compoundV3Adapter,
            baseConfig.protocols.compoundV3Comet,
            baseConfig.protocols.compoundV3CometRewards,
            address(parent.vault),
            parent.asset
        );
    }

    function _assertParentForkCrosschainVaults() internal view {
        assertEq(parent.vault.getCrosschainVault(arbitrumConfig.ccip.thisChainSelector), address(arbitrumChild.vault));
        assertEq(parent.vault.getCrosschainVault(ethereumConfig.ccip.thisChainSelector), address(ethereumChild.vault));
        assertEq(parent.vault.getCrosschainVault(avalancheConfig.ccip.thisChainSelector), address(avalancheChild.vault));
        assertEq(parent.vault.getCrosschainVault(optimismConfig.ccip.thisChainSelector), address(optimismChild.vault));
        assertEq(parent.vault.getCrosschainVault(polygonConfig.ccip.thisChainSelector), address(polygonChild.vault));
    }

    function _assertChildForkDeployment(
        Child memory forkChild,
        HelperConfig.NetworkConfig memory config,
        address forkDeployer
    ) internal view {
        assertEq(forkChild.vault.defaultAdmin(), forkDeployer);
        assertTrue(forkChild.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, config.roles.configOperator));
        assertTrue(forkChild.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, forkDeployer));
        assertTrue(forkChild.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(forkChild.workflowRouter)));
        assertTrue(forkChild.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(forkChild.workflowRouter)));
        assertTrue(forkChild.vault.hasRole(Roles.LINK_OPERATOR_ROLE, config.roles.linkOperator));
        assertTrue(forkChild.vault.hasRole(Roles.PAUSER_ROLE, config.roles.pauser));
        assertTrue(forkChild.vault.hasRole(Roles.UNPAUSER_ROLE, config.roles.unpauser));
        assertTrue(forkChild.vault.hasRole(Roles.UPGRADER_ROLE, config.roles.upgrader));

        assertGt(address(forkChild.vaultImpl).code.length, 0);
        assertNotEq(address(forkChild.vaultImpl), address(forkChild.vault));

        assertEq(forkChild.vault.getAdapterRegistry(), address(forkChild.adapterRegistry));
        assertEq(forkChild.vault.getAsset(), forkChild.asset);
        assertEq(forkChild.vault.getAssetPrecision(), 10 ** 6);
        assertEq(forkChild.vault.getLink(), forkChild.link);
        assertEq(forkChild.vault.getThisChainSelector(), config.ccip.thisChainSelector);
        assertEq(forkChild.vault.getParentChainSelector(), config.ccip.parentChainSelector);
        assertEq(forkChild.vault.getDefaultCcipGasLimit(), config.ccip.initialDefaultCcipGasLimit);
        assertEq(forkChild.vault.getCrosschainVault(baseConfig.ccip.thisChainSelector), address(parent.vault));
        assertEq(forkChild.workflowRouter.getVault(), address(forkChild.vault));
        assertTrue(forkChild.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, forkDeployer));
        assertTrue(forkChild.workflowRouter.hasRole(Roles.CONFIG_OPERATOR_ROLE, config.roles.configOperator));
        assertEq(forkChild.workflowRouter.defaultAdminDelay(), 0);

        _assertOptionalAaveV3Adapter(
            forkChild.adapterRegistry,
            forkChild.aaveV3Adapter,
            config.protocols.aaveV3PoolAddressesProvider,
            address(forkChild.vault),
            forkChild.asset
        );
        _assertOptionalAaveV4Adapter(
            forkChild.adapterRegistry,
            forkChild.aaveV4Adapter,
            config.protocols.aaveV4Spoke,
            address(forkChild.vault),
            forkChild.asset
        );
        _assertOptionalCompoundV3Adapter(
            forkChild.adapterRegistry,
            forkChild.compoundV3Adapter,
            config.protocols.compoundV3Comet,
            config.protocols.compoundV3CometRewards,
            address(forkChild.vault),
            forkChild.asset
        );
    }

    function test_baseForkDeploymentTest() public virtual {}
}
