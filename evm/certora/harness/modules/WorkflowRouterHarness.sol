// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";

import {WorkflowRouter} from "../../../src/modules/WorkflowRouter.sol";

contract WorkflowRouterHarness is WorkflowRouter, HelperHarness {
    constructor(WorkflowRouter.ConstructorParams memory params) WorkflowRouter(params) {}

    function buildMetadata(bytes32 workflowId, bytes10 workflowName, address workflowOwner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(workflowId, workflowName, workflowOwner);
    }

    function buildReport(bytes4 selector) external pure returns (bytes memory) {
        return abi.encodePacked(selector);
    }

    function buildShortReport(bytes3 report) external pure returns (bytes memory) {
        return abi.encodePacked(report);
    }

    function certoraVaultCallSucceedsSelector() external pure returns (bytes4) {
        return bytes4(keccak256("workflowRouterCallSucceeds()"));
    }
}
