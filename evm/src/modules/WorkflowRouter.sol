// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/shared/interfaces/IReceiver.sol";
import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IWorkflowRouter} from "../interfaces/modules/IWorkflowRouter.sol";
import {IBaseVault} from "../interfaces/vaults/IBaseVault.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 WorkflowRouter
/// @author @contractlevel
/// @notice Handles incoming CRE reports from Chainlink's Keystone Forwarder for the Yieldcoin v2 system
/// @dev Validates workflow metadata, report destination, observation age, and selector allowlist,
///      then strips the signed envelope and dispatches the vault calldata. No business logic lives here.
contract WorkflowRouter is IWorkflowRouter, AccessControlDefaultAdminRules, Pausable {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Keystone metadata contains workflow ID (32), name (10), owner (20), and report ID (2)
    uint256 internal constant KEYSTONE_METADATA_LENGTH = 64;
    /// @dev Maximum time between the signed observation and report delivery
    uint256 internal constant MAX_REPORT_AGE = 30 minutes;
    /// @dev Report envelope: chain selector (8), target router (20), observation timestamp (32)
    uint256 internal constant REPORT_ENVELOPE_LENGTH = 60;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The Yieldcoin v2 Vault
    address internal immutable i_vault;
    /// @dev The vault's CCIP chain selector
    uint64 internal immutable i_thisChainSelector;

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
    /// @notice Parameters used to initialize the WorkflowRouter
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

    /// @notice Initializes the WorkflowRouter and grants its initial roles
    /// @param params Constructor parameters
    /// @dev Reverts if params.defaultAdmin is the zero address
    /// @dev Reverts if params.pauser is the zero address
    /// @dev Reverts if params.unpauser is the zero address
    /// @dev Reverts if params.configOperator is the zero address
    /// @dev Reverts if params.keystoneForwarder is the zero address
    /// @dev Reverts if params.vault is the zero address
    /// @dev Reverts if params.vault reports a zero chain selector
    constructor(ConstructorParams memory params)
        AccessControlDefaultAdminRules(params.initialDelay, params.defaultAdmin)
    {
        _revertIfZeroAddress(params.pauser);
        _revertIfZeroAddress(params.unpauser);
        _revertIfZeroAddress(params.configOperator);
        _revertIfZeroAddress(params.keystoneForwarder);
        _revertIfZeroAddress(params.vault);

        i_vault = params.vault;
        uint64 chainSelector = IBaseVault(params.vault).getThisChainSelector();
        if (chainSelector == 0) revert WorkflowRouter__NoZeroChainSelector();
        i_thisChainSelector = chainSelector;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
        _grantRole(Roles.KEYSTONE_FORWARDER_ROLE, params.keystoneForwarder);
    }

    /// @notice Validates that a required address is nonzero
    /// @param value The address to validate
    /// @dev Reverts if value is the zero address
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert WorkflowRouter__NoZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                               ON REPORT
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates and forwards an incoming CRE workflow report to the vault
    /// @param metadata The packed Keystone metadata containing workflow ID, name, owner, and report ID
    /// @param report The target chain selector, router, observation timestamp, and raw vault calldata
    /// @dev A report that fails because its execution gas limit is insufficient may be retried with a higher gas limit
    ///      only while its signed observation timestamp remains valid
    /// @dev Reverts if the caller does not have KEYSTONE_FORWARDER_ROLE
    /// @dev Reverts if the router is paused
    /// @dev Reverts if metadata is not exactly 64 bytes
    /// @dev Reverts if the decoded workflow ID, name, or owner is zero
    /// @dev Reverts if the decoded workflow name and owner do not match the metadata registered for the workflow ID
    /// @dev Reverts if report is shorter than its envelope and a function selector
    /// @dev Reverts if the report's target chain selector or router does not match this router
    /// @dev Reverts if the observation timestamp is in the future or more than 30 minutes old
    /// @dev Reverts if the report selector is not allowlisted for the workflow
    /// @dev Reverts if the forwarded vault call fails
    /// @dev The metadata report ID is unused. This router rejects expired reports but does not independently reject an
    ///      otherwise-valid replay within the 30-minute window; Keystone manages transmission replay state.
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

        if (report.length < REPORT_ENVELOPE_LENGTH + 4) revert WorkflowRouter__ReportTooShort(report.length);

        uint64 targetChainSelector = uint64(bytes8(report[:8]));
        address targetRouter = address(bytes20(report[8:28]));
        if (targetChainSelector != i_thisChainSelector || targetRouter != address(this)) {
            revert WorkflowRouter__InvalidReportDomain(targetChainSelector, targetRouter);
        }

        uint256 observedAt = uint256(bytes32(report[28:REPORT_ENVELOPE_LENGTH]));
        if (observedAt > block.timestamp) revert WorkflowRouter__ReportFromFuture(observedAt, block.timestamp);
        if (block.timestamp - observedAt > MAX_REPORT_AGE) {
            revert WorkflowRouter__ReportExpired(observedAt, block.timestamp);
        }

        bytes calldata vaultCall = report[REPORT_ENVELOPE_LENGTH:];
        bytes4 selector = bytes4(vaultCall[:4]);

        uint256 generation = s_workflowGenerations[workflowId];
        if (!s_workflowSelectors[workflowId][generation][selector]) {
            revert WorkflowRouter__SelectorNotAllowlisted(workflowId, selector);
        }

        //slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) = i_vault.call(vaultCall);
        if (!success) revert WorkflowRouter__CallFailed(returnData);
    }

    /// @notice Decodes metadata fields from the Keystone Forwarder's onReport call
    /// @param metadata The raw metadata bytes from onReport
    /// @return workflowId The unique workflow identifier
    /// @return workflowName The hash-encoded workflow name (bytes10)
    /// @return workflowOwner The address that deployed the workflow
    /// @dev Metadata is abi.encodePacked by the Forwarder (no length prefix):
    ///      - Offset  0, size 32: workflowId    (bytes32)
    ///      - Offset 32, size 10: workflowName  (bytes10)
    ///      - Offset 42, size 20: workflowOwner (address)
    ///      - Offset 62, size  2: reportId      (unused)
    /// @dev Reverts if metadata is not exactly 64 bytes
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
    /// @param name The hash-encoded workflow name
    /// @param owner The address that deployed the workflow
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if workflowId is zero
    /// @dev Reverts if exactly one of name and owner is zero
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
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if workflowId is zero
    /// @dev Reverts if selectors is empty
    /// @dev Reverts if workflowId does not have registered metadata (see getWorkflowMetadata)
    /// @dev Set `isAllowlisted` to false to remove selectors from the workflow allowlist
    /// @dev Writes into the workflow's current selector-allowlist generation (see `getWorkflowGeneration`)
    function setWorkflowSelectors(bytes32 workflowId, bytes4[] calldata selectors, bool isAllowlisted)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (workflowId == bytes32(0)) revert WorkflowRouter__NoZeroWorkflowId();
        if (selectors.length == 0) revert WorkflowRouter__NoSelectors();
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
    /// @dev Reverts if the caller does not have PAUSER_ROLE
    /// @dev Reverts if the contract is already paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the WorkflowRouter
    /// @dev Reverts if the caller does not have UNPAUSER_ROLE
    /// @dev Reverts if the contract is not paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the registered metadata for a workflow ID
    /// @param workflowId The workflow ID to look up
    /// @return metadata The registered owner and name, or zero values if the workflow is unregistered
    /// @dev A workflow is registered if and only if owner and name are both nonzero
    function getWorkflowMetadata(bytes32 workflowId) external view returns (WorkflowMetadata memory metadata) {
        metadata = s_workflowMetadata[workflowId];
    }

    /// @notice Returns the current selector-allowlist generation for a workflow ID
    /// @param workflowId The workflow ID to query
    /// @return generation The current generation of the workflow's selector allowlist
    /// @dev Bumped by every successful `setWorkflowMetadata` call for this workflow ID. A generation of
    ///      0 means the workflow ID has never been configured. A nonzero generation does not by itself
    ///      mean the workflow ID is currently registered, since removal also advances it - check
    ///      `getWorkflowMetadata` for current registration status
    function getWorkflowGeneration(bytes32 workflowId) external view returns (uint256 generation) {
        generation = s_workflowGenerations[workflowId];
    }

    /// @notice Returns whether a selector is allowlisted for a workflow
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

    /// @notice Returns the Yieldcoin v2 Vault address for this chain
    /// @return vault The address of the vault
    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    /// @notice Returns the CCIP chain selector this router accepts reports for
    /// @return chainSelector The CCIP chain selector read from the vault during construction
    function getThisChainSelector() external view returns (uint64 chainSelector) {
        chainSelector = i_thisChainSelector;
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
