// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @title Yieldcoin v2 Adapter Registry Interface
/// @author @contractlevel
/// @notice Interface for the AdapterRegistry
interface IAdapterRegistry {
    /// @notice Emitted when an adapter is set
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @param adapter The address of the adapter
    event AdapterSet(bytes32 indexed protocolId, address indexed adapter);

    /// @notice Gets the adapter for a given protocol ID
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @return adapter The address of the adapter
    function getAdapter(bytes32 protocolId) external view returns (address adapter);
}
