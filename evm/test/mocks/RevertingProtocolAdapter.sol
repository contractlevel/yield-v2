// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "../../src/interfaces/adapters/IProtocolAdapter.sol";

contract RevertingProtocolAdapter is IProtocolAdapter {
    address internal immutable i_vault;
    address internal immutable i_asset;

    constructor(address vault, address asset) {
        i_vault = vault;
        i_asset = asset;
    }

    function deposit(uint256) external pure {
        revert("RevertingProtocolAdapter: deposit");
    }

    function withdraw(uint256) external pure returns (uint256) {
        revert("RevertingProtocolAdapter: withdraw");
    }

    function getTVL() external pure returns (uint256 tvl) {
        return 0;
    }

    function getProtocolPool() external pure returns (address pool) {
        return address(0);
    }

    function getVault() external view returns (address vault) {
        return i_vault;
    }

    function getAsset() external view returns (address asset) {
        return i_asset;
    }

    function getBufferedAssets() external pure returns (uint256 bufferedAssets) {
        return 0;
    }
}
