// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";
import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IWorkflowRouter} from "../interfaces/modules/IWorkflowRouter.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 WorkflowRouter
/// @author @contractlevel
/// @notice Handles incoming CRE reports from Chainlink's Keystone Forwarder for the Yieldcoin v2 system
/// @dev Validates every incoming CRE report against a per-workflow metadata + selector allowlist,
///      then dispatches the raw report calldata to the vault. No business logic lives here.
contract WorkflowRouter is IWorkflowRouter, AccessControlDefaultAdminRules, Pausable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Keystone metadata contains workflow ID (32), name (10), owner (20), and report ID (2)
    uint256 internal constant KEYSTONE_METADATA_LENGTH = 64;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The Yieldcoin v2 Vault
    address internal immutable i_vault;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev Mapping of workflow IDs to metadata
    mapping(bytes32 workflowId => WorkflowMetadata) internal s_workflowMetadata;
    /// @dev Mapping of workflow IDs to their current selector-allowlist generation. Bumped on every
    ///      successful `setWorkflowMetadata` call (registration, removal, or updating the metadata of
    ///      an already-registered workflow ID), so a workflow ID reused after removal - or whose
    ///      metadata is updated while still registered - can never inherit selectors allowlisted under
    ///      a prior registration. A generation of 0 means the workflow ID has never been configured; it
    ///      is never reachable again once `setWorkflowMetadata` has been called for that ID, so it is
    ///      permanently dead/false-by-default. A nonzero generation does not by itself mean the
    ///      workflow ID is currently registered, since removal also advances it.
    mapping(bytes32 workflowId => uint256 generation) internal s_workflowGenerations;
    /// @dev Mapping of workflow IDs, to generation, to allowed function selectors. Indexed by the
    ///      workflow's current generation (`s_workflowGenerations`) so a prior generation's selectors
    ///      are never allowlisted for the current one.
    /// @dev Function selector clash should be double checked!
    mapping(bytes32 workflowId => mapping(uint256 generation => mapping(bytes4 selector => bool isAllowlisted)))
        internal s_workflowSelectors;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Parameters to initialize the contract in the constructor.
    /// @param initialDelay The initial delay for the default admin role
    /// @param defaultAdmin The address of the default admin
    /// @param pauser The address that can pause the router
    /// @param unpauser The address that can unpause the router
    /// @param configOperator The address that can configure workflow metadata and selectors
    /// @param keystoneForwarder The Chainlink Keystone Forwarder address
    /// @param vault The address of the Yieldcoin v2 Vault
    struct ConstructorParams {
        uint48 initialDelay;
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address keystoneForwarder;
        address vault;
    }

    /// @notice Initializes the WorkflowRouter and grants initial roles.
    /// @param params Constructor parameters
    /// @dev Precondition: pauser, unpauser, configOperator, keystoneForwarder, and vault must not be the zero address
    ///      (defaultAdmin validity is enforced by AccessControlDefaultAdminRules)
    constructor(ConstructorParams memory params)
        AccessControlDefaultAdminRules(params.initialDelay, params.defaultAdmin)
    {
        _revertIfZeroAddress(params.pauser);
        _revertIfZeroAddress(params.unpauser);
        _revertIfZeroAddress(params.configOperator);
        _revertIfZeroAddress(params.keystoneForwarder);
        _revertIfZeroAddress(params.vault);

        i_vault = params.vault;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
        _grantRole(Roles.KEYSTONE_FORWARDER_ROLE, params.keystoneForwarder);
    }

    /// @notice Reverts when a required address input is zero
    /// @param value The address to validate
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert WorkflowRouter__NoZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                               ON REPORT
    //////////////////////////////////////////////////////////////*/
    /// @notice Handles incoming keystone reports.
    /// @dev A report that fails because its execution gas limit is insufficient may be retried with a higher gas limit.
    /// @param metadata Report's metadata.
    /// @param report Workflow report.
    /// @dev Precondition: Caller must have the KEYSTONE_FORWARDER_ROLE
    /// @dev Precondition: WorkflowRouter must not be paused
    /// @dev Precondition: metadata.length must equal the Keystone metadata length
    /// @dev Precondition: Workflow ID must not be zero
    /// @dev Precondition: Workflow Metadata must be valid
    /// @dev Precondition: report.length must be valid for a selector
    /// @dev Precondition: selector must be allowlisted
    /// @dev Precondition: Call to the vault must succeed
    function onReport(bytes calldata metadata, bytes calldata report)
        external
        whenNotPaused
        onlyRole(Roles.KEYSTONE_FORWARDER_ROLE)
    {
        (bytes32 workflowId, bytes10 workflowName, address workflowOwner) = _decodeMetadata(metadata);
        if (workflowId == bytes32(0) || workflowName == bytes10(0) || workflowOwner == address(0)) {
            revert WorkflowRouter__MetadataZero(workflowId, workflowName, workflowOwner);
        }

        WorkflowMetadata memory registered = s_workflowMetadata[workflowId];
        if (registered.owner != workflowOwner || registered.name != workflowName) {
            revert WorkflowRouter__MetadataMismatch(workflowId, workflowName, workflowOwner);
        }

        if (report.length < 4) revert WorkflowRouter__ReportTooShort(report.length);
        bytes4 selector = bytes4(report[:4]);

        uint256 generation = s_workflowGenerations[workflowId];
        if (!s_workflowSelectors[workflowId][generation][selector]) {
            revert WorkflowRouter__SelectorNotAllowlisted(workflowId, selector);
        }

        //slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) = i_vault.call(report);
        if (!success) revert WorkflowRouter__CallFailed(returnData);
    }

    /// @notice Decodes metadata fields from the Keystone Forwarder's onReport call
    /// @dev Metadata is abi.encodePacked by the Forwarder (no length prefix):
    ///      - Offset  0, size 32: workflowId    (bytes32)
    ///      - Offset 32, size 10: workflowName  (bytes10)
    ///      - Offset 42, size 20: workflowOwner (address)
    ///      - Offset 62, size  2: reportId      (unused)
    /// @param metadata The raw metadata bytes from onReport
    /// @return workflowId The unique workflow identifier
    /// @return workflowName The hash-encoded workflow name (bytes10)
    /// @return workflowOwner The address that deployed the workflow
    function _decodeMetadata(bytes calldata metadata)
        internal
        pure
        returns (bytes32 workflowId, bytes10 workflowName, address workflowOwner)
    {
        if (metadata.length != KEYSTONE_METADATA_LENGTH) {
            revert WorkflowRouter__InvalidMetadataLength(metadata.length);
        }

        //slither-disable-next-line assembly
        assembly {
            workflowId := calldataload(metadata.offset)
            workflowName := calldataload(add(metadata.offset, 32))
            workflowOwner := shr(mul(12, 8), calldataload(add(metadata.offset, 42)))
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the workflow metadata
    /// @param workflowId The ID of the workflow
    /// @param name The hash-encoded workflow name (bytes10)
    /// @param owner The address that deployed the workflow
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: workflowId must not be zero
    /// @dev Precondition: name and owner must both be nonzero when setting metadata, or both zero when removing metadata
    /// @dev Precondition: the `(name, owner)` pair must differ from the currently registered metadata
    ///      for `workflowId` - changing either field is sufficient (reverts with
    ///      WorkflowRouter__MetadataUnchanged otherwise, including when removing an already-removed,
    ///      i.e. unregistered, workflow ID)
    /// @dev Set `name` and `owner` to zero to remove metadata for `workflowId`.
    /// @dev Every successful call advances the workflow's selector-allowlist generation by one,
    ///      starting a fresh, empty selector set: selectors from every prior generation become
    ///      unreachable. Registering a workflow ID, or updating the metadata of an already-registered
    ///      workflow ID, requires selectors to be re-added via `setWorkflowSelectors` afterward.
    ///      Removing a workflow ID also invalidates its selectors, but additionally leaves it unable to
    ///      receive new selectors until it is registered again, since `setWorkflowSelectors` requires
    ///      registered metadata.
    //slither-disable-next-line missing-zero-address-check
    function setWorkflowMetadata(bytes32 workflowId, bytes10 name, address owner)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (workflowId == bytes32(0)) revert WorkflowRouter__NoZeroWorkflowId();

        bool isRemoval = name == bytes10(0) && owner == address(0);
        if (!isRemoval && (name == bytes10(0) || owner == address(0))) {
            revert WorkflowRouter__MetadataZero(workflowId, name, owner);
        }

        WorkflowMetadata memory current = s_workflowMetadata[workflowId];
        if (current.owner == owner && current.name == name) {
            revert WorkflowRouter__MetadataUnchanged(workflowId, name, owner);
        }

        ++s_workflowGenerations[workflowId];
        s_workflowMetadata[workflowId] = WorkflowMetadata(owner, name);
        emit WorkflowMetadataSet(workflowId, name, owner);
    }

    /// @notice Sets the workflow selectors
    /// @param workflowId The ID of the workflow
    /// @param selectors The selectors to set
    /// @param isAllowlisted Whether the selectors are allowlisted
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: workflowId must not be zero
    /// @dev Precondition: workflowId must have registered metadata (see `getWorkflowMetadata`)
    /// @dev Set `isAllowlisted` to false to remove selectors from the workflow allowlist.
    /// @dev Writes into the workflow's current selector-allowlist generation (see `getWorkflowGeneration`).
    function setWorkflowSelectors(bytes32 workflowId, bytes4[] calldata selectors, bool isAllowlisted)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (workflowId == bytes32(0)) revert WorkflowRouter__NoZeroWorkflowId();
        if (s_workflowMetadata[workflowId].owner == address(0)) {
            revert WorkflowRouter__WorkflowNotRegistered(workflowId);
        }

        uint256 generation = s_workflowGenerations[workflowId];
        for (uint256 i; i < selectors.length; ++i) {
            s_workflowSelectors[workflowId][generation][selectors[i]] = isAllowlisted;
            emit WorkflowSelectorSet(workflowId, selectors[i], isAllowlisted);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 PAUSE
    //////////////////////////////////////////////////////////////*/
    /// @notice Pauses the WorkflowRouter
    /// @dev Precondition: Caller must have the PAUSER_ROLE
    /// @dev Precondition: WorkflowRouter must not be paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the WorkflowRouter
    /// @dev Precondition: Caller must have the UNPAUSER_ROLE
    /// @dev Precondition: WorkflowRouter must be paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the registered metadata for a workflow ID.
    /// @dev A workflow is registered iff owner != address(0) and name != bytes10(0).
    /// @param workflowId The workflow ID to look up
    /// @return metadata The registered owner and name (zero values if unregistered)
    function getWorkflowMetadata(bytes32 workflowId) external view returns (WorkflowMetadata memory metadata) {
        metadata = s_workflowMetadata[workflowId];
    }

    /// @notice Returns the current selector-allowlist generation for a workflow ID
    /// @dev Bumped by every successful `setWorkflowMetadata` call for this workflow ID. A generation of
    ///      0 means the workflow ID has never been configured. A nonzero generation does not by itself
    ///      mean the workflow ID is currently registered, since removal also advances it - check
    ///      `getWorkflowMetadata` for current registration status.
    /// @param workflowId The workflow ID to query
    /// @return generation The current generation of the workflow's selector allowlist
    function getWorkflowGeneration(bytes32 workflowId) external view returns (uint256 generation) {
        generation = s_workflowGenerations[workflowId];
    }

    /// @notice Gets whether a selector is allowlisted for a workflow
    /// @param workflowId The ID of the workflow
    /// @param selector The selector to check
    /// @return isAllowlisted Whether the selector is allowlisted for the workflow
    /// @dev Checks against the workflow's current generation (see `getWorkflowGeneration`)
    function getAllowlistedWorkflowSelector(bytes32 workflowId, bytes4 selector)
        external
        view
        returns (bool isAllowlisted)
    {
        isAllowlisted = s_workflowSelectors[workflowId][s_workflowGenerations[workflowId]][selector];
    }

    /// @notice Gets the Yieldcoin v2 Vault address for this chain
    /// @return vault The address of the vault
    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether this contract implements the given interface ID
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if this contract implements `interfaceId`, false otherwise
    /// @dev Overrides AccessControlDefaultAdminRules and IERC165. Additionally supports IReceiver by checking
    ///      `type(IReceiver).interfaceId` before falling back to `super.supportsInterface`.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlDefaultAdminRules, IERC165)
        returns (bool)
    {
        return interfaceId == type(IReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
