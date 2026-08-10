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
    /// @notice Metadata registered for a workflow
    /// @param owner The address that deployed the workflow
    /// @param name The hash-encoded workflow name
    struct WorkflowMetadata {
        address owner;
        bytes10 name;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when Keystone metadata is not exactly 64 bytes
    /// @param metadataLength The length of the metadata received
    error WorkflowRouter__InvalidMetadataLength(uint256 metadataLength);
    /// @dev Thrown when any of the metadata fields are zero: in onReport, when the decoded workflowId,
    ///      workflowName, or workflowOwner is zero; in setWorkflowMetadata, when name and owner are not
    ///      both zero (removal) or both nonzero (registration)
    /// @param workflowId The workflow ID being validated
    /// @param workflowName The workflow name being validated
    /// @param workflowOwner The workflow owner being validated
    error WorkflowRouter__MetadataZero(bytes32 workflowId, bytes10 workflowName, address workflowOwner);
    /// @dev Thrown when the zero address is provided for required configuration
    error WorkflowRouter__NoZeroAddress();
    /// @dev Thrown when the zero workflow ID is provided
    error WorkflowRouter__NoZeroWorkflowId();
    /// @dev Thrown when no workflow selectors are provided
    error WorkflowRouter__NoSelectors();
    /// @dev Thrown when the decoded metadata does not match the registered metadata for the workflow ID
    /// @param workflowId The workflow ID whose metadata was checked
    /// @param workflowName The decoded workflow name that failed to match
    /// @param workflowOwner The decoded workflow owner that failed to match
    error WorkflowRouter__MetadataMismatch(bytes32 workflowId, bytes10 workflowName, address workflowOwner);
    /// @dev Thrown when setWorkflowMetadata is called with a name and owner that already match the
    ///      currently registered metadata for the workflow ID (including removing an already-removed,
    ///      i.e. unregistered, workflow ID)
    /// @param workflowId The workflow ID whose metadata was not changed
    /// @param name The unchanged workflow name
    /// @param owner The unchanged workflow owner
    error WorkflowRouter__MetadataUnchanged(bytes32 workflowId, bytes10 name, address owner);
    /// @dev Thrown when setWorkflowSelectors is called for a workflow ID with no registered metadata
    /// @param workflowId The unregistered workflow ID
    error WorkflowRouter__WorkflowNotRegistered(bytes32 workflowId);
    /// @dev Thrown when the report is shorter than the 4-byte function selector
    /// @param reportLength The length of the report received
    error WorkflowRouter__ReportTooShort(uint256 reportLength);
    /// @dev Thrown when the report's function selector is not allowlisted for the workflow ID
    /// @param workflowId The workflow ID the report was submitted for
    /// @param selector The function selector decoded from the report
    error WorkflowRouter__SelectorNotAllowlisted(bytes32 workflowId, bytes4 selector);
    /// @dev Thrown when the low-level call forwarding the report to the vault reverts
    /// @param returnData The revert data returned by the failed call
    error WorkflowRouter__CallFailed(bytes returnData);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the workflow metadata is set
    /// @param workflowId The ID of the workflow
    /// @param name The hash-encoded workflow name that was set (zero if metadata was removed)
    /// @param owner The address that deployed the workflow (zero if metadata was removed)
    event WorkflowMetadataSet(bytes32 indexed workflowId, bytes10 indexed name, address indexed owner);
    /// @notice Emitted when a workflow's selector allowlist status is set
    /// @param workflowId The ID of the workflow
    /// @param selector The function selector whose allowlist status was set
    /// @param isAllowlisted Whether the selector is now allowlisted for the workflow
    event WorkflowSelectorSet(bytes32 indexed workflowId, bytes4 indexed selector, bool indexed isAllowlisted);

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the workflow metadata
    /// @param workflowId The ID of the workflow
    /// @param name The hash-encoded workflow name
    /// @param owner The address that deployed the workflow
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if workflowId is zero
    /// @dev Reverts unless name and owner are both nonzero when setting metadata or both zero when removing metadata
    /// @dev Reverts if the (name, owner) pair matches the currently registered metadata, including when removing an
    ///      already-unregistered workflow ID
    /// @dev Set `name` and `owner` to zero to remove metadata for `workflowId`
    /// @dev Every successful call advances the workflow's selector-allowlist generation by one,
    ///      starting a fresh, empty selector set: selectors from every prior generation become
    ///      unreachable. Registering a workflow ID, or updating the metadata of an already-registered
    ///      workflow ID, requires selectors to be re-added via `setWorkflowSelectors` afterward.
    ///      Removing a workflow ID also invalidates its selectors, but additionally leaves it unable to
    ///      receive new selectors until it is registered again, since `setWorkflowSelectors` requires
    ///      registered metadata.
    function setWorkflowMetadata(bytes32 workflowId, bytes10 name, address owner) external;

    /// @notice Sets the workflow selectors
    /// @param workflowId The ID of the workflow
    /// @param selectors The selectors to set
    /// @param isAllowlisted Whether the selectors are allowlisted
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if workflowId is zero
    /// @dev Reverts if selectors is empty
    /// @dev Reverts if workflowId does not have registered metadata (see getWorkflowMetadata)
    /// @dev Set `isAllowlisted` to false to remove selectors from the workflow allowlist
    /// @dev Writes into the workflow's current selector-allowlist generation (see `getWorkflowGeneration`)
    function setWorkflowSelectors(bytes32 workflowId, bytes4[] calldata selectors, bool isAllowlisted) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the registered metadata for a workflow ID
    /// @param workflowId The workflow ID to look up
    /// @return metadata The registered owner and name, or zero values if the workflow is unregistered
    /// @dev A workflow is registered if and only if owner and name are both nonzero
    function getWorkflowMetadata(bytes32 workflowId) external view returns (WorkflowMetadata memory metadata);

    /// @notice Returns the current selector-allowlist generation for a workflow ID
    /// @param workflowId The workflow ID to query
    /// @return generation The current generation of the workflow's selector allowlist
    /// @dev Bumped by every successful `setWorkflowMetadata` call for this workflow ID. A generation of
    ///      0 means the workflow ID has never been configured. A nonzero generation does not by itself
    ///      mean the workflow ID is currently registered, since removal also advances it - check
    ///      `getWorkflowMetadata` for current registration status
    function getWorkflowGeneration(bytes32 workflowId) external view returns (uint256 generation);

    /// @notice Returns whether a selector is allowlisted for a workflow
    /// @param workflowId The ID of the workflow
    /// @param selector The selector to check
    /// @return isAllowlisted Whether the selector is allowlisted for the workflow
    /// @dev Checks against the workflow's current generation (see `getWorkflowGeneration`)
    function getAllowlistedWorkflowSelector(bytes32 workflowId, bytes4 selector)
        external
        view
        returns (bool isAllowlisted);

    /// @notice Returns the Yieldcoin v2 Vault address for this chain
    /// @return vault The address of the vault
    function getVault() external view returns (address vault);
}
