// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Compound v3 Comet Interface
/// @notice Minimal Compound v3 Comet interface used by the CompoundV3Adapter
interface IComet {
    /// @notice Supplies an amount of asset from the caller to the protocol, crediting the caller's balance
    /// @dev The Comet pulls `asset` from the caller, so prior token approval is required
    /// @param asset The address of the asset to supply
    /// @param amount The amount of asset to supply
    function supply(address asset, uint256 amount) external;

    /// @notice Withdraws an amount of asset from the caller's balance in the protocol, or borrows it if `asset`
    /// is the base token and `amount` exceeds the caller's supplied base balance
    /// @param asset The address of the asset to withdraw
    /// @param amount The amount of asset to withdraw
    function withdraw(address asset, uint256 amount) external;

    /// @notice Returns the base token balance of an account, including accrued interest
    /// @dev Only reflects the base asset (e.g. USDC); returns 0 if the account is net borrowing the base asset
    /// @param account The address of the account
    /// @return The base token balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the address of this Comet market's base asset
    /// @return The address of the base token
    function baseToken() external view returns (address);
}
