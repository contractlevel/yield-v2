// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IAaveV4Hub} from "../../../../../src/interfaces/external/IAaveV4Hub.sol";

contract MockAaveV4Hub is IAaveV4Hub {
    mapping(uint256 assetId => uint256 minimumAddAmount) public s_minimumAddAmount;
    bool public s_previewReverts;

    function previewAddByAssets(uint256 assetId, uint256 assets) external view returns (uint256 shares) {
        require(!s_previewReverts);
        shares = assets < s_minimumAddAmount[assetId] ? 0 : assets;
    }
}
