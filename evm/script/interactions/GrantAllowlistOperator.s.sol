// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract GrantAllowlistOperator is Script {
    error GrantAllowlistOperator__UnsupportedChain(uint256 chainId);
    error GrantAllowlistOperator__RoleNotGranted();

    uint256 internal constant BASE_CHAIN_ID = 8453;
    address internal constant ALLOWLIST_OPERATOR = 0xB0E03148B64D6695B429FFC72Ad0209A132bF196;

    function run() external {
        if (block.chainid != BASE_CHAIN_ID) revert GrantAllowlistOperator__UnsupportedChain(block.chainid);

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        IAccessControl vault = IAccessControl(config.deployed.vaultProxy);

        if (!vault.hasRole(Roles.ALLOWLIST_OPERATOR_ROLE, ALLOWLIST_OPERATOR)) {
            vm.broadcast(msg.sender);
            vault.grantRole(Roles.ALLOWLIST_OPERATOR_ROLE, ALLOWLIST_OPERATOR);
        }

        if (!vault.hasRole(Roles.ALLOWLIST_OPERATOR_ROLE, ALLOWLIST_OPERATOR)) {
            revert GrantAllowlistOperator__RoleNotGranted();
        }
    }
}
