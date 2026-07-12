// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Aave v4 Spoke Interface
/// @notice Minimal interface for the Aave v4 Spoke methods used by the Yieldcoin v2 adapter
interface IAaveV4Spoke {
    struct Reserve {
        address underlying;
        address hub;
        uint16 assetId;
        uint8 decimals;
        uint24 collateralRisk;
        uint8 flags;
        uint32 dynamicConfigKey;
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        returns (uint256 suppliedShares, uint256 suppliedAmount);

    function withdraw(uint256 reserveId, uint256 amount, address to) external returns (uint256, uint256);

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256);

    function getReserveCount() external view returns (uint256);

    function getReserve(uint256 reserveId) external view returns (Reserve memory);
}
