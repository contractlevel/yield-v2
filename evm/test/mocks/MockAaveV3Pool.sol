// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";

contract MockAaveV3Pool {
    error MockAaveV3Pool__SupplyReverts();
    error MockAaveV3Pool__WithdrawReverts();

    address internal s_aTokenAddress;
    uint256 internal s_withdrawReturn;
    bool internal s_supplyReverts;
    bool internal s_withdrawReverts;

    function setATokenAddress(address aTokenAddress) external {
        s_aTokenAddress = aTokenAddress;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
    }

    function setSupplyReverts(bool supplyReverts) external {
        s_supplyReverts = supplyReverts;
    }

    function setWithdrawReverts(bool withdrawReverts) external {
        s_withdrawReverts = withdrawReverts;
    }

    function supply(address asset, uint256 amount, address, uint16) external {
        if (s_supplyReverts) revert MockAaveV3Pool__SupplyReverts();
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256, address to) external returns (uint256) {
        if (s_withdrawReverts) revert MockAaveV3Pool__WithdrawReverts();
        uint256 amount = s_withdrawReturn;
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveDataLegacy memory data) {
        data.aTokenAddress = s_aTokenAddress;
    }
}
