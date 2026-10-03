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
import {Roles} from "../../src/libraries/Roles.sol";

contract RecoverPolygonGovernanceTimelock is Script {
    error RecoverPolygonGovernanceTimelock__WrongChain();
    error RecoverPolygonGovernanceTimelock__UnexpectedDefaultAdmin(address target, address actual);
    error RecoverPolygonGovernanceTimelock__VerificationFailed();

    uint256 internal constant POLYGON_CHAIN_ID = 137;
    uint256 internal constant MIN_DELAY = 3 days;
    address internal constant ADMIN_SAFE = 0x377a77807085675Bc8350a47eEE2F1DF457abFd7;
    address internal constant TIMELOCK = 0x06411fd2Bb6f0b9AeA49054B3b01bEE5a234dCFb;

    function run() external returns (TimelockController timelock) {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        return recoverWithConfig(config, msg.sender);
    }

    function recoverWithConfig(HelperConfig.NetworkConfig memory config, address deployer)
        public
        returns (TimelockController timelock)
    {
        if (block.chainid != POLYGON_CHAIN_ID) revert RecoverPolygonGovernanceTimelock__WrongChain();
        timelock = TimelockController(payable(TIMELOCK));

        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);
        address[] memory adminTargets = new address[](3);
        adminTargets[0] = address(vault);
        adminTargets[1] = vault.getAdapterRegistry();
        adminTargets[2] = config.deployed.workflowRouter;

        vm.startBroadcast(deployer);
        for (uint256 i; i < adminTargets.length; ++i) {
            IAccessControlDefaultAdminRules access = IAccessControlDefaultAdminRules(adminTargets[i]);
            address currentAdmin = access.defaultAdmin();
            if (currentAdmin != deployer) {
                revert RecoverPolygonGovernanceTimelock__UnexpectedDefaultAdmin(adminTargets[i], currentAdmin);
            }
            (address pendingAdmin,) = access.pendingDefaultAdmin();
            if (pendingAdmin != TIMELOCK) access.beginDefaultAdminTransfer(TIMELOCK);
        }

        IAccessControl vaultAccess = IAccessControl(address(vault));
        if (!vaultAccess.hasRole(Roles.UPGRADER_ROLE, TIMELOCK)) {
            vaultAccess.grantRole(Roles.UPGRADER_ROLE, TIMELOCK);
        }
        if (vaultAccess.hasRole(Roles.UPGRADER_ROLE, config.roles.upgrader)) {
            vaultAccess.revokeRole(Roles.UPGRADER_ROLE, config.roles.upgrader);
        }
        vm.stopBroadcast();

        if (
            timelock.getMinDelay() != MIN_DELAY || !timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), TIMELOCK)
                || !timelock.hasRole(timelock.PROPOSER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.CANCELLER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.EXECUTOR_ROLE(), ADMIN_SAFE)
                || !vaultAccess.hasRole(Roles.UPGRADER_ROLE, TIMELOCK)
                || vaultAccess.hasRole(Roles.UPGRADER_ROLE, config.roles.upgrader)
        ) revert RecoverPolygonGovernanceTimelock__VerificationFailed();

        for (uint256 i; i < adminTargets.length; ++i) {
            (address pendingAdmin,) = IAccessControlDefaultAdminRules(adminTargets[i]).pendingDefaultAdmin();
            if (pendingAdmin != TIMELOCK) revert RecoverPolygonGovernanceTimelock__VerificationFailed();
        }
    }
}
