// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IChildVault} from "../../src/interfaces/vaults/IChildVault.sol";
import {Roles} from "../../src/libraries/Roles.sol";
import {Types} from "../../src/libraries/Types.sol";

contract RetryFujiRebalance is Script {
    error RetryFujiRebalance__UnsupportedChain(uint256 chainId);
    error RetryFujiRebalance__SenderIsNotDefaultAdmin(address actualDefaultAdmin, address sender);
    error RetryFujiRebalance__UnexpectedLastHandledNonce(uint256 nonce);

    uint256 internal constant AVALANCHE_FUJI_CHAIN_ID = 43_113;
    uint256 internal constant REBALANCE_NONCE = 5;
    uint64 internal constant ETHEREUM_SEPOLIA_CHAIN_SELECTOR = 16_015_286_601_757_825_753;
    bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256("compound-v3");

    function run() external {
        if (block.chainid != AVALANCHE_FUJI_CHAIN_ID) {
            revert RetryFujiRebalance__UnsupportedChain(block.chainid);
        }

        address vaultAddress = new HelperConfig().getActiveNetworkConfig().deployed.vaultProxy;
        IChildVault vault = IChildVault(vaultAddress);
        IAccessControl access = IAccessControl(vaultAddress);
        address defaultAdmin = IAccessControlDefaultAdminRules(vaultAddress).defaultAdmin();
        if (defaultAdmin != msg.sender) {
            revert RetryFujiRebalance__SenderIsNotDefaultAdmin(defaultAdmin, msg.sender);
        }

        uint256 lastHandledNonce = vault.getLastHandledRebalanceNonce();
        if (lastHandledNonce != REBALANCE_NONCE - 1 && lastHandledNonce != REBALANCE_NONCE) {
            revert RetryFujiRebalance__UnexpectedLastHandledNonce(lastHandledNonce);
        }

        vm.startBroadcast(msg.sender);
        if (lastHandledNonce < REBALANCE_NONCE) {
            if (!access.hasRole(Roles.REBALANCE_OPERATOR_ROLE, msg.sender)) {
                access.grantRole(Roles.REBALANCE_OPERATOR_ROLE, msg.sender);
            }
            vault.executeRebalance(
                REBALANCE_NONCE,
                Types.Strategy({protocolId: COMPOUND_V3_PROTOCOL_ID, chainSelector: ETHEREUM_SEPOLIA_CHAIN_SELECTOR})
            );
        }
        if (access.hasRole(Roles.REBALANCE_OPERATOR_ROLE, msg.sender)) {
            access.revokeRole(Roles.REBALANCE_OPERATOR_ROLE, msg.sender);
        }
        vm.stopBroadcast();
    }
}
