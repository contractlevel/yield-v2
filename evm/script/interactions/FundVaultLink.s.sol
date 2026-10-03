// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {HelperConfig} from "../HelperConfig.s.sol";

contract FundVaultLink is Script {
    using SafeERC20 for IERC20;

    error FundVaultLink__ZeroBalance();
    error FundVaultLink__BalanceAboveMaximum(uint256 balance);

    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        IERC20 link = IERC20(config.tokens.link);
        uint256 balance = link.balanceOf(msg.sender);
        if (balance == 0) revert FundVaultLink__ZeroBalance();
        if (balance > 10 ether) revert FundVaultLink__BalanceAboveMaximum(balance);

        vm.broadcast(msg.sender);
        link.safeTransfer(config.deployed.vaultProxy, balance);
    }
}
