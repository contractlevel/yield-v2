// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {HelperConfig} from "../HelperConfig.s.sol";

contract FundVaultLink is Script {
    using SafeERC20 for IERC20;

    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();

        vm.broadcast(msg.sender);
        IERC20(config.tokens.link).safeTransfer(config.deployed.vaultProxy, 5 ether);
    }
}
