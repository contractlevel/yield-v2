// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";

contract BeginDefaultAdminTransfers is Script {
    error BeginDefaultAdminTransfers__UnsupportedChain(uint256 chainId);
    error BeginDefaultAdminTransfers__InvalidNewAdmin();
    error BeginDefaultAdminTransfers__UnexpectedDefaultAdmin(
        address target, address actualDefaultAdmin, address expectedDefaultAdmin
    );

    uint256 internal constant BASE_CHAIN_ID = 8453;

    function run() external {
        if (!_isSupportedMainnet(block.chainid)) {
            revert BeginDefaultAdminTransfers__UnsupportedChain(block.chainid);
        }

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        address newAdmin = config.roles.defaultAdmin;
        if (newAdmin == address(0) || newAdmin == msg.sender) {
            revert BeginDefaultAdminTransfers__InvalidNewAdmin();
        }

        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);

        vm.startBroadcast(msg.sender);
        _beginTransfer(config.deployed.vaultProxy, newAdmin);
        _beginTransfer(vault.getAdapterRegistry(), newAdmin);
        _beginTransfer(config.deployed.workflowRouter, newAdmin);
        if (block.chainid == BASE_CHAIN_ID) {
            _beginTransfer(IParentVault(config.deployed.vaultProxy).getShare(), newAdmin);
        }
        vm.stopBroadcast();
    }

    function _beginTransfer(address target, address newAdmin) internal {
        IAccessControlDefaultAdminRules access = IAccessControlDefaultAdminRules(target);
        address currentAdmin = access.defaultAdmin();
        if (currentAdmin == newAdmin) return;
        if (currentAdmin != msg.sender) {
            revert BeginDefaultAdminTransfers__UnexpectedDefaultAdmin(target, currentAdmin, msg.sender);
        }

        (address pendingAdmin,) = access.pendingDefaultAdmin();
        if (pendingAdmin == newAdmin) return;
        access.beginDefaultAdminTransfer(newAdmin);
    }

    function _isSupportedMainnet(uint256 chainId) internal pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}
