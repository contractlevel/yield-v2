// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IAllowlist} from "../../src/interfaces/modules/IAllowlist.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract AllowlistUser is Script {
    error AllowlistUser__UnsupportedChain(uint256 chainId);
    error AllowlistUser__InvalidUser();
    error AllowlistUser__SenderIsNotDefaultAdmin(address actualDefaultAdmin, address sender);

    uint256 internal constant BASE_CHAIN_ID = 8453;

    function run() external {
        if (block.chainid != BASE_CHAIN_ID) revert AllowlistUser__UnsupportedChain(block.chainid);

        address user = vm.envAddress("ALLOWLIST_USER");
        if (user == address(0)) revert AllowlistUser__InvalidUser();

        address vault = new HelperConfig().getActiveNetworkConfig().deployed.vaultProxy;
        IAccessControl access = IAccessControl(vault);
        address defaultAdmin = IAccessControlDefaultAdminRules(vault).defaultAdmin();
        if (defaultAdmin != msg.sender) {
            revert AllowlistUser__SenderIsNotDefaultAdmin(defaultAdmin, msg.sender);
        }
        bool needsRole = !access.hasRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);

        address[] memory users = new address[](1);
        users[0] = user;

        vm.startBroadcast(msg.sender);
        if (needsRole) access.grantRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);
        IAllowlist(vault).setAllowlistedUsers(users, true);
        access.revokeRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);
        vm.stopBroadcast();
    }
}
