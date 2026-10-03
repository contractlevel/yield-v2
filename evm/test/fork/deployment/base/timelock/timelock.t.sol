// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

import {Roles} from "../../../../../src/libraries/Roles.sol";

contract Base_TimelockForkTest is Test {
    uint256 internal constant BASE_FORK_BLOCK = 51_685_651;
    uint256 internal constant MIN_DELAY = 3 days;

    address internal constant ADMIN_SAFE = 0x377a77807085675Bc8350a47eEE2F1DF457abFd7;
    address internal constant DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;

    address internal constant PARENT_VAULT = 0x664EFe3859165011b811d8AFc127872520e97079;
    address internal constant SHARE = 0xab83Ba0bc3c4fEE04fE4aD5DF914f86F5F31c45d;
    address internal constant ADAPTER_REGISTRY = 0xf5A044C79d1cfD1128ea082AccE8DaEd9d631045;
    address internal constant WORKFLOW_ROUTER = 0xAAac2c5e99cBf3dBb8d9c1fe96F968ce9cC7518b;

    TimelockController internal timelock;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"), BASE_FORK_BLOCK);

        address[] memory proposers = new address[](1);
        proposers[0] = ADMIN_SAFE;
        address[] memory executors = new address[](1);
        executors[0] = ADMIN_SAFE;

        timelock = new TimelockController(MIN_DELAY, proposers, executors, address(0));
    }

    function test_Base_TimelockControlsDefaultAdminOperations() external {
        address[] memory targets = _baseContracts();

        vm.startPrank(DEPLOYER);
        for (uint256 i; i < targets.length; ++i) {
            IAccessControlDefaultAdminRules target = IAccessControlDefaultAdminRules(targets[i]);
            target.cancelDefaultAdminTransfer();
            target.beginDefaultAdminTransfer(address(timelock));
        }
        vm.stopPrank();

        uint256[] memory values = new uint256[](targets.length);
        bytes[] memory payloads = new bytes[](targets.length);
        for (uint256 i; i < targets.length; ++i) {
            payloads[i] = abi.encodeCall(IAccessControlDefaultAdminRules.acceptDefaultAdminTransfer, ());
        }

        bytes32 predecessor = bytes32(0);
        bytes32 acceptSalt = keccak256("accept-base-default-admin");
        vm.prank(ADMIN_SAFE);
        timelock.scheduleBatch(targets, values, payloads, predecessor, acceptSalt, MIN_DELAY);

        vm.prank(ADMIN_SAFE);
        vm.expectRevert();
        timelock.executeBatch(targets, values, payloads, predecessor, acceptSalt);

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(ADMIN_SAFE);
        timelock.executeBatch(targets, values, payloads, predecessor, acceptSalt);

        for (uint256 i; i < targets.length; ++i) {
            assertEq(IAccessControlDefaultAdminRules(targets[i]).defaultAdmin(), address(timelock));
        }

        address newOperator = makeAddr("newOperator");
        IAccessControlDefaultAdminRules router = IAccessControlDefaultAdminRules(WORKFLOW_ROUTER);

        vm.prank(ADMIN_SAFE);
        vm.expectRevert();
        router.grantRole(Roles.CONFIG_OPERATOR_ROLE, newOperator);

        bytes memory grantCall = abi.encodeCall(router.grantRole, (Roles.CONFIG_OPERATOR_ROLE, newOperator));
        bytes32 grantSalt = keccak256("grant-config-operator");
        vm.prank(ADMIN_SAFE);
        timelock.schedule(WORKFLOW_ROUTER, 0, grantCall, predecessor, grantSalt, MIN_DELAY);

        vm.warp(block.timestamp + MIN_DELAY);
        vm.prank(ADMIN_SAFE);
        timelock.execute(WORKFLOW_ROUTER, 0, grantCall, predecessor, grantSalt);

        assertTrue(router.hasRole(Roles.CONFIG_OPERATOR_ROLE, newOperator));
    }

    function _baseContracts() private pure returns (address[] memory targets) {
        targets = new address[](4);
        targets[0] = PARENT_VAULT;
        targets[1] = SHARE;
        targets[2] = ADAPTER_REGISTRY;
        targets[3] = WORKFLOW_ROUTER;
    }
}
