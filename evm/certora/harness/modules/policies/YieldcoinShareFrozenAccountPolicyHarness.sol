// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";
import {
    YieldcoinShareFrozenAccountPolicy
} from "../../../../src/modules/policies/YieldcoinShareFrozenAccountPolicy.sol";

contract YieldcoinShareFrozenAccountPolicyHarness is YieldcoinShareFrozenAccountPolicy, HelperHarness {
    constructor(address share) YieldcoinShareFrozenAccountPolicy(share) {}

    function oneAccountParameters(address account) external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = abi.encode(account);
    }

    function truncatedAccountParameters() external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = new bytes(31);
    }

    function dirtyAddressParameters() external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = abi.encode(type(uint256).max);
    }
}
