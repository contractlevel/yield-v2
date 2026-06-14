// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

contract MockVault {
    error MockVault__NoZeroAddress();

    address internal immutable i_asset;

    constructor(address asset) {
        if (asset == address(0)) revert MockVault__NoZeroAddress();
        i_asset = asset;
    }

    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }
}