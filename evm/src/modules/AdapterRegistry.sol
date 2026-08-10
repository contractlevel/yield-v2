// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

import {IAdapterRegistry} from "../interfaces/modules/IAdapterRegistry.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 Adapter Registry
/// @author @contractlevel
/// @notice Stores the protocol adapters available to the Yieldcoin v2 vault on this chain
contract AdapterRegistry is IAdapterRegistry, AccessControlDefaultAdminRules {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev Mapping of protocol IDs to adapter addresses
    mapping(bytes32 protocolId => address adapter) internal s_adapters;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    // deployment steps:
    // deploy AdapterRegistry
    // deploy Vault, passing AdapterRegistry address - if Parent Vault, pass initialActiveProtocolId too
    // deploy ProtocolAdapters
    // point ProtocolAdapters to AdapterRegistry
    /// @param initialDelay The initial delay for the default admin role
    /// @param initialOwner The address of the initial default admin
    /// @dev Reverts if initialOwner is the zero address
    //slither-disable-next-line missing-zero-check
    constructor(uint48 initialDelay, address initialOwner) AccessControlDefaultAdminRules(initialDelay, initialOwner) {}

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets or removes the adapter registered for a protocol ID
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @param adapter The adapter address, or address(0) to remove the registration
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if protocolId is zero
    /// @dev The adapter address may be zero to remove the registration
    /// @dev Does not validate whether a replaced or removed adapter is active in a vault
    //slither-disable-next-line missing-zero-check
    function setAdapter(bytes32 protocolId, address adapter) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        if (protocolId == bytes32(0)) revert AdapterRegistry__NoZeroProtocolId();
        s_adapters[protocolId] = adapter;
        emit AdapterSet(protocolId, adapter);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the adapter registered for a protocol ID
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @return adapter The registered adapter address, or address(0) if none is registered
    function getAdapter(bytes32 protocolId) external view returns (address adapter) {
        adapter = s_adapters[protocolId];
    }
}
