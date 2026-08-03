// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";

import {WorkflowRouter} from "../../../src/modules/WorkflowRouter.sol";
import {IReceiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";

contract WorkflowRouterHarness is WorkflowRouter, HelperHarness {
    constructor(WorkflowRouter.ConstructorParams memory params) WorkflowRouter(params) {}

    function buildMetadata(bytes32 workflowId, bytes10 workflowName, address workflowOwner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(workflowId, workflowName, workflowOwner, bytes2(0));
    }

    function buildShortMetadata(bytes32 workflowId, bytes10 workflowName, address workflowOwner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(workflowId, workflowName, workflowOwner, bytes1(0));
    }

    function buildLongMetadata(bytes32 workflowId, bytes10 workflowName, address workflowOwner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(workflowId, workflowName, workflowOwner, bytes3(0));
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

    function getWorkflowSelectorAtGeneration(bytes32 workflowId, uint256 generation, bytes4 selector)
        external
        view
        returns (bool isAllowlisted)
    {
        isAllowlisted = s_workflowSelectors[workflowId][generation][selector];
    }

    function getWorkflowSelectorAtNextGeneration(bytes32 workflowId, bytes4 selector)
        external
        view
        returns (bool isAllowlisted)
    {
        isAllowlisted = s_workflowSelectors[workflowId][s_workflowGenerations[workflowId] + 1][selector];
    }

    function receiverInterfaceId() external pure returns (bytes4) {
        return type(IReceiver).interfaceId;
    }
}
