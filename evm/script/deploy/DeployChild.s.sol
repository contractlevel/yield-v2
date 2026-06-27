// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {ChildVault, BaseVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../src/modules/adapters/CompoundV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {Roles} from "../../src/libraries/Roles.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployChild Script
/// @author @contractlevel
/// @notice Script to deploy the ChildVault and its modules
contract DeployChild is Script {
    struct Deployment {
        address link;
        address asset;
        address aaveV3PoolAddressesProvider;
        address aaveV4Spoke;
        address compoundV3Comet;
        address compoundV3CometRewards;
        AdapterRegistry adapterRegistry;
        ChildVault childVaultImpl;
        ChildVault childVaultProxy;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
        WorkflowRouter workflowRouter;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external returns (Deployment memory deploy) {
        HelperConfig helperConfig = new HelperConfig();

        address deployer = msg.sender;
        vm.startBroadcast(deployer);
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        deploy = deployWithConfig(networkConfig, deployer);
        vm.stopBroadcast();
    }

    function deployWithConfig(HelperConfig.NetworkConfig memory networkConfig, address deployer)
        public
        returns (Deployment memory deploy)
    {
        deploy.link = networkConfig.tokens.link;
        deploy.asset = networkConfig.tokens.usdc;
        deploy.aaveV3PoolAddressesProvider = networkConfig.protocols.aaveV3PoolAddressesProvider;
        deploy.aaveV4Spoke = networkConfig.protocols.aaveV4Spoke;
        deploy.compoundV3Comet = networkConfig.protocols.compoundV3Comet;
        deploy.compoundV3CometRewards = networkConfig.protocols.compoundV3CometRewards;

        /// @dev Deploy the AdapterRegistry
        deploy.adapterRegistry = new AdapterRegistry(
            0, /// @dev Initial delay for the default admin role
            deployer
        );
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev Deploy the ChildVault implementation with immutable params, then initialize proxy state atomically.
        BaseVault.ConstructorParams memory baseVaultConstructorParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            asset: networkConfig.tokens.usdc,
            ccipRouter: networkConfig.ccip.router,
            adapterRegistry: address(deploy.adapterRegistry),
            thisChainSelector: networkConfig.ccip.thisChainSelector
        });
        BaseVault.InitParams memory baseVaultInitParams = BaseVault.InitParams({
            defaultAdmin: deployer,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: deployer,
            emergencyReceiver: networkConfig.emergencyReceiver,
            initialDefaultCcipGasLimit: networkConfig.ccip.initialDefaultCcipGasLimit,
            upgrader: networkConfig.roles.upgrader
        });
        deploy.childVaultImpl = new ChildVault(baseVaultConstructorParams, networkConfig.ccip.parentChainSelector);
        ERC1967Proxy childVaultProxy = new ERC1967Proxy(
            address(deploy.childVaultImpl), abi.encodeWithSelector(ChildVault.initialize.selector, baseVaultInitParams)
        );
        deploy.childVaultProxy = ChildVault(address(childVaultProxy));

        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        if (networkConfig.protocols.aaveV3PoolAddressesProvider != address(0)) {
            deploy.aaveV3Adapter =
                new AaveV3Adapter(address(deploy.childVaultProxy), networkConfig.protocols.aaveV3PoolAddressesProvider);
            deploy.adapterRegistry.setAdapter(aaveV3ProtocolId, address(deploy.aaveV3Adapter));
        }

        bytes32 aaveV4ProtocolId = keccak256("aave-v4");
        if (networkConfig.protocols.aaveV4Spoke != address(0)) {
            deploy.aaveV4Adapter =
                new AaveV4Adapter(address(deploy.childVaultProxy), networkConfig.protocols.aaveV4Spoke);
            deploy.adapterRegistry.setAdapter(aaveV4ProtocolId, address(deploy.aaveV4Adapter));
        }

        bytes32 compoundV3ProtocolId = keccak256("compound-v3");
        if (networkConfig.protocols.compoundV3Comet != address(0)) {
            deploy.compoundV3Adapter = new CompoundV3Adapter(
                address(deploy.childVaultProxy),
                networkConfig.protocols.compoundV3Comet,
                networkConfig.protocols.compoundV3CometRewards
            );
            deploy.adapterRegistry.setAdapter(compoundV3ProtocolId, address(deploy.compoundV3Adapter));
        }

        /// @dev Deploy the WorkflowRouter
        uint48 initialDelay = 259200; // 3 days
        WorkflowRouter.ConstructorParams memory workflowRouterParams = WorkflowRouter.ConstructorParams({
            initialDelay: initialDelay,
            defaultAdmin: networkConfig.roles.defaultAdmin,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: networkConfig.roles.configOperator,
            keystoneForwarder: networkConfig.cre.keystoneForwarder,
            vault: address(deploy.childVaultProxy)
        });
        deploy.workflowRouter = new WorkflowRouter(workflowRouterParams);

        deploy.childVaultProxy.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.childVaultProxy.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.childVaultProxy.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.childVaultProxy.grantRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer);
        deploy.childVaultProxy.grantRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator);
        deploy.childVaultProxy.grantRole(Roles.DONATE_OPERATOR_ROLE, networkConfig.roles.donateOperator);
        deploy.childVaultProxy.grantRole(Roles.REWARDS_OPERATOR_ROLE, networkConfig.roles.rewardsOperator);

        deploy.childVaultProxy.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        deploy.adapterRegistry.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.childVaultProxy.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.adapterRegistry.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }
    }
}
