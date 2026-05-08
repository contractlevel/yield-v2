// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAaveV4Spoke {
    address internal immutable i_underlying;
    uint256 internal s_withdrawReturn;

    mapping(uint256 reserveId => mapping(address user => uint256 suppliedAssets)) internal s_suppliedAssets;

    constructor(address underlying) {
        i_underlying = underlying;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
    }

    function setUserSuppliedAssets(uint256 reserveId, address user, uint256 amount) external {
        s_suppliedAssets[reserveId][user] = amount;
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256) {
        IERC20(i_underlying).transferFrom(msg.sender, address(this), amount);
        s_suppliedAssets[reserveId][onBehalfOf] += amount;
        return (amount, amount);
    }

    function withdraw(uint256 reserveId, uint256, address onBehalfOf) external returns (uint256, uint256) {
        uint256 amount = s_withdrawReturn;
        uint256 suppliedAssets = s_suppliedAssets[reserveId][onBehalfOf];
        if (amount >= suppliedAssets) s_suppliedAssets[reserveId][onBehalfOf] = 0;
        else s_suppliedAssets[reserveId][onBehalfOf] = suppliedAssets - amount;

        IERC20(i_underlying).transfer(msg.sender, amount);
        return (amount, amount);
    }

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256) {
        return s_suppliedAssets[reserveId][user];
    }
}
