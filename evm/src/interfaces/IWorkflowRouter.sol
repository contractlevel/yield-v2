// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IReceiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";
import {IPauseable} from "./IPauseable.sol";

/// @title Yieldcoin v2 WorkflowRouter Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 WorkflowRouter contract
interface IWorkflowRouter is IReceiver, IPauseable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when any of the metadata fields are zero
    error WorkflowRouter__MetadataZero(bytes32 workflowId, bytes10 workflowName, address workflowOwner);
    /// @dev Thrown when the zero address is provided for required configuration
    error WorkflowRouter__NoZeroAddress();
    /// @dev Thrown when the zero workflow ID is provided
    error WorkflowRouter__NoZeroWorkflowId();
    /// @dev Thrown when the metadata fields do not match the registered metadata
    error WorkflowRouter__MetadataMismatch(bytes32 workflowId, bytes10 workflowName, address workflowOwner);
    /// @dev Thrown when the report is too short
    error WorkflowRouter__ReportTooShort(uint256 reportLength);
    /// @dev Thrown when the selector is not allowlisted
    error WorkflowRouter__SelectorNotAllowlisted(bytes32 workflowId, bytes4 selector);
    /// @dev Thrown when the call to the vault fails
    error WorkflowRouter__CallFailed(bytes returnData);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Emitted when the workflow metadata is set
    event WorkflowMetadataSet(bytes32 indexed workflowId, bytes10 indexed name, address indexed owner);
    /// @dev Emitted when the workflow selector is set
    event WorkflowSelectorSet(bytes32 indexed workflowId, bytes4 indexed selector, bool isAllowlisted);
}
