// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract DeployGovernanceTimelock is Script {
    error DeployGovernanceTimelock__UnsupportedChain(uint256 chainId);
    error DeployGovernanceTimelock__UnexpectedDefaultAdmin(address target, address actual, address expected);
    error DeployGovernanceTimelock__PendingAdminMismatch(address target);
    error DeployGovernanceTimelock__UpgraderRoleMismatch(address target);
    error DeployGovernanceTimelock__TimelockRoleMismatch();

    event GovernanceTimelockDeployed(uint256 indexed chainId, address indexed timelock);

    uint256 internal constant BASE_CHAIN_ID = 8453;
    uint256 internal constant MIN_DELAY = 3 days;
    address internal constant ADMIN_SAFE = 0x377a77807085675Bc8350a47eEE2F1DF457abFd7;

    function run() external returns (TimelockController timelock) {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        return deployWithConfig(config, msg.sender);
    }

    function deployWithConfig(HelperConfig.NetworkConfig memory config, address deployer)
        public
        returns (TimelockController timelock)
    {
        if (!_isSupportedMainnet(block.chainid)) {
            revert DeployGovernanceTimelock__UnsupportedChain(block.chainid);
        }

        address[] memory proposers = new address[](1);
        proposers[0] = ADMIN_SAFE;
        address[] memory executors = new address[](1);
        executors[0] = ADMIN_SAFE;

        vm.startBroadcast(deployer);
        timelock = new TimelockController(MIN_DELAY, proposers, executors, address(0));

        address[] memory adminTargets = _adminTargets(config);
        for (uint256 i; i < adminTargets.length; ++i) {
            _setPendingAdmin(adminTargets[i], address(timelock), deployer);
        }

        address[] memory upgradeTargets = _upgradeTargets(config);
        for (uint256 i; i < upgradeTargets.length; ++i) {
            _transferUpgraderRole(upgradeTargets[i], config.roles.upgrader, address(timelock));
        }
        vm.stopBroadcast();

        _verifyTimelockRoles(timelock);
        _verifyTargets(adminTargets, upgradeTargets, config.roles.upgrader, address(timelock));
        emit GovernanceTimelockDeployed(block.chainid, address(timelock));
    }

    function _setPendingAdmin(address target, address timelock, address deployer) private {
        IAccessControlDefaultAdminRules access = IAccessControlDefaultAdminRules(target);
        address currentAdmin = access.defaultAdmin();
        if (currentAdmin != deployer) {
            revert DeployGovernanceTimelock__UnexpectedDefaultAdmin(target, currentAdmin, deployer);
        }

        (address pendingAdmin,) = access.pendingDefaultAdmin();
        if (pendingAdmin == timelock) return;
        if (pendingAdmin != address(0)) access.cancelDefaultAdminTransfer();
        access.beginDefaultAdminTransfer(timelock);
    }

    function _transferUpgraderRole(address target, address currentUpgrader, address timelock) private {
        IAccessControl access = IAccessControl(target);
        if (!access.hasRole(Roles.UPGRADER_ROLE, timelock)) {
            access.grantRole(Roles.UPGRADER_ROLE, timelock);
        }
        if (currentUpgrader != timelock && access.hasRole(Roles.UPGRADER_ROLE, currentUpgrader)) {
            access.revokeRole(Roles.UPGRADER_ROLE, currentUpgrader);
        }
    }

    function _verifyTimelockRoles(TimelockController timelock) private view {
        if (
            timelock.getMinDelay() != MIN_DELAY || !timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(timelock))
                || timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.PROPOSER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.CANCELLER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.EXECUTOR_ROLE(), ADMIN_SAFE)
        ) revert DeployGovernanceTimelock__TimelockRoleMismatch();
    }

    function _verifyTargets(
        address[] memory adminTargets,
        address[] memory upgradeTargets,
        address currentUpgrader,
        address timelock
    ) private view {
        for (uint256 i; i < adminTargets.length; ++i) {
            (address pendingAdmin,) = IAccessControlDefaultAdminRules(adminTargets[i]).pendingDefaultAdmin();
            if (pendingAdmin != timelock) {
                revert DeployGovernanceTimelock__PendingAdminMismatch(adminTargets[i]);
            }
        }

        for (uint256 i; i < upgradeTargets.length; ++i) {
            IAccessControl access = IAccessControl(upgradeTargets[i]);
            if (!access.hasRole(Roles.UPGRADER_ROLE, timelock) || access.hasRole(Roles.UPGRADER_ROLE, currentUpgrader))
            {
                revert DeployGovernanceTimelock__UpgraderRoleMismatch(upgradeTargets[i]);
            }
        }
    }

    function _adminTargets(HelperConfig.NetworkConfig memory config) private view returns (address[] memory targets) {
        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);
        bool isBase = block.chainid == BASE_CHAIN_ID;
        targets = new address[](isBase ? 4 : 3);
        targets[0] = address(vault);
        targets[1] = vault.getAdapterRegistry();
        targets[2] = config.deployed.workflowRouter;
        if (isBase) targets[3] = IParentVault(address(vault)).getShare();
    }

    function _upgradeTargets(HelperConfig.NetworkConfig memory config) private view returns (address[] memory targets) {
        bool isBase = block.chainid == BASE_CHAIN_ID;
        targets = new address[](isBase ? 2 : 1);
        targets[0] = config.deployed.vaultProxy;
        if (isBase) targets[1] = IParentVault(config.deployed.vaultProxy).getShare();
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}
