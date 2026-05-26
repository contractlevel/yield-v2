// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockComet {
    error MockComet__SupplyReverts();
    error MockComet__WithdrawReverts();
    error MockComet__UnexpectedWithdrawAmount(uint256 actual, uint256 expected);

    mapping(address account => uint256 balance) internal s_balances;
    uint256 internal s_withdrawReturn;
    uint256 internal s_expectedWithdrawAmount;
    bool internal s_supplyReverts;
    bool internal s_withdrawReverts;
    bool internal s_useExpectedWithdrawAmount;

    function setBalance(address account, uint256 amount) external {
        s_balances[account] = amount;
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

    function supply(address asset, uint256 amount) external {
        if (s_supplyReverts) revert MockComet__SupplyReverts();
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        s_balances[msg.sender] += amount;
    }

    function withdraw(address asset, uint256 amount) external {
        if (s_withdrawReverts) revert MockComet__WithdrawReverts();

        uint256 balance = s_balances[msg.sender];
        if (amount == type(uint256).max) {
            if (s_useExpectedWithdrawAmount && amount != s_expectedWithdrawAmount) {
                revert MockComet__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }

            s_balances[msg.sender] = 0;
            IERC20(asset).transfer(msg.sender, balance);
            return;
        }

        uint256 amountToTransfer = s_withdrawReturn;
        if (s_useExpectedWithdrawAmount) {
            if (amount != s_expectedWithdrawAmount) {
                revert MockComet__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }
            amountToTransfer = amount;
        }

        if (amountToTransfer >= balance) s_balances[msg.sender] = 0;
        else s_balances[msg.sender] = balance - amountToTransfer;

        IERC20(asset).transfer(msg.sender, amountToTransfer);
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        balance = s_balances[account];
    }
}
