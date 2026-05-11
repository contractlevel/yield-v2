// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

import {IAdapterRegistry} from "../interfaces/IAdapterRegistry.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 Adapter Registry
/// @author @contractlevel
/// @notice Registry for protocol adapters. This should be deployed on every chain.
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
    //slither-disable-next-line missing-zero-check
    constructor(uint48 initialDelay, address initialOwner) AccessControlDefaultAdminRules(initialDelay, initialOwner) {}

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets an adapter for a given protocol ID
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @param adapter The address of the adapter
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    //slither-disable-next-line missing-zero-check
    function setAdapter(bytes32 protocolId, address adapter) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        s_adapters[protocolId] = adapter;
        emit AdapterSet(protocolId, adapter);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the adapter for a given protocol ID
    /// @param protocolId The ID of the protocol - keccak256("aave-v3") for Aave v3, keccak256("compound-v3") for Compound v3, etc.
    /// @return adapter The address of the adapter
    function getAdapter(bytes32 protocolId) external view returns (address adapter) {
        adapter = s_adapters[protocolId];
    }
}
