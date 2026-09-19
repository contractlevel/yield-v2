// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IAaveV4Hub} from "../../../src/interfaces/external/IAaveV4Hub.sol";

contract TestnetAaveV4Hub is IAaveV4Hub {
    function previewAddByAssets(uint256, uint256 assets) external pure returns (uint256 shares) {
        return assets;
    }
}
