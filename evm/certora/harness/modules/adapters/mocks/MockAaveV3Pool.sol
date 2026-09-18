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
    bool public s_supplyReverts;
    bool public s_withdrawReverts;
    bool public s_normalizedIncomeReverts;
    uint256 public s_supplyTVLChange;
    uint256 public s_withdrawAmount;
    uint256 public s_reserveNormalizedIncome;

    bool public s_supplyCalled;
    address public s_supplyCaller;
    address public s_supplyAsset;
    uint256 public s_supplyAmount;
    address public s_supplyOnBehalfOf;
    uint16 public s_supplyReferralCode;

    constructor(address asset, address aToken) {
        i_asset = asset;
        i_aToken = aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        require(!s_supplyReverts);
        s_supplyCalled = true;
        s_supplyCaller = msg.sender;
        s_supplyAsset = asset;
        s_supplyAmount = amount;
        s_supplyOnBehalfOf = onBehalfOf;
        s_supplyReferralCode = referralCode;
        if (s_decreaseTVLOnSupply) MockAToken(i_aToken).burn(onBehalfOf, s_supplyTVLChange);
        else MockAToken(i_aToken).mint(onBehalfOf, s_supplyTVLChange);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256 amountOut) {
        require(!s_withdrawReverts);
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

    function getReserveNormalizedIncome(address asset) external view returns (uint256) {
        require(asset == i_asset);
        require(!s_normalizedIncomeReverts);
        return s_reserveNormalizedIncome;
    }
}
