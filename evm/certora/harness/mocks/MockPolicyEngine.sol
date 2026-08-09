// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract MockPolicyEngine {
    uint256 public runCount;

    function run(IPolicyEngine.Payload calldata) external {
        ++runCount;
    }
    function attach() external {}
    function detach() external {}
}
