// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IChildVault} from "../../src/interfaces/vaults/IChildVault.sol";

abstract contract ExecutingEpochRecovery is Script {
    error ExecutingEpochRecovery__WrongChain(uint256 chainId);
    error ExecutingEpochRecovery__WrongCaller(address caller);
    error ExecutingEpochRecovery__MissingRole();
    error ExecutingEpochRecovery__EpochAlreadyHandled(uint256 lastHandledEpochNonce);

    uint256 internal constant AVALANCHE_CHAIN_ID = 43114;
    uint256 internal constant EPOCH_NONCE = 4;
    uint256 internal constant WITHDRAW_AMOUNT = 2_005_491;
    address internal constant MAINNET_DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;

    bytes32 internal constant EPOCH_OPERATOR_ROLE = keccak256("EPOCH_OPERATOR_ROLE");
    bytes32 internal constant SALT = keccak256("YIELD_V2_RECOVER_EPOCH_4");

    function _config() internal returns (HelperConfig.NetworkConfig memory config) {
        if (block.chainid != AVALANCHE_CHAIN_ID) revert ExecutingEpochRecovery__WrongChain(block.chainid);
        config = new HelperConfig().getActiveNetworkConfig();
    }

    function _grantPayload() internal pure returns (bytes memory) {
        return abi.encodeCall(IAccessControl.grantRole, (EPOCH_OPERATOR_ROLE, MAINNET_DEPLOYER));
    }
}

contract ScheduleEpochOperatorGrant is ExecutingEpochRecovery {
    function run() external returns (address target, bytes memory data) {
        HelperConfig.NetworkConfig memory config = _config();
        return build(config.deployed.governanceTimelock, config.deployed.vaultProxy);
    }

    function build(address timelockAddress, address vault) public view returns (address target, bytes memory data) {
        TimelockController timelock = TimelockController(payable(timelockAddress));
        data = abi.encodeCall(timelock.schedule, (vault, 0, _grantPayload(), bytes32(0), SALT, timelock.getMinDelay()));
        return (address(timelock), data);
    }
}

contract ExecuteEpochOperatorGrant is ExecutingEpochRecovery {
    function run() external returns (address target, bytes memory data) {
        HelperConfig.NetworkConfig memory config = _config();
        return build(config.deployed.governanceTimelock, config.deployed.vaultProxy);
    }

    function build(address timelock, address vault) public pure returns (address target, bytes memory data) {
        target = timelock;
        data = abi.encodeCall(TimelockController.execute, (vault, 0, _grantPayload(), bytes32(0), SALT));
    }
}

contract ExecuteRecoveringEpochWithdraw is ExecutingEpochRecovery {
    function run() external {
        HelperConfig.NetworkConfig memory config = _config();
        IChildVault vault = IChildVault(config.deployed.vaultProxy);
        if (msg.sender != MAINNET_DEPLOYER) revert ExecutingEpochRecovery__WrongCaller(msg.sender);
        if (!IAccessControl(address(vault)).hasRole(EPOCH_OPERATOR_ROLE, msg.sender)) {
            revert ExecutingEpochRecovery__MissingRole();
        }

        uint256 lastHandledEpochNonce = vault.getLastHandledEpochNonce();
        if (lastHandledEpochNonce >= EPOCH_NONCE) {
            revert ExecutingEpochRecovery__EpochAlreadyHandled(lastHandledEpochNonce);
        }

        vm.startBroadcast(msg.sender);
        vault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
        vm.stopBroadcast();
    }
}

contract RenounceEpochOperator is ExecutingEpochRecovery {
    function run() external {
        HelperConfig.NetworkConfig memory config = _config();
        if (msg.sender != MAINNET_DEPLOYER) revert ExecutingEpochRecovery__WrongCaller(msg.sender);

        vm.startBroadcast(msg.sender);
        IAccessControl(config.deployed.vaultProxy).renounceRole(EPOCH_OPERATOR_ROLE, msg.sender);
        vm.stopBroadcast();
    }
}
