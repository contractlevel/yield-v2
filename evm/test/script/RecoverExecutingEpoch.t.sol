// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {
    ExecuteEpochOperatorGrant,
    ScheduleEpochOperatorGrant
} from "../../script/interactions/RecoverExecutingEpoch.s.sol";

contract RecoveryVault is AccessControl {
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}

contract RecoverExecutingEpochTest is Test {
    uint256 private constant DELAY = 3 days;
    bytes32 private constant EPOCH_OPERATOR_ROLE = keccak256("EPOCH_OPERATOR_ROLE");
    address private constant MAINNET_DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;

    TimelockController private timelock;
    RecoveryVault private vault;

    function setUp() public {
        address[] memory proposers = new address[](1);
        proposers[0] = address(this);
        address[] memory executors = new address[](1);
        executors[0] = address(this);
        timelock = new TimelockController(DELAY, proposers, executors, address(0));
        vault = new RecoveryVault(address(this));
        vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), address(timelock));
        vault.renounceRole(vault.DEFAULT_ADMIN_ROLE(), address(this));
    }

    function test_ScheduleAndExecuteGrant_Match() public {
        ScheduleEpochOperatorGrant scheduler = new ScheduleEpochOperatorGrant();
        ExecuteEpochOperatorGrant executor = new ExecuteEpochOperatorGrant();

        (address scheduleTarget, bytes memory scheduleData) = scheduler.build(address(timelock), address(vault));
        (address executeTarget, bytes memory executeData) = executor.build(address(timelock), address(vault));

        assertEq(scheduleTarget, address(timelock));
        assertEq(executeTarget, address(timelock));
        (bool scheduled,) = scheduleTarget.call(scheduleData);
        assertTrue(scheduled);

        vm.warp(block.timestamp + DELAY);
        (bool executed,) = executeTarget.call(executeData);
        assertTrue(executed);
        assertTrue(vault.hasRole(EPOCH_OPERATOR_ROLE, MAINNET_DEPLOYER));
    }
}
