// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {MockAToken} from "./MockAToken.sol";

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

contract MockAaveV3Pool {
    address internal immutable i_asset;
    address internal immutable i_aToken;

    bool public s_decreaseTVLOnSupply;
    uint256 public s_supplyTVLChange;
    uint256 public s_withdrawAmount;

    constructor(address asset, address aToken) {
        i_asset = asset;
        i_aToken = aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        if (s_decreaseTVLOnSupply) MockAToken(i_aToken).burn(onBehalfOf, s_supplyTVLChange);
        else MockAToken(i_aToken).mint(onBehalfOf, s_supplyTVLChange);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256 amountOut) {
        uint256 tvl = MockAToken(i_aToken).balanceOf(msg.sender);
        uint256 tvlChange = amount == type(uint256).max ? tvl : amount;
        amountOut = s_withdrawAmount;

        require(tvlChange <= tvl);

        MockAToken(i_aToken).burn(msg.sender, tvlChange);
        IMintableERC20(i_asset).mint(to, amountOut);
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory data) {
        require(asset == i_asset);
        data.aTokenAddress = i_aToken;
    }
}
