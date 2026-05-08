// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {ChildVault, BaseVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";

/// @title DeployChildVault
/// @author @contractlevel
/// @notice Script to deploy the ChildVault and its modules
contract DeployChildVault is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        address deployer = msg.sender;

        /// @dev Deploy the AdapterRegistry
        AdapterRegistry adapterRegistry = new AdapterRegistry(deployer);

        /// @dev Deploy the ChildVault
        BaseVault.ConstructorParams memory baseVaultParams = BaseVault.ConstructorParams({
            link: networkConfig.tokens.link,
            usdc: networkConfig.tokens.usdc,
            ccipRouter: networkConfig.ccip.router,
            defaultAdmin: networkConfig.defaultAdmin,
            pauser: networkConfig.pauser,
            unpauser: networkConfig.unpauser,
            configOperator: networkConfig.configOperator,
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

        /// @dev Transfer ownership of the AdapterRegistry to the initial owner
        /// @notice The initialOwner address needs to accept the ownership transfer!
        adapterRegistry.transferOwnership(networkConfig.initialOwner);

        vm.stopBroadcast();
    }
}
