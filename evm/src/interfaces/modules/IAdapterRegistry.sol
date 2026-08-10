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
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @param adapter The address of the adapter
    event AdapterSet(bytes32 indexed protocolId, address indexed adapter);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets or removes the adapter registered for a protocol ID
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @param adapter The adapter address, or address(0) to remove the registration
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if protocolId is zero
    /// @dev The adapter address may be zero to remove the registration
    /// @dev Does not validate whether a replaced or removed adapter is active in a vault
    function setAdapter(bytes32 protocolId, address adapter) external;
    /// @notice Returns the adapter registered for a protocol ID
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @return adapter The registered adapter address, or address(0) if none is registered
    function getAdapter(bytes32 protocolId) external view returns (address adapter);
}
