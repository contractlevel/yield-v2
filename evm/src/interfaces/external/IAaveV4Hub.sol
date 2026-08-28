// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Minimal Aave v4 Hub interface used by the Yieldcoin v2 adapter
interface IAaveV4Hub {
    /// @notice Previews the added shares minted for an asset amount, rounding down
    function previewAddByAssets(uint256 assetId, uint256 assets) external view returns (uint256 shares);
}
