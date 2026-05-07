// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Yieldcoin v2 Share Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 Share contract
interface IShare is IERC20 {
    /// @notice Mints shares to an address
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    function mint(address to, uint256 amount) external;
    /// @notice Burns shares
    /// @param amount The amount of shares to burn
    function burn(uint256 amount) external;
}
