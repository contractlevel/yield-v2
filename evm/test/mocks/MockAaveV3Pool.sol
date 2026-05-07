// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";

contract MockAaveV3Pool {
    address internal s_aTokenAddress;
    uint256 internal s_withdrawReturn;

    function setATokenAddress(address aTokenAddress) external {
        s_aTokenAddress = aTokenAddress;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
    }

    function supply(address asset, uint256 amount, address, uint16) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256, address to) external returns (uint256) {
        uint256 amount = s_withdrawReturn;
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveDataLegacy memory data) {
        data.aTokenAddress = s_aTokenAddress;
    }
}
