// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DepositParent is Script {
    using SafeERC20 for IERC20;

    uint256 internal constant DEPOSIT_AMOUNT = 10e6;

    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();

        vm.startBroadcast(msg.sender);
        IERC20(config.tokens.usdc).forceApprove(config.deployed.vaultProxy, DEPOSIT_AMOUNT);
        IParentVault(config.deployed.vaultProxy).deposit(DEPOSIT_AMOUNT);
        vm.stopBroadcast();
    }
}
