// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {ChildVault, BaseVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {Roles} from "../../src/libraries/Roles.sol";

/// @title DeployChild Script
/// @author @contractlevel
/// @notice Script to deploy the ChildVault and its modules
contract DeployChild is Script {
    struct Deployment {
        address link;
        address usdc;
        AdapterRegistry adapterRegistry;
        ChildVault childVault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
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
        deploy.link = networkConfig.tokens.link;
        deploy.usdc = networkConfig.tokens.usdc;

        /// @dev Deploy the AdapterRegistry
        deploy.adapterRegistry = new AdapterRegistry(
            0, /// @dev Initial delay for the default admin role
            deployer
        );
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev Deploy the ChildVault
        BaseVault.ConstructorParams memory baseVaultParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            usdc: networkConfig.tokens.usdc,
            ccipRouter: networkConfig.ccip.router,
            defaultAdmin: deployer,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: deployer,
            adapterRegistry: address(deploy.adapterRegistry),
            thisChainSelector: networkConfig.ccip.thisChainSelector
        });
        deploy.childVault = new ChildVault(baseVaultParams, networkConfig.ccip.parentChainSelector);

        /// @dev Deploy the Aave v3 Adapter
        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        deploy.aaveV3Adapter = new AaveV3Adapter(
            address(deploy.childVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
        );
        deploy.adapterRegistry.setAdapter(aaveV3ProtocolId, address(deploy.aaveV3Adapter));

        /// @dev Deploy the Aave v4 Adapter
        bytes32 aaveV4ProtocolId = keccak256("aave-v4");
        deploy.aaveV4Adapter = new AaveV4Adapter(
            address(deploy.childVault),
            networkConfig.tokens.usdc,
            networkConfig.protocols.aaveV4Spoke,
            networkConfig.protocols.aaveV4ReserveId
        );
        deploy.adapterRegistry.setAdapter(aaveV4ProtocolId, address(deploy.aaveV4Adapter));

        /// @dev Deploy the WorkflowRouter
        WorkflowRouter.ConstructorParams memory workflowRouterParams = WorkflowRouter.ConstructorParams({
            initialDelay: 0,
            defaultAdmin: deployer,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: networkConfig.roles.configOperator,
            keystoneForwarder: networkConfig.cre.keystoneForwarder,
            vault: address(deploy.childVault)
        });
        deploy.workflowRouter = new WorkflowRouter(workflowRouterParams);

        deploy.childVault.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        deploy.childVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.childVault.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(deploy.workflowRouter));
        deploy.childVault.grantRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer);
        deploy.childVault.grantRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator);

        deploy.childVault.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        deploy.adapterRegistry.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.childVault.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.workflowRouter.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            deploy.adapterRegistry.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        vm.stopBroadcast();
    }
}
