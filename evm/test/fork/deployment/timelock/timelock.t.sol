// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {DeployGovernanceTimelock} from "../../../../script/interactions/DeployGovernanceTimelock.s.sol";
import {RecoverPolygonGovernanceTimelock} from "../../../../script/interactions/RecoverPolygonGovernanceTimelock.s.sol";
import {
    ExecuteDefaultAdminAcceptance,
    ScheduleDefaultAdminAcceptance
} from "../../../../script/interactions/DefaultAdminTimelockOperations.s.sol";
import {HelperConfig} from "../../../../script/HelperConfig.s.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

contract GovernanceTimelock_DeploymentForkTest is Test {
    uint256 internal constant MIN_DELAY = 3 days;
    uint256 internal constant BASE_CHAIN_ID = 8453;

    address internal constant ADMIN_SAFE = 0x377a77807085675Bc8350a47eEE2F1DF457abFd7;
    address internal constant CANCELLER = 0x56F48C7Edfca223D050E9AEfC6975C4c7d308416;
    address internal constant DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;

    function test_Arbitrum_DeploysGovernanceTimelock() external {
        _assertDeployment("ARBITRUM_MAINNET_RPC_URL", 508_107_759);
    }

    function test_Ethereum_DeploysGovernanceTimelock() external {
        _assertDeployment("ETHEREUM_MAINNET_RPC_URL", 26_039_913);
    }

    function test_Base_DeploysGovernanceTimelock() external {
        _assertDeployment("BASE_MAINNET_RPC_URL", 51_686_959);
    }

    function test_Optimism_DeploysGovernanceTimelock() external {
        _assertDeployment("OPTIMISM_MAINNET_RPC_URL", 157_282_245);
    }

    function test_Avalanche_DeploysGovernanceTimelock() external {
        _assertDeployment("AVALANCHE_MAINNET_RPC_URL", 95_977_065);
    }

    function test_Polygon_DeploysGovernanceTimelock() external {
        _assertDeployment("POLYGON_MAINNET_RPC_URL", 94_305_441);
    }

    function test_Polygon_RecoversPartiallyConfiguredGovernanceTimelock() external {
        vm.createSelectFork(vm.envString("POLYGON_MAINNET_RPC_URL"), 94_370_648);
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        TimelockController timelock = new RecoverPolygonGovernanceTimelock().recoverWithConfig(config, DEPLOYER);

        address[] memory adminTargets = _adminTargets(config);
        for (uint256 i; i < adminTargets.length; ++i) {
            (address pendingAdmin,) = IAccessControlDefaultAdminRules(adminTargets[i]).pendingDefaultAdmin();
            assertEq(pendingAdmin, address(timelock));
        }
        assertTrue(IAccessControl(config.deployed.vaultProxy).hasRole(Roles.UPGRADER_ROLE, address(timelock)));
        assertFalse(IAccessControl(config.deployed.vaultProxy).hasRole(Roles.UPGRADER_ROLE, config.roles.upgrader));
    }

    function _assertDeployment(string memory rpcEnv, uint256 blockNumber) private {
        vm.createSelectFork(vm.envString(rpcEnv), blockNumber);
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        DeployGovernanceTimelock deployer = new DeployGovernanceTimelock();

        TimelockController timelock = deployer.deployWithConfig(config, DEPLOYER);

        assertEq(timelock.getMinDelay(), MIN_DELAY);
        assertTrue(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(timelock)));
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), ADMIN_SAFE));
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), ADMIN_SAFE));
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), ADMIN_SAFE));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), ADMIN_SAFE));
        assertFalse(timelock.hasRole(timelock.CANCELLER_ROLE(), CANCELLER));

        address[] memory adminTargets = _adminTargets(config);
        for (uint256 i; i < adminTargets.length; ++i) {
            IAccessControlDefaultAdminRules access = IAccessControlDefaultAdminRules(adminTargets[i]);
            (address pendingAdmin,) = access.pendingDefaultAdmin();
            assertEq(access.defaultAdmin(), DEPLOYER);
            assertEq(pendingAdmin, address(timelock));
        }

        address[] memory upgradeTargets = _upgradeTargets(config);
        for (uint256 i; i < upgradeTargets.length; ++i) {
            IAccessControl access = IAccessControl(upgradeTargets[i]);
            assertTrue(access.hasRole(Roles.UPGRADER_ROLE, address(timelock)));
            assertFalse(access.hasRole(Roles.UPGRADER_ROLE, config.roles.upgrader));
        }

        _assertDefaultAdminAcceptance(timelock, config, adminTargets);
    }

    function _assertDefaultAdminAcceptance(
        TimelockController timelock,
        HelperConfig.NetworkConfig memory config,
        address[] memory adminTargets
    ) private {
        (address scheduleTarget, bytes memory scheduleData) =
            new ScheduleDefaultAdminAcceptance().build(address(timelock), config);
        vm.prank(ADMIN_SAFE);
        (bool scheduled,) = scheduleTarget.call(scheduleData);
        assertTrue(scheduled);

        (address executeTarget, bytes memory executeData) =
            new ExecuteDefaultAdminAcceptance().build(address(timelock), config);
        vm.prank(ADMIN_SAFE);
        (bool executedEarly,) = executeTarget.call(executeData);
        assertFalse(executedEarly);

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(ADMIN_SAFE);
        (bool executed,) = executeTarget.call(executeData);
        assertTrue(executed);
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), CANCELLER));

        for (uint256 i; i < adminTargets.length; ++i) {
            IAccessControlDefaultAdminRules access = IAccessControlDefaultAdminRules(adminTargets[i]);
            (address pendingAdmin,) = access.pendingDefaultAdmin();
            assertEq(access.defaultAdmin(), address(timelock));
            assertEq(pendingAdmin, address(0));
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
}
