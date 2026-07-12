// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Yieldcoin v2 Share Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 Share contract
/// @notice The YieldcoinShare token does not inherit this because Chainlink ACE's ComplianceTokenERC3643 functions are not virtual.
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
    /// @notice Sets the Chainlink CCIP token admin identity
    /// @param newAdmin The new CCIP admin
    /// @dev Precondition: newAdmin must not be the zero address
    function setCCIPAdmin(address newAdmin) external;
    /// @notice Gets the Chainlink CCIP token admin identity
    /// @return ccipAdmin The stored CCIP admin
    function getCCIPAdmin() external view returns (address ccipAdmin);
}
