// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, Vm} from "forge-std/Test.sol";

import {Constants} from "./Constants.t.sol";

import {IPauseable} from "../src/interfaces/IPauseable.sol";

contract BaseTest is Constants, Test {
    address internal immutable i_owner = makeAddr("owner");
    address internal immutable i_pauser = makeAddr("pauser");
    address internal immutable i_unpauser = makeAddr("unpauser");
    address internal immutable i_nonOwner = makeAddr("nonOwner");
    address internal immutable i_nonKycUser = makeAddr("nonKycUser");
    address internal immutable i_depositor = makeAddr("depositor");
    address internal immutable i_withdrawer = makeAddr("withdrawer");
    address internal immutable i_recipient1 = makeAddr("recipient1");
    address internal immutable i_recipient2 = makeAddr("recipient2");
    address internal immutable i_configOperator = makeAddr("configOperator");
    address internal immutable i_rebalanceOperator = makeAddr("rebalanceOperator");
    address internal immutable i_emergencyDrainer = makeAddr("emergencyDrainer");
    address internal immutable i_emergencyReceiver = makeAddr("emergencyReceiver");
    address internal immutable i_linkOperator = makeAddr("linkOperator");
    address internal immutable i_donateOperator = makeAddr("donateOperator");
    address internal immutable i_complianceOperator = makeAddr("complianceOperator");
    address internal immutable i_policyEngineManager = makeAddr("policyEngineManager");
    address internal immutable i_epochOperator = makeAddr("epochOperator");
    address internal immutable i_treasury = makeAddr("treasury");
    address internal immutable i_upgrader = makeAddr("upgrader");

    modifier givenContractIsPaused(address contractAddress) {
        (, address msgSender,) = vm.readCallers();
        _changePrank(i_pauser);
        IPauseable(contractAddress).pause();
        _changePrank(msgSender);
        _;
    }

    modifier givenContractIsNotPaused(address contractAddress) {
        (, address msgSender,) = vm.readCallers();
        _changePrank(i_unpauser);
        IPauseable(contractAddress).unpause();
        _changePrank(msgSender);
        _;
    }

    /// @notice Modifier to change the caller to a non-admin
    modifier whenCallerIsNotAdmin() {
        _changePrank(i_nonOwner);
        _;
    }

    constructor() {
        vm.label(i_owner, "Owner");
        vm.label(i_pauser, "Pauser");
        vm.label(i_unpauser, "Unpauser");
        vm.label(i_nonOwner, "NonOwner");
        vm.label(i_nonKycUser, "NonKycUser");
        vm.label(i_depositor, "Depositor");
        vm.label(i_withdrawer, "Withdrawer");
        vm.label(i_recipient1, "Recipient1");
        vm.label(i_recipient2, "Recipient2");
        vm.label(i_configOperator, "ConfigOperator");
        vm.label(i_rebalanceOperator, "RebalanceOperator");
        vm.label(i_emergencyDrainer, "EmergencyDrainer");
        vm.label(i_emergencyReceiver, "EmergencyReceiver");
        vm.label(i_linkOperator, "LinkOperator");
        vm.label(i_donateOperator, "DonateOperator");
        vm.label(i_complianceOperator, "ComplianceOperator");
        vm.label(i_policyEngineManager, "PolicyEngineManager");
        vm.label(i_epochOperator, "EpochOperator");
        vm.label(i_treasury, "Treasury");
        vm.label(i_upgrader, "Upgrader");
    }

    /// @notice Finds the first log matching both the event signature and emitting contract.
    ///         Reverts if no match is found.
    /// @param eventSig keccak256 hash of the event signature, e.g. keccak256("Transfer(address,address,uint256)")
    /// @param emitter The contract expected to have emitted the event
    /// @return The matching log. Indexed params are in topics[1..N]; non-indexed params are abi-encoded in data.
    function _assertEmittedBy(bytes32 eventSig, address emitter) internal view returns (Vm.Log memory) {
        Vm.Log[] memory logs = vm.getRecordedLogs();

        return _assertEmittedBy(logs, eventSig, emitter);
    }

    function _assertEmittedBy(Vm.Log[] memory logs, bytes32 eventSig, address emitter)
        internal
        pure
        returns (Vm.Log memory)
    {
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].topics[0] == eventSig && logs[i].emitter == emitter) return logs[i];
        }
        revert("_assertEmittedBy: event not emitted by contract");
    }

    /// @notice Changes the caller for the current transaction
    /// @param newCaller The new caller address
    function _changePrank(address newCaller) internal {
        vm.stopPrank();
        vm.startPrank(newCaller);
    }

    /// @notice Builds the metadata for a workflow
    /// @param workflowId The ID of the workflow
    /// @param name The name of the workflow
    /// @param owner The owner of the workflow
    /// @return metadata The metadata for the workflow
    function _buildMetadata(bytes32 workflowId, bytes10 name, address owner)
        internal
        pure
        returns (bytes memory metadata)
    {
        metadata = abi.encodePacked(workflowId, name, owner);
    }

    /// @notice Helper function to create CRE encoded workflow name
    /// @dev see: https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#how-workflow-names-are-encoded
    /// @param rawName The raw string name of the workflow
    /// @return encodedName The CRE encoded workflow name
    function _createWorkflowName(string memory rawName) internal pure returns (bytes10 encodedName) {
        // Convert workflow name to bytes10:
        // SHA256 hash → hex encode → take first 10 chars → hex encode those chars
        bytes32 hash = sha256(bytes(rawName));
        bytes memory hexString = _bytesToHexString(abi.encodePacked(hash));
        bytes memory first10 = new bytes(10);
        for (uint256 i; i < 10; ++i) {
            first10[i] = hexString[i];
        }
        encodedName = bytes10(first10);
    }

    /// @dev Helper function for '_createWorkflowName'
    /// @param data The bytes data to convert to a hex string
    function _bytesToHexString(bytes memory data) internal pure returns (bytes memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory hexString = new bytes(data.length * 2);

        for (uint256 i; i < data.length; ++i) {
            hexString[i * 2] = hexChars[uint8(data[i] >> 4)];
            hexString[i * 2 + 1] = hexChars[uint8(data[i] & 0x0f)];
        }

        return hexString;
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual {}
}
