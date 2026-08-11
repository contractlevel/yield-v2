// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPauseable} from "../common/IPauseable.sol";

/// @title Yieldcoin v2 Share Token Interface
/// @author @contractlevel
/// @notice Interface for the upgradeable ERC20 token representing shares in Yieldcoin v2
interface IShare is IERC20, IPauseable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when a required address is the zero address
    error YieldcoinShare__NoZeroAddress();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the Chainlink CCIP token administrator is updated
    /// @param previousAdmin The previous CCIP token administrator
    /// @param newAdmin The new CCIP token administrator
    event CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Mints shares to an address
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    /// @dev Reverts if the caller does not have MINTER_ROLE
    /// @dev Reverts if to is the zero address
    /// @dev Reverts if the token is paused
    function mint(address to, uint256 amount) external;

    /// @notice Burns shares from an address
    /// @param user The address to burn shares from
    /// @param amount The amount of shares to burn
    /// @dev Reverts if the caller does not have BURNER_ROLE
    /// @dev Reverts if user is the zero address
    /// @dev Reverts if amount exceeds the user's share balance
    /// @dev Reverts if the token is paused
    function burn(address user, uint256 amount) external;

    /// @notice Sets the Chainlink CCIP token admin identity
    /// @param newAdmin The new CCIP admin
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if newAdmin is the zero address
    function setCCIPAdmin(address newAdmin) external;

    /// @notice Returns the Chainlink CCIP token admin identity
    /// @return ccipAdmin The stored CCIP admin
    function getCCIPAdmin() external view returns (address ccipAdmin);
}
