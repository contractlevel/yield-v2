// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {MockAToken} from "./MockAToken.sol";

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

contract MockAaveV3Pool {
    address internal immutable i_asset;
    address internal immutable i_aToken;

    constructor(address asset, address aToken) {
        i_asset = asset;
        i_aToken = aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        MockAToken(i_aToken).mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256 amountOut) {
        uint256 tvl = MockAToken(i_aToken).balanceOf(msg.sender);
        amountOut = amount == type(uint256).max ? tvl : amount;

        require(amountOut <= tvl);

        MockAToken(i_aToken).burn(msg.sender, amountOut);
        IMintableERC20(i_asset).mint(to, amountOut);
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory data) {
        require(asset == i_asset);
        data.aTokenAddress = i_aToken;
    }
}
