// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

contract MockAccessControlVault {
    address internal immutable i_asset;

    mapping(bytes32 role => mapping(address account => bool hasRole)) internal s_hasRole;

    constructor(address asset) {
        i_asset = asset;
    }

    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return s_hasRole[role][account];
    }
}
