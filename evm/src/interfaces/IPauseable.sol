// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Pauseable Interface
/// @author @contractlevel
interface IPauseable {
    /// @notice Pauses the contract
    /// @dev Precondition: Caller must have the PAUSER_ROLE
    function pause() external;

    /// @notice Unpauses the contract
    /// @dev Precondition: Caller must have the UNPAUSER_ROLE
    function unpause() external;
}
