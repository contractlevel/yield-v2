// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseForkTest} from "../BaseForkTest.t.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

abstract contract BaseForkDeploymentTest is BaseForkTest {
    function _assertParentForkDeployment() internal view {
        assertEq(parent.vault.defaultAdmin(), parentForkDeployer);
        assertTrue(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, arbitrumConfig.roles.configOperator));
        assertFalse(parent.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, parentForkDeployer));
        assertTrue(parent.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(parent.workflowRouter)));
        assertTrue(parent.vault.hasRole(Roles.EMERGENCY_DRAINER_ROLE, arbitrumConfig.roles.emergencyDrainer));
        assertTrue(parent.vault.hasRole(Roles.LINK_OPERATOR_ROLE, arbitrumConfig.roles.linkOperator));
        assertTrue(parent.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, arbitrumConfig.roles.donateOperator));
        assertEq(
            parent.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, parentForkDeployer),
            parentForkDeployer == arbitrumConfig.roles.donateOperator
        );
        assertEq(parent.vault.getEmergencyReceiver(), arbitrumConfig.emergencyReceiver);
        assertTrue(parent.vault.hasRole(Roles.PAUSER_ROLE, arbitrumConfig.roles.pauser));
        assertTrue(parent.vault.hasRole(Roles.UNPAUSER_ROLE, arbitrumConfig.roles.unpauser));
        assertTrue(parent.vault.hasRole(Roles.POLICY_ENGINE_MANAGER_ROLE, arbitrumConfig.roles.policyEngineManager));

        assertEq(parent.vault.getAdapterRegistry(), address(parent.adapterRegistry));
        assertEq(parent.vault.getShare(), address(parent.share));
        assertEq(parent.vault.getTreasury(), arbitrumConfig.treasury);
        assertEq(parent.identityRegistry.getIdentity(arbitrumConfig.treasury), parent.treasuryCcid);
        assertTrue(parent.vaultKycPolicy.validate(arbitrumConfig.treasury, ""));
        assertTrue(parent.shareKycPolicy.validate(arbitrumConfig.treasury, ""));
        assertEq(parent.vault.getAsset(), parent.asset);
        assertEq(parent.vault.getAssetPrecision(), 10 ** 6);
        assertEq(parent.vault.getSharePrecision(), 1e18 / parent.vault.getAssetPrecision());
        assertEq(parent.vault.getMinDepositAmount(), 100 * parent.vault.getAssetPrecision());
        assertEq(parent.vault.getLink(), parent.link);
        assertEq(parent.vault.getThisChainSelector(), arbitrumConfig.ccip.parentChainSelector);
        assertEq(parent.vault.getDefaultCcipGasLimit(), arbitrumConfig.ccip.initialDefaultCcipGasLimit);
        assertEq(parent.workflowRouter.getVault(), address(parent.vault));

        _assertOptionalAaveV3Adapter(
            parent.adapterRegistry,
            parent.aaveV3Adapter,
            arbitrumConfig.protocols.aaveV3PoolAddressesProvider,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalAaveV4Adapter(
            parent.adapterRegistry,
            parent.aaveV4Adapter,
            arbitrumConfig.protocols.aaveV4Spoke,
            address(parent.vault),
            parent.asset
        );
        _assertOptionalCompoundV3Adapter(
            parent.adapterRegistry,
            parent.compoundV3Adapter,
            arbitrumConfig.protocols.compoundV3Comet,
            arbitrumConfig.protocols.compoundV3CometRewards,
            address(parent.vault),
            parent.asset
        );
    }

    function _assertParentForkCrosschainVaults() internal view {
        assertEq(parent.vault.getCrosschainVault(baseConfig.ccip.thisChainSelector), address(baseChild.vault));
        assertEq(parent.vault.getCrosschainVault(ethereumConfig.ccip.thisChainSelector), address(ethereumChild.vault));
        assertEq(parent.vault.getCrosschainVault(avalancheConfig.ccip.thisChainSelector), address(avalancheChild.vault));
        assertEq(parent.vault.getCrosschainVault(optimismConfig.ccip.thisChainSelector), address(optimismChild.vault));
    }

    function _assertChildForkDeployment(
        Child memory forkChild,
        HelperConfig.NetworkConfig memory config,
        address forkDeployer
    ) internal view {
        assertEq(forkChild.vault.defaultAdmin(), forkDeployer);
        assertTrue(forkChild.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, config.roles.configOperator));
        assertFalse(forkChild.vault.hasRole(Roles.CONFIG_OPERATOR_ROLE, forkDeployer));
        assertTrue(forkChild.vault.hasRole(Roles.EPOCH_OPERATOR_ROLE, address(forkChild.workflowRouter)));
        assertTrue(forkChild.vault.hasRole(Roles.REBALANCE_OPERATOR_ROLE, address(forkChild.workflowRouter)));
        assertTrue(forkChild.vault.hasRole(Roles.EMERGENCY_DRAINER_ROLE, config.roles.emergencyDrainer));
        assertTrue(forkChild.vault.hasRole(Roles.LINK_OPERATOR_ROLE, config.roles.linkOperator));
        assertTrue(forkChild.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, config.roles.donateOperator));
        assertEq(
            forkChild.vault.hasRole(Roles.DONATE_OPERATOR_ROLE, forkDeployer),
            forkDeployer == config.roles.donateOperator
        );
        assertEq(forkChild.vault.getEmergencyReceiver(), config.emergencyReceiver);
        assertTrue(forkChild.vault.hasRole(Roles.PAUSER_ROLE, config.roles.pauser));
        assertTrue(forkChild.vault.hasRole(Roles.UNPAUSER_ROLE, config.roles.unpauser));

        assertEq(forkChild.vault.getAdapterRegistry(), address(forkChild.adapterRegistry));
        assertEq(forkChild.vault.getAsset(), forkChild.asset);
        assertEq(forkChild.vault.getAssetPrecision(), 10 ** 6);
        assertEq(forkChild.vault.getLink(), forkChild.link);
        assertEq(forkChild.vault.getThisChainSelector(), config.ccip.thisChainSelector);
        assertEq(forkChild.vault.getParentChainSelector(), config.ccip.parentChainSelector);
        assertEq(forkChild.vault.getDefaultCcipGasLimit(), config.ccip.initialDefaultCcipGasLimit);
        assertEq(forkChild.vault.getCrosschainVault(arbitrumConfig.ccip.thisChainSelector), address(parent.vault));
        assertEq(forkChild.workflowRouter.getVault(), address(forkChild.vault));

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
