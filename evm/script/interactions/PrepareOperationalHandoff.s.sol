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

contract PrepareOperationalHandoff is Script {
    error PrepareOperationalHandoff__UnsupportedChain(uint256 chainId);
    error PrepareOperationalHandoff__SenderIsNotDefaultAdmin(address actualDefaultAdmin, address sender);
    error PrepareOperationalHandoff__RoleNotRevoked(address target, bytes32 role);
    error PrepareOperationalHandoff__DeployerStillAllowlisted();

    uint256 internal constant BASE_CHAIN_ID = 8453;

    function run() external {
        if (!_isSupportedMainnet(block.chainid)) {
            revert PrepareOperationalHandoff__UnsupportedChain(block.chainid);
        }

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        address vault = config.deployed.vaultProxy;
        address router = config.deployed.workflowRouter;

        address defaultAdmin = IAccessControlDefaultAdminRules(vault).defaultAdmin();
        if (defaultAdmin != msg.sender) {
            revert PrepareOperationalHandoff__SenderIsNotDefaultAdmin(defaultAdmin, msg.sender);
        }

        vm.startBroadcast(msg.sender);
        if (block.chainid == BASE_CHAIN_ID) _removeDeployerFromAllowlist(vault);
        _revokeIfGranted(vault, Roles.CONFIG_OPERATOR_ROLE, msg.sender);
        _revokeIfGranted(router, Roles.CONFIG_OPERATOR_ROLE, msg.sender);
        vm.stopBroadcast();

        _requireRoleRevoked(vault, Roles.CONFIG_OPERATOR_ROLE, msg.sender);
        _requireRoleRevoked(router, Roles.CONFIG_OPERATOR_ROLE, msg.sender);
        if (block.chainid == BASE_CHAIN_ID) {
            _requireRoleRevoked(vault, Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);
            if (IAllowlist(vault).getAllowlistedUser(msg.sender)) {
                revert PrepareOperationalHandoff__DeployerStillAllowlisted();
            }
        }
    }

    function _removeDeployerFromAllowlist(address vault) private {
        IAccessControl access = IAccessControl(vault);
        bool temporaryRole = !access.hasRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);
        if (temporaryRole) access.grantRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);

        address[] memory users = new address[](1);
        users[0] = msg.sender;
        IAllowlist(vault).setAllowlistedUsers(users, false);

        if (temporaryRole) access.revokeRole(Roles.ALLOWLIST_OPERATOR_ROLE, msg.sender);
    }

    function _revokeIfGranted(address target, bytes32 role, address account) private {
        IAccessControl access = IAccessControl(target);
        if (access.hasRole(role, account)) access.revokeRole(role, account);
    }

    function _requireRoleRevoked(address target, bytes32 role, address account) private view {
        if (IAccessControl(target).hasRole(role, account)) {
            revert PrepareOperationalHandoff__RoleNotRevoked(target, role);
        }
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}
