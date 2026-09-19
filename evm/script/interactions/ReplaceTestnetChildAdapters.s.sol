// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {TestnetProtocolConfigurator} from "../deploy/TestnetProtocolConfigurator.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../src/modules/adapters/CompoundV3Adapter.sol";

/// @title ReplaceTestnetChildAdapters
/// @notice Replaces protocol adapters on an existing testnet ChildVault
contract ReplaceTestnetChildAdapters is Script {
    error ReplaceTestnetChildAdapters__UnsupportedChain(uint256 chainId);
    error ReplaceTestnetChildAdapters__ZeroVault();
    error ReplaceTestnetChildAdapters__ActiveAdapterExists(address adapter);
    error ReplaceTestnetChildAdapters__RegistryUpdateFailed(bytes32 protocolId, address adapter);

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256("aave-v3");
    bytes32 internal constant AAVE_V4_PROTOCOL_ID = keccak256("aave-v4");
    bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256("compound-v3");

    struct Replacement {
        address vault;
        AdapterRegistry registry;
        AaveV3Adapter aaveV3Adapter;
        AaveV4Adapter aaveV4Adapter;
        CompoundV3Adapter compoundV3Adapter;
    }

    function run() external returns (Replacement memory replacement) {
        _requireSupportedChildTestnet(block.chainid);

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        if (config.deployed.vaultProxy == address(0)) revert ReplaceTestnetChildAdapters__ZeroVault();

        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);
        address activeAdapter = vault.getActiveProtocolAdapter();
        if (activeAdapter != address(0)) {
            revert ReplaceTestnetChildAdapters__ActiveAdapterExists(activeAdapter);
        }

        vm.startBroadcast(msg.sender);
        replacement = replace(config, vault);
        vm.stopBroadcast();
    }

    function replace(HelperConfig.NetworkConfig memory config, IBaseVault vault)
        public
        returns (Replacement memory replacement)
    {
        replacement.vault = address(vault);
        replacement.registry = AdapterRegistry(vault.getAdapterRegistry());

        if (config.protocols.aaveV3PoolAddressesProvider != address(0)) {
            replacement.aaveV3Adapter = new AaveV3Adapter(address(vault), config.protocols.aaveV3PoolAddressesProvider);
        }
        if (config.protocols.aaveV4Spoke != address(0)) {
            replacement.aaveV4Adapter = new AaveV4Adapter(address(vault), config.protocols.aaveV4Spoke);
        }
        if (config.protocols.compoundV3Comet != address(0)) {
            replacement.compoundV3Adapter = new CompoundV3Adapter(
                address(vault), config.protocols.compoundV3Comet, config.protocols.compoundV3CometRewards
            );
        }

        TestnetProtocolConfigurator.authorizeAdapters(
            config.protocols,
            address(replacement.aaveV3Adapter),
            address(replacement.aaveV4Adapter),
            address(replacement.compoundV3Adapter)
        );

        _setAndVerify(replacement.registry, AAVE_V3_PROTOCOL_ID, address(replacement.aaveV3Adapter));
        _setAndVerify(replacement.registry, AAVE_V4_PROTOCOL_ID, address(replacement.aaveV4Adapter));
        _setAndVerify(replacement.registry, COMPOUND_V3_PROTOCOL_ID, address(replacement.compoundV3Adapter));
    }

    function _setAndVerify(AdapterRegistry registry, bytes32 protocolId, address adapter) private {
        registry.setAdapter(protocolId, adapter);
        if (registry.getAdapter(protocolId) != adapter) {
            revert ReplaceTestnetChildAdapters__RegistryUpdateFailed(protocolId, adapter);
        }
    }

    function _requireSupportedChildTestnet(uint256 chainId) private pure {
        if (chainId != 421614 && chainId != 11155111 && chainId != 11155420 && chainId != 43113 && chainId != 80002) {
            revert ReplaceTestnetChildAdapters__UnsupportedChain(chainId);
        }
    }
}
