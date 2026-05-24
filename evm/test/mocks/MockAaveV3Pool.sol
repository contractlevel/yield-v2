// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {MockAToken} from "./MockAToken.sol";

contract MockAaveV3Pool {
    error MockAaveV3Pool__SupplyReverts();
    error MockAaveV3Pool__WithdrawReverts();
    error MockAaveV3Pool__UnexpectedWithdrawAmount(uint256 actual, uint256 expected);

    address internal s_aTokenAddress;
    uint256 internal s_withdrawReturn;
    uint256 internal s_expectedWithdrawAmount;
    bool internal s_supplyReverts;
    bool internal s_withdrawReverts;
    bool internal s_useExpectedWithdrawAmount;
    bool internal s_updatesATokenBalance;

    function setATokenAddress(address aTokenAddress) external {
        s_aTokenAddress = aTokenAddress;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
        s_useExpectedWithdrawAmount = false;
    }

    function setExpectedWithdrawAmount(uint256 amount) external {
        s_expectedWithdrawAmount = amount;
        s_useExpectedWithdrawAmount = true;
    }

    function setSupplyReverts(bool supplyReverts) external {
        s_supplyReverts = supplyReverts;
    }

    function setWithdrawReverts(bool withdrawReverts) external {
        s_withdrawReverts = withdrawReverts;
    }

    function setUpdatesATokenBalance(bool updatesATokenBalance) external {
        s_updatesATokenBalance = updatesATokenBalance;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        if (s_supplyReverts) revert MockAaveV3Pool__SupplyReverts();
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (s_updatesATokenBalance) MockAToken(s_aTokenAddress).mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        if (s_withdrawReverts) revert MockAaveV3Pool__WithdrawReverts();
        if (s_useExpectedWithdrawAmount) {
            if (amount != s_expectedWithdrawAmount) {
                revert MockAaveV3Pool__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }
            if (s_updatesATokenBalance) MockAToken(s_aTokenAddress).burn(msg.sender, amount);
            IERC20(asset).transfer(to, amount);
            return amount;
        }

        uint256 returnAmount = s_withdrawReturn;
        IERC20(asset).transfer(to, returnAmount);
        return returnAmount;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveDataLegacy memory data) {
        data.aTokenAddress = s_aTokenAddress;
    }
}
