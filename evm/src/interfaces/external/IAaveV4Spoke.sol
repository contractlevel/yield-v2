// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Aave v4 Spoke Interface
/// @notice Minimal interface for the Aave v4 Spoke methods used by the Yieldcoin v2 adapter
interface IAaveV4Spoke {
    /// @notice Reserve level data, as stored on the Aave v4 Spoke
    /// @param underlying The address of the underlying asset
    /// @param hub The address of the associated Hub
    /// @param assetId The identifier of the asset in the Hub
    /// @param decimals The number of decimals of the underlying asset
    /// @param collateralRisk The risk associated with the reserve as collateral, expressed in BPS
    /// @param flags The packed boolean flags of the reserve (e.g. paused, frozen, borrowable)
    /// @param dynamicConfigKey The key of the last reserve dynamic config
    struct Reserve {
        address underlying;
        address hub;
        uint16 assetId;
        uint8 decimals;
        uint24 collateralRisk;
        uint8 flags;
        uint32 dynamicConfigKey;
    }

    /// @notice Supplies an amount of underlying asset of the specified reserve.
    /// @dev It reverts if the reserve associated with the given reserve identifier is not listed.
    /// @dev The Spoke pulls the underlying asset from the caller, so prior token approval is required.
    /// @dev Caller must be `onBehalfOf` or an authorized position manager for `onBehalfOf`.
    /// @param reserveId The reserve identifier.
    /// @param amount The amount of asset to supply.
    /// @param onBehalfOf The owner of the position to add supply shares to.
    /// @return The amount of shares supplied.
    /// @return The amount of assets supplied.
    function supply(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256);

    /// @notice Withdraws a specified amount of underlying asset from the given reserve.
    /// @dev It reverts if the reserve associated with the given reserve identifier is not listed.
    /// @dev Providing an amount greater than the maximum withdrawable value signals a full withdrawal.
    /// @dev Caller must be `onBehalfOf` or an authorized position manager for `onBehalfOf`.
    /// @dev Caller receives the underlying asset withdrawn.
    /// @param reserveId The identifier of the reserve.
    /// @param amount The amount of asset to withdraw.
    /// @param onBehalfOf The owner of position to remove supply shares from.
    /// @return The amount of shares withdrawn.
    /// @return The amount of assets withdrawn.
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256);

    /// @notice Returns the amount of assets supplied by a specific user for a given reserve
    /// @dev Reverts if the reserve associated with `reserveId` is not listed
    /// @param reserveId The identifier of the reserve
    /// @param user The address of the user
    /// @return The amount of assets supplied by the user
    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256);

    /// @notice Returns the number of listed reserves on the Spoke
    /// @dev Count includes reserves that are not currently active
    /// @return The number of listed reserves
    function getReserveCount() external view returns (uint256);

    /// @notice Returns the reserve struct data in storage for a given reserve
    /// @dev Reverts if the reserve associated with `reserveId` is not listed
    /// @param reserveId The identifier of the reserve
    /// @return The reserve struct
    function getReserve(uint256 reserveId) external view returns (Reserve memory);
}
