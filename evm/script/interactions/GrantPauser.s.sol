// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract GrantPauser is Script {
    error GrantPauser__UnsupportedChain(uint256 chainId);
    error GrantPauser__RoleNotGranted(address target, address pauser);

    address internal constant PAUSER_ONE = 0x418feeaC792ABc3FB7f7A5a6a74c68C7C39e7C37;
    address internal constant PAUSER_TWO = 0xfdC521A45b9036bd4b18DcE54De58C840C67fb0e;

    function run() external {
        if (!_isSupportedMainnet(block.chainid)) revert GrantPauser__UnsupportedChain(block.chainid);

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        address[2] memory targets = [config.deployed.vaultProxy, config.deployed.workflowRouter];
        address[2] memory pausers = [PAUSER_ONE, PAUSER_TWO];

        vm.startBroadcast(msg.sender);
        for (uint256 i; i < targets.length; ++i) {
            IAccessControl access = IAccessControl(targets[i]);
            for (uint256 j; j < pausers.length; ++j) {
                if (!access.hasRole(Roles.PAUSER_ROLE, pausers[j])) access.grantRole(Roles.PAUSER_ROLE, pausers[j]);
            }
        }
        vm.stopBroadcast();

        for (uint256 i; i < targets.length; ++i) {
            for (uint256 j; j < pausers.length; ++j) {
                if (!IAccessControl(targets[i]).hasRole(Roles.PAUSER_ROLE, pausers[j])) {
                    revert GrantPauser__RoleNotGranted(targets[i], pausers[j]);
                }
            }
        }
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}
