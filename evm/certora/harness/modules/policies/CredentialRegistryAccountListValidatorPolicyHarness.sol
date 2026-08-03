// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";
import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract CredentialRegistryAccountListValidatorPolicyHarness is
    CredentialRegistryAccountListValidatorPolicy,
    HelperHarness
{
    mapping(address account => bool isValid) internal s_validAccounts;
    bool internal s_requirementsConfigured;

    function getCredentialRequirementIds() public view override returns (bytes32[] memory requirementIds) {
        requirementIds = new bytes32[](s_requirementsConfigured ? 1 : 0);
    }

    function validate(address account, bytes calldata) public view override returns (bool) {
        return s_validAccounts[account];
    }

    function oneAccountParameters(address account) external pure returns (bytes[] memory parameters) {
        address[] memory accounts = new address[](1);
        accounts[0] = account;
        parameters = _accountListParameters(accounts);
    }

    function emptyAccountListParameters() external pure returns (bytes[] memory parameters) {
        address[] memory accounts = new address[](0);
        parameters = _accountListParameters(accounts);
    }

    function malformedAccountListParameters() external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = bytes("");
    }

    function _accountListParameters(address[] memory accounts) internal pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = abi.encode(accounts);
    }
}
