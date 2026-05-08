// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @title Aave v4 Spoke Interface
/// @notice Minimal interface for the Aave v4 Spoke methods used by the Yieldcoin v2 adapter
interface IAaveV4Spoke {
    function supply(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    function withdraw(uint256 reserveId, uint256 amount, address to) external returns (uint256, uint256);

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256);
}
