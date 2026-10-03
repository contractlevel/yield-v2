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

abstract contract DefaultAdminTimelockOperation is Script {
    error DefaultAdminTimelockOperation__TimelockNotConfigured();

    uint256 internal constant BASE_CHAIN_ID = 8453;
    bytes32 internal constant SALT = keccak256("YIELD_V2_ACCEPT_DEFAULT_ADMIN_TRANSFERS");
    bytes32 internal constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    address internal constant INDEPENDENT_CANCELLER = 0x56F48C7Edfca223D050E9AEfC6975C4c7d308416;

    function _operation(address timelock, HelperConfig.NetworkConfig memory config)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory payloads)
    {
        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);
        bool isBase = block.chainid == BASE_CHAIN_ID;
        targets = new address[](isBase ? 5 : 4);
        targets[0] = address(vault);
        targets[1] = vault.getAdapterRegistry();
        targets[2] = config.deployed.workflowRouter;
        if (isBase) targets[3] = IParentVault(address(vault)).getShare();

        uint256 cancellerIndex = targets.length - 1;
        targets[cancellerIndex] = timelock;

        values = new uint256[](targets.length);
        payloads = new bytes[](targets.length);
        for (uint256 i; i < cancellerIndex; ++i) {
            payloads[i] = abi.encodeCall(IAccessControlDefaultAdminRules.acceptDefaultAdminTransfer, ());
        }
        payloads[cancellerIndex] = abi.encodeCall(IAccessControl.grantRole, (CANCELLER_ROLE, INDEPENDENT_CANCELLER));
    }

    function _timelockAddress(HelperConfig.NetworkConfig memory config) internal pure returns (address timelock) {
        timelock = config.deployed.governanceTimelock;
        if (timelock == address(0)) revert DefaultAdminTimelockOperation__TimelockNotConfigured();
    }
}

contract ScheduleDefaultAdminAcceptance is DefaultAdminTimelockOperation {
    function run() external returns (address target, bytes memory data) {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        return build(_timelockAddress(config), config);
    }

    function build(address timelockAddress, HelperConfig.NetworkConfig memory config)
        public
        view
        returns (address target, bytes memory data)
    {
        TimelockController timelock = TimelockController(payable(timelockAddress));
        (address[] memory targets, uint256[] memory values, bytes[] memory payloads) =
            _operation(timelockAddress, config);
        data = abi.encodeCall(
            timelock.scheduleBatch, (targets, values, payloads, bytes32(0), SALT, timelock.getMinDelay())
        );
        return (timelockAddress, data);
    }
}

contract ExecuteDefaultAdminAcceptance is DefaultAdminTimelockOperation {
    function run() external returns (address target, bytes memory data) {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        return build(_timelockAddress(config), config);
    }

    function build(address timelockAddress, HelperConfig.NetworkConfig memory config)
        public
        view
        returns (address target, bytes memory data)
    {
        (address[] memory targets, uint256[] memory values, bytes[] memory payloads) =
            _operation(timelockAddress, config);
        data = abi.encodeCall(TimelockController.executeBatch, (targets, values, payloads, bytes32(0), SALT));
        return (timelockAddress, data);
    }
}
