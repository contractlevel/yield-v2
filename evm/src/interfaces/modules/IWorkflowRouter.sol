// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IReceiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";
import {IPauseable} from "../common/IPauseable.sol";

/// @title Yieldcoin v2 WorkflowRouter Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 WorkflowRouter contract
interface IWorkflowRouter is IReceiver, IPauseable {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Struct for workflow metadata
    /// @param owner The address that deployed the workflow
    /// @param name The hash-encoded workflow name
    struct WorkflowMetadata {
        address owner;
        bytes10 name;
    }

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
    event WorkflowSelectorSet(bytes32 indexed workflowId, bytes4 indexed selector, bool indexed isAllowlisted);

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the workflow metadata
    /// @param workflowId The ID of the workflow
    /// @param name The hash-encoded workflow name
    /// @param owner The address that deployed the workflow
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: workflowId must not be zero
    /// @notice Set `name` and `owner` to zero to remove metadata for `workflowId`
    function setWorkflowMetadata(bytes32 workflowId, bytes10 name, address owner) external;

    /// @notice Sets the workflow selectors
    /// @param workflowId The ID of the workflow
    /// @param selectors The selectors to set
    /// @param isAllowlisted Whether the selectors are allowlisted
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: workflowId must not be zero
    /// @notice Set `isAllowlisted` to false to remove selectors from the workflow allowlist
    function setWorkflowSelectors(bytes32 workflowId, bytes4[] calldata selectors, bool isAllowlisted) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the registered metadata for a workflow ID
    /// @dev A workflow is registered iff owner != address(0) and name != bytes10(0).
    /// @param workflowId The workflow ID to look up
    /// @return metadata The registered owner and name
    function getWorkflowMetadata(bytes32 workflowId) external view returns (WorkflowMetadata memory metadata);

    /// @notice Gets whether a selector is allowlisted for a workflow
    /// @param workflowId The ID of the workflow
    /// @param selector The selector to check
    /// @return isAllowlisted Whether the selector is allowlisted for the workflow
    function getAllowlistedWorkflowSelector(bytes32 workflowId, bytes4 selector)
        external
        view
        returns (bool isAllowlisted);

    /// @notice Gets the Yieldcoin v2 Vault address for this chain
    /// @return vault The address of the vault
    function getVault() external view returns (address vault);
}
