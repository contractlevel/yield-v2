// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVaultStore} from "../vaults/BaseVaultStore.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IAdapterRegistry} from "../interfaces/IAdapterRegistry.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/// @title Yieldcoin v2 BaseVault strategy adapter logic library
/// @author @contractlevel
/// @notice Handles shared active strategy adapter state transitions for BaseVault implementations.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the vault context.
library BaseVaultStrategyLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IBaseVault and emit from the vault via DELEGATECALL.
    event ActiveProtocolAdapterSet(bytes32 indexed protocolId, address indexed adapter);
    event ActiveProtocolAdapterCleared(address indexed adapter);

    /*//////////////////////////////////////////////////////////////
                                STRATEGY
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the active strategy protocol adapter.
    /// @param $ BaseVault namespaced storage
    /// @param protocolId The protocol ID of the strategy
    /// @param adapterRegistry The adapter registry
    /// @param vault The vault address expected by the registered adapter
    /// @return adapter The active strategy protocol adapter
    function setActiveAdapter(
        BaseVaultStore.BaseVaultStorage storage $,
        bytes32 protocolId,
        address adapterRegistry,
        address vault
    ) public returns (address adapter) {
        adapter = _setActiveAdapter($, protocolId, adapterRegistry, vault);
    }

    /// @notice Clears the active strategy protocol adapter for this chain.
    /// @param $ BaseVault namespaced storage
    function clearActiveAdapter(BaseVaultStore.BaseVaultStorage storage $) public {
        _clearActiveAdapter($);
    }

    function _setActiveAdapter(
        BaseVaultStore.BaseVaultStorage storage $,
        bytes32 protocolId,
        address adapterRegistry,
        address vault
    ) internal returns (address adapter) {
        adapter = IAdapterRegistry(adapterRegistry).getAdapter(protocolId);
        if (adapter == address(0)) revert IBaseVault.BaseVault__NoAdapterRegistered(protocolId);

        address adapterVault = IProtocolAdapter(adapter).getVault();
        if (adapterVault != vault) revert IBaseVault.BaseVault__InvalidAdapterVault(adapter, adapterVault, vault);

        $.s_activeProtocolAdapter = adapter;
        emit ActiveProtocolAdapterSet(protocolId, adapter);
    }

    function _clearActiveAdapter(BaseVaultStore.BaseVaultStorage storage $) internal {
        address adapter = $.s_activeProtocolAdapter;
        $.s_activeProtocolAdapter = address(0);
        emit ActiveProtocolAdapterCleared(adapter);
    }
}
