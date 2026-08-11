// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {TestnetProtocolConfigurator} from "./TestnetProtocolConfigurator.sol";
import {ParentVault, BaseVault} from "../../src/vaults/ParentVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../src/modules/adapters/CompoundV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
import {Roles} from "../../src/libraries/Roles.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployParent
/// @author @contractlevel
/// @notice Deploys and configures the ParentVault and its modules
contract DeployParent is Script {
    struct Deployment {
        address link;
        address asset;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
        AdapterRegistry adapterRegistry;
        YieldcoinShare yieldcoinImpl;
        YieldcoinShare yieldcoinProxy;
        ParentVault parentVaultImpl;
        ParentVault parentVaultProxy;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
        WorkflowRouter workflowRouter;
    }

    function run() external returns (Deployment memory deploy) {
        HelperConfig helperConfig = new HelperConfig();
        address deployer = msg.sender;
        vm.startBroadcast(deployer);
        deploy = deployWithConfig(helperConfig.getActiveNetworkConfig(), deployer);
        vm.stopBroadcast();
    }

    function deployWithConfig(HelperConfig.NetworkConfig memory config, address deployer)
        public
        returns (Deployment memory deploy)
    {
        deploy.link = config.tokens.link;
        deploy.asset = config.tokens.usdc;
        deploy.aaveV3PoolAddressesProvider = config.protocols.aaveV3PoolAddressesProvider;
        deploy.aaveV4Spoke = config.protocols.aaveV4Spoke;
        deploy.compoundV3Comet = config.protocols.compoundV3Comet;
        deploy.compoundV3CometRewards = config.protocols.compoundV3CometRewards;

        deploy.adapterRegistry = new AdapterRegistry(0, deployer);
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        deploy.yieldcoinImpl = new YieldcoinShare();
        deploy.yieldcoinProxy = YieldcoinShare(
            address(
                new ERC1967Proxy(
                    address(deploy.yieldcoinImpl),
                    abi.encodeCall(
                        YieldcoinShare.initialize,
                        (
                            deployer,
                            config.roles.pauser,
                            config.roles.unpauser,
                            config.roles.configOperator,
                            config.roles.configOperator,
                            config.roles.upgrader
                        )
                    )
                )
            )
        );

        BaseVault.ConstructorParams memory constructorParams = BaseVault.ConstructorParams({
            link: config.tokens.link,
            asset: config.tokens.usdc,
            ccipRouter: config.ccip.router,
            adapterRegistry: address(deploy.adapterRegistry),
            thisChainSelector: config.ccip.parentChainSelector
        });
        BaseVault.InitParams memory initParams = BaseVault.InitParams({
            defaultAdmin: deployer,
            pauser: config.roles.pauser,
            unpauser: config.roles.unpauser,
            configOperator: deployer,
            initialDefaultCcipGasLimit: config.ccip.initialDefaultCcipGasLimit,
            upgrader: config.roles.upgrader
        });
        deploy.parentVaultImpl = new ParentVault(constructorParams, address(deploy.yieldcoinProxy));
        deploy.parentVaultProxy = ParentVault(
            payable(address(
                    new ERC1967Proxy(
                        address(deploy.parentVaultImpl),
                        abi.encodeCall(
                            ParentVault.initialize, (initParams, config.treasury, config.roles.cancelDepositOperator)
                        )
                    )
                ))
        );

        bytes32 initialProtocolId = _deployAdapters(deploy, config);
        if (initialProtocolId != bytes32(0)) {
            deploy.parentVaultProxy.setInitialActiveProtocolAdapter(initialProtocolId);
        }

        deploy.parentVaultProxy.setSupportedProtocol(keccak256("aave-v3"), true);
        deploy.parentVaultProxy.setSupportedProtocol(keccak256("aave-v4"), true);
        deploy.parentVaultProxy.setSupportedProtocol(keccak256("compound-v3"), true);

        deploy.workflowRouter = new WorkflowRouter(
            WorkflowRouter.ConstructorParams({
                initialDelay: 3 days,
                defaultAdmin: config.roles.defaultAdmin,
                pauser: config.roles.pauser,
                unpauser: config.roles.unpauser,
                configOperator: config.roles.configOperator,
                keystoneForwarder: config.cre.keystoneForwarder,
                vault: address(deploy.parentVaultProxy)
            })
        );

        deploy.yieldcoinProxy.grantRole(Roles.MINTER_ROLE, address(deploy.parentVaultProxy));
        deploy.yieldcoinProxy.grantRole(Roles.BURNER_ROLE, address(deploy.parentVaultProxy));
        deploy.parentVaultProxy.grantRole(Roles.CONFIG_OPERATOR_ROLE, config.roles.configOperator);
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, config.roles.configOperator);
        deploy.parentVaultProxy.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.parentVaultProxy.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.parentVaultProxy.grantRole(Roles.LINK_OPERATOR_ROLE, config.roles.linkOperator);
        deploy.parentVaultProxy.grantRole(Roles.REWARDS_OPERATOR_ROLE, config.roles.rewardsOperator);
        deploy.parentVaultProxy.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        deploy.adapterRegistry.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        if (deployer != config.roles.defaultAdmin) {
            deploy.yieldcoinProxy.beginDefaultAdminTransfer(config.roles.defaultAdmin);
            deploy.parentVaultProxy.beginDefaultAdminTransfer(config.roles.defaultAdmin);
            deploy.adapterRegistry.beginDefaultAdminTransfer(config.roles.defaultAdmin);
        }
    }

    function _deployAdapters(Deployment memory deploy, HelperConfig.NetworkConfig memory config)
        internal
        returns (bytes32 initialProtocolId)
    {
        bytes32 protocolId = keccak256("aave-v3");
        if (config.protocols.aaveV3PoolAddressesProvider != address(0)) {
            deploy.aaveV3Adapter =
                new AaveV3Adapter(address(deploy.parentVaultProxy), config.protocols.aaveV3PoolAddressesProvider);
            deploy.adapterRegistry.setAdapter(protocolId, address(deploy.aaveV3Adapter));
            initialProtocolId = protocolId;
        }

        protocolId = keccak256("aave-v4");
        if (config.protocols.aaveV4Spoke != address(0)) {
            deploy.aaveV4Adapter = new AaveV4Adapter(address(deploy.parentVaultProxy), config.protocols.aaveV4Spoke);
            deploy.adapterRegistry.setAdapter(protocolId, address(deploy.aaveV4Adapter));
            if (initialProtocolId == bytes32(0)) initialProtocolId = protocolId;
        }

        protocolId = keccak256("compound-v3");
        if (config.protocols.compoundV3Comet != address(0)) {
            deploy.compoundV3Adapter = new CompoundV3Adapter(
                address(deploy.parentVaultProxy),
                config.protocols.compoundV3Comet,
                config.protocols.compoundV3CometRewards
            );
            deploy.adapterRegistry.setAdapter(protocolId, address(deploy.compoundV3Adapter));
            if (initialProtocolId == bytes32(0)) initialProtocolId = protocolId;
        }

        TestnetProtocolConfigurator.authorizeAdapters(
            config.protocols,
            address(deploy.aaveV3Adapter),
            address(deploy.aaveV4Adapter),
            address(deploy.compoundV3Adapter)
        );
    }
}
