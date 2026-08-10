// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Pauseable Interface
/// @author @contractlevel
/// @notice Interface for role-gated emergency pause/unpause of a Yieldcoin v2 contract
interface IPauseable {
    /// @notice Pauses the contract
    /// @dev Reverts if the caller does not have PAUSER_ROLE
    /// @dev Reverts if the contract is already paused
    function pause() external;

    /// @notice Unpauses the contract
    /// @dev Reverts if the caller does not have UNPAUSER_ROLE
    /// @dev Reverts if the contract is not paused
    function unpause() external;
}
