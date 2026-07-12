// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IAaveV4Spoke} from "../../../../../src/interfaces/external/IAaveV4Spoke.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAaveV4Spoke is IAaveV4Spoke {
    address internal immutable i_underlying;

    mapping(uint256 reserveId => mapping(address user => uint256 suppliedAssets)) internal s_suppliedAssets;

    constructor(address underlying) {
        i_underlying = underlying;
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        returns (uint256 suppliedShares, uint256 suppliedAmount)
    {
        IERC20(i_underlying).transferFrom(msg.sender, address(this), amount);
        s_suppliedAssets[reserveId][onBehalfOf] += amount;

        return (amount, amount);
    }

    function withdraw(uint256 reserveId, uint256 amount, address to)
        external
        returns (uint256 withdrawnShares, uint256 withdrawnAmount)
    {
        uint256 suppliedAssets = s_suppliedAssets[reserveId][msg.sender];
        withdrawnAmount = amount == type(uint256).max ? suppliedAssets : amount;

        require(withdrawnAmount <= suppliedAssets);

        s_suppliedAssets[reserveId][msg.sender] = suppliedAssets - withdrawnAmount;
        IERC20(i_underlying).transfer(to, withdrawnAmount);

        return (withdrawnAmount, withdrawnAmount);
    }

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256 suppliedAssets) {
        suppliedAssets = s_suppliedAssets[reserveId][user];
    }

    function getReserveCount() external pure returns (uint256 reserveCount) {
        reserveCount = 1;
    }

    function getReserve(uint256) external view returns (Reserve memory reserve) {
        reserve.underlying = i_underlying;
        reserve.decimals = 6;
    }
}
