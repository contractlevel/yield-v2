// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Adapter Registry Interface
/// @author @contractlevel
/// @notice Interface for the AdapterRegistry
interface IAdapterRegistry {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the zero protocol ID is provided
    error AdapterRegistry__NoZeroProtocolId();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when an adapter is set
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @param adapter The address of the adapter
    event AdapterSet(bytes32 indexed protocolId, address indexed adapter);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets an adapter for a given protocol ID
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @param adapter The address of the adapter
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: protocolId must not be zero
    /// @dev Explicitly no zero address check on adapter
    /// @dev Set `adapter` to address(0) to remove the adapter for `protocolId`
    function setAdapter(bytes32 protocolId, address adapter) external;
    /// @notice Gets the adapter for a given protocol ID
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @return adapter The address of the adapter
    function getAdapter(bytes32 protocolId) external view returns (address adapter);
}
