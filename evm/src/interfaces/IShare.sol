// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Yieldcoin v2 Share Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 Share contract
interface IShare is IERC20 {
    /// @notice Mints shares to an address
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    function mint(address to, uint256 amount) external;
    /// @notice Burns shares from an address
    /// @param user The address to burn shares from
    /// @param amount The amount of shares to burn
    function burn(address user, uint256 amount) external;
    /// @notice Returns whether an address is frozen under ERC-3643 compliance controls
    /// @param user The address to check
    /// @return frozen True when the address is frozen
    function isFrozen(address user) external view returns (bool frozen);
}
