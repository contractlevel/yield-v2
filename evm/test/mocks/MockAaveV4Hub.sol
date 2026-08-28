// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockAaveV4Hub {
    error MockAaveV4Hub__PreviewReverts(uint256 assets);

    uint256 internal s_minimumAssetsForShares = 1;
    bool internal s_previewReverts;

    function setMinimumAssetsForShares(uint256 amount) external {
        s_minimumAssetsForShares = amount;
    }

    function setPreviewReverts(bool previewReverts) external {
        s_previewReverts = previewReverts;
    }

    function previewAddByAssets(uint256, uint256 assets) external view returns (uint256 shares) {
        if (s_previewReverts) revert MockAaveV4Hub__PreviewReverts(assets);
        if (assets >= s_minimumAssetsForShares) shares = assets;
    }
}
