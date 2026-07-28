// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract GrantConfigOperator is Script {
    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();

        vm.broadcast(msg.sender);
        IAccessControl(config.deployed.vaultProxy).grantRole(Roles.CONFIG_OPERATOR_ROLE, msg.sender);
    }
}
