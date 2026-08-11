// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

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
    /// @dev Thrown when a protocol withdrawal returns zero assets
    error ProtocolAdapter__NoZeroAmount();
    /// @dev Thrown when an epoch withdraw amount exceeds the adapter TVL
    error ProtocolAdapter__WithdrawAmountExceedsTotalValue();
    /// @dev Thrown when the wired protocol's configured asset does not match the adapter's underlying asset
    error ProtocolAdapter__AssetMismatch();
    /// @dev Thrown when the protocol reports less TVL after a deposit than before it
    error ProtocolAdapter__TVLDecreasedOnDeposit();
    /// @dev Thrown when the protocol credits less than the requested deposit amount, beyond rounding tolerance
    error ProtocolAdapter__IncompleteDeposit();
    /// @dev Thrown when the protocol returns less underlying asset than the requested withdrawal amount
    error ProtocolAdapter__IncorrectWithdrawAmount();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit to the protocol is executed
    /// @param amount The amount of underlying asset deposited
    event Deposit(uint256 indexed amount);
    /// @notice Emitted when a withdrawal from the protocol is executed
    /// @param amount The amount of underlying asset withdrawn
    event Withdraw(uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the configured protocol position
    /// @param amount The amount of underlying asset to deposit
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the protocol reports a lower position value after the deposit
    /// @dev Reverts if the protocol credits less than amount beyond the permitted rounding tolerance
    function deposit(uint256 amount) external;
    /// @notice Withdraws the underlying asset from the configured protocol position and transfers it to the vault
    /// @param amount The amount of underlying asset to withdraw, or type(uint256).max to withdraw the entire position
    /// @return actualWithdrawnAmount The actual amount of underlying asset withdrawn
    /// @dev Handles two withdrawal scenarios:
    ///      1. Epoch withdrawal - when amount is a specific amount
    ///      2. Rebalance withdrawal - when amount is type(uint256).max
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a specific withdrawal amount exceeds the adapter's position value
    /// @dev Reverts if the protocol returns zero assets
    /// @dev Reverts if the protocol returns less than the expected amount beyond the permitted rounding tolerance
    function withdraw(uint256 amount) external returns (uint256 actualWithdrawnAmount);
    /// @notice Returns the underlying-asset value of the adapter's protocol position
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    function getTVL() external view returns (uint256 tvl);
    /// @notice Returns the address of the protocol pool
    /// @return pool The address of the protocol pool
    function getProtocolPool() external view returns (address pool);
    /// @notice Returns the Yieldcoin v2 Vault authorized to call this adapter
    /// @return vault The vault address
    function getVault() external view returns (address vault);
    /// @notice Returns the underlying asset token used by this adapter
    /// @return asset The underlying asset token address
    function getAsset() external view returns (address asset);
}
