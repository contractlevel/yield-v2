// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @title Yieldcoin v2 Protocol Adapter Interface
/// @author @contractlevel
/// @notice Interface for a protocol adapter
interface IProtocolAdapter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the caller is not the Yieldcoin v2 Vault
    error ProtocolAdapter__OnlyVault();
    /// @dev Thrown when the zero address is provided
    error ProtocolAdapter__NoZeroAddress();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit to the protocol is executed
    /// @param amount The amount of asset deposited
    event Deposit(uint256 indexed amount);
    /// @notice Emitted when a withdrawal from the protocol is executed
    /// @param amount The amount of asset withdrawn
    event Withdraw(uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the protocol
    /// @param amount The amount of asset to deposit
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    function deposit(uint256 amount) external;
    /// @notice Withdraws the underlying asset from the protocol
    /// @param amount The amount of asset to withdraw
    /// @return amountOut The actual amount of asset withdrawn
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    function withdraw(uint256 amount) external returns (uint256 amountOut);
    /// @notice Gets the total value locked in the protocol
    /// @return tvl The total value locked in the protocol
    function getTVL() external view returns (uint256 tvl);
    /// @notice Gets the address of the protocol pool
    /// @return pool The address of the protocol pool
    function getProtocolPool() external view returns (address pool);
    /// @notice Gets the Yieldcoin v2 Vault authorized to call this adapter
    /// @return vault The vault address
    function getVault() external view returns (address vault);
    /// @notice Gets the underlying asset token used by this adapter
    /// @return asset The underlying asset token address
    function getAsset() external view returns (address asset);
}
