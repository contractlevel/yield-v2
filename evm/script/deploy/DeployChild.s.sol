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
    struct ChildDeployment {
        AdapterRegistry adapterRegistry;
        ChildVault childVault;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        WorkflowRouter workflowRouter;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        address deployer = msg.sender;

        /// @dev Deploy the AdapterRegistry
        AdapterRegistry adapterRegistry = new AdapterRegistry(
            0, /// @dev Initial delay for the default admin role
            deployer
        );
        adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev Deploy the ChildVault
        BaseVault.ConstructorParams memory baseVaultParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            usdc: networkConfig.tokens.usdc,
            ccipRouter: networkConfig.ccip.router,
            defaultAdmin: deployer,
            pauser: networkConfig.roles.pauser,
            unpauser: networkConfig.roles.unpauser,
            configOperator: deployer,
            adapterRegistry: address(adapterRegistry),
            thisChainSelector: networkConfig.ccip.thisChainSelector
        });
        ChildVault childVault = new ChildVault(baseVaultParams, networkConfig.ccip.parentChainSelector);

        /// @dev Deploy the Aave v3 Adapter
        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            address(childVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
        );
        adapterRegistry.setAdapter(aaveV3ProtocolId, address(aaveV3Adapter));

        /// @dev Deploy the Aave v4 Adapter
        bytes32 aaveV4ProtocolId = keccak256("aave-v4");
        AaveV4Adapter aaveV4Adapter = new AaveV4Adapter(
            address(childVault),
            networkConfig.tokens.usdc,
            networkConfig.protocols.aaveV4Spoke,
            networkConfig.protocols.aaveV4ReserveId
        );
        adapterRegistry.setAdapter(aaveV4ProtocolId, address(aaveV4Adapter));

        /// @dev Deploy the WorkflowRouter
        WorkflowRouter workflowRouter = new WorkflowRouter(
            0, /// @dev Initial delay for the default admin role
            deployer,
            address(childVault)
        );
        childVault.setWorkflowRouter(address(workflowRouter));

        childVault.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        childVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(workflowRouter));
        childVault.grantRole(Roles.REBALANCE_OPERATOR_ROLE, address(workflowRouter));
        childVault.grantRole(Roles.EMERGENCY_DRAINER_ROLE, networkConfig.roles.emergencyDrainer);
        childVault.grantRole(Roles.LINK_OPERATOR_ROLE, networkConfig.roles.linkOperator);

        workflowRouter.grantRole(Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator);
        workflowRouter.grantRole(Roles.PAUSER_ROLE, networkConfig.roles.pauser);
        workflowRouter.grantRole(Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser);
        workflowRouter.grantRole(Roles.KEYSTONE_FORWARDER_ROLE, networkConfig.cre.keystoneForwarder);

        childVault.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        adapterRegistry.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);
        workflowRouter.revokeRole(Roles.CONFIG_OPERATOR_ROLE, deployer);

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            childVault.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            workflowRouter.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        /// @dev The deployer remains default admin until the configured default admin accepts this transfer.
        ///      networkConfig.roles.defaultAdmin should call acceptDefaultAdminTransfer() ASAP.
        if (deployer != networkConfig.roles.defaultAdmin) {
            adapterRegistry.beginDefaultAdminTransfer(networkConfig.roles.defaultAdmin);
        }

        vm.stopBroadcast();
    }
}
