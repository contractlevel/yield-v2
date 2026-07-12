// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockProtocolAdapter is IProtocolAdapter {
    address internal immutable i_vault;
    address internal immutable i_asset;

    uint256 internal s_tvl;
    bool internal s_depositReverts;
    bool internal s_withdrawReverts;

    constructor(address vault, address asset) {
        i_vault = vault;
        i_asset = asset;
    }

    function setTVL(uint256 tvl) external {
        s_tvl = tvl;
    }

    function deposit(uint256 amount) external {
        if (s_depositReverts) revert("MockProtocolAdapter: deposit reverted");
        s_tvl += amount;
        emit Deposit(amount);
    }

    function withdraw(uint256 amount) external returns (uint256 amountOut) {
        if (s_withdrawReverts) revert("MockProtocolAdapter: withdraw reverted");
        amountOut = amount > s_tvl ? s_tvl : amount;
        s_tvl -= amountOut;
        IERC20(i_asset).transfer(i_vault, amountOut);
        emit Withdraw(amountOut);
    }

    function getTVL() external view returns (uint256 tvl) {
        tvl = s_tvl;
    }

    function getProtocolPool() external view returns (address pool) {
        pool = address(0);
    }

    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    function depositReverts() external view returns (bool depositReverts) {
        depositReverts = s_depositReverts;
    }

    function withdrawReverts() external view returns (bool withdrawReverts) {
        withdrawReverts = s_withdrawReverts;
    }
}
