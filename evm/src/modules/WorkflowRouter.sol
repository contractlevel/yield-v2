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
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The Yieldcoin v2 Vault
    address internal immutable i_vault;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev Mapping of workflow IDs to metadata
    mapping(bytes32 workflowId => WorkflowMetadata) internal s_workflowMetadata;
    /// @dev Mapping of workflow IDs to allowed function selectors
    /// @dev Function selector clash should be double checked!
    mapping(bytes32 workflowId => mapping(bytes4 selector => bool isAllowlisted)) internal s_workflowSelectors;

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

    /// @param params Constructor parameters
    /// @dev Precondition: required address params must not be the zero address
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
    /// @dev If this function call reverts, it can be retried with a higher gas
    /// limit. The receiver is responsible for discarding stale reports.
    /// @param metadata Report's metadata.
    /// @param report Workflow report.
    /// @dev Precondition: Caller must have the KEYSTONE_FORWARDER_ROLE
    /// @dev Precondition: WorkflowRouter must not be paused
    /// @dev Precondition: Workflow ID must not be zero
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

        if (!s_workflowSelectors[workflowId][selector]) {
            revert WorkflowRouter__SelectorNotAllowlisted(workflowId, selector);
        }

        //slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) = i_vault.call(report);
        if (!success) revert WorkflowRouter__CallFailed(returnData);
    }

    /// @notice Decodes metadata fields from the Keystone Forwarder's onReport call
    /// @dev Metadata is abi.encodePacked by the Forwarder:
    ///      - Offset  0, size 32: length prefix (standard dynamic bytes)
    ///      - Offset 32, size 32: workflowId    (bytes32)
    ///      - Offset 64, size 10: workflowName  (bytes10)
    ///      - Offset 74, size 20: workflowOwner (address)
    /// @param metadata The raw metadata bytes from onReport
    /// @return workflowId The unique workflow identifier
    /// @return workflowName The hash-encoded workflow name (bytes10)
    /// @return workflowOwner The address that deployed the workflow
    function _decodeMetadata(bytes calldata metadata)
        internal
        pure
        returns (bytes32 workflowId, bytes10 workflowName, address workflowOwner)
    {
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
    /// @notice Set `name` and `owner` to zero to remove metadata for `workflowId`
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

        s_workflowMetadata[workflowId] = WorkflowMetadata(owner, name);
        emit WorkflowMetadataSet(workflowId, name, owner);
    }

    /// @notice Sets the workflow selectors
    /// @param workflowId The ID of the workflow
    /// @param selectors The selectors to set
    /// @param isAllowlisted Whether the selectors are allowlisted
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: workflowId must not be zero
    /// @notice Set `isAllowlisted` to false to remove selectors from the workflow allowlist
    function setWorkflowSelectors(bytes32 workflowId, bytes4[] calldata selectors, bool isAllowlisted)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (workflowId == bytes32(0)) revert WorkflowRouter__NoZeroWorkflowId();

        for (uint256 i; i < selectors.length; ++i) {
            s_workflowSelectors[workflowId][selectors[i]] = isAllowlisted;
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

    /// @notice Gets whether a selector is allowlisted for a workflow
    /// @param workflowId The ID of the workflow
    /// @param selector The selector to check
    /// @return isAllowlisted Whether the selector is allowlisted for the workflow
    function getAllowlistedWorkflowSelector(bytes32 workflowId, bytes4 selector)
        external
        view
        returns (bool isAllowlisted)
    {
        isAllowlisted = s_workflowSelectors[workflowId][selector];
    }

    /// @notice Gets the Yieldcoin v2 Vault address for this chain
    /// @return vault The address of the vault
    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC165
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    /// @dev Overrides AccessControlDefaultAdminRules and IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlDefaultAdminRules, IERC165)
        returns (bool)
    {
        return interfaceId == type(IReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
