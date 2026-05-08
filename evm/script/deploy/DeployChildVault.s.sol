// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {ChildVault, BaseVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";

contract DeployChildVault is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        address deployer = msg.sender;

        AdapterRegistry adapterRegistry = new AdapterRegistry(deployer);

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

        bytes32 aaveV3ProtocolId = keccak256("aave-v3");
        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            address(childVault), networkConfig.tokens.usdc, networkConfig.protocols.aaveV3PoolAddressesProvider
        );
        adapterRegistry.setAdapter(aaveV3ProtocolId, address(aaveV3Adapter));
        adapterRegistry.transferOwnership(networkConfig.initialOwner);

        vm.stopBroadcast();
    }
}
