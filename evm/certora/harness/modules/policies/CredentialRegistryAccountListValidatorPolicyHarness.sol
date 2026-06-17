// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

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

    function setAccountValid(address account, bool isValid) external {
        s_validAccounts[account] = isValid;
    }

    function validate(address account, bytes calldata) public view override returns (bool) {
        return s_validAccounts[account];
    }

    function oneAccountParameters(address account) external pure returns (bytes[] memory parameters) {
        address[] memory accounts = new address[](1);
        accounts[0] = account;
        parameters = _accountListParameters(accounts);
    }

    function twoAccountParameters(address accountOne, address accountTwo)
        external
        pure
        returns (bytes[] memory parameters)
    {
        address[] memory accounts = new address[](2);
        accounts[0] = accountOne;
        accounts[1] = accountTwo;
        parameters = _accountListParameters(accounts);
    }

    function emptyAccountListParameters() external pure returns (bytes[] memory parameters) {
        address[] memory accounts = new address[](0);
        parameters = _accountListParameters(accounts);
    }

    function multiplePolicyParameters(address a1, address a2) external pure returns (bytes[] memory parameters) {
        address[] memory accounts = new address[](2);
        accounts[0] = a1;
        accounts[1] = a2;

        parameters = new bytes[](2);
        parameters[0] = abi.encode(accounts);
        parameters[1] = abi.encode(accounts);
    }

    function _accountListParameters(address[] memory accounts) internal pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = abi.encode(accounts);
    }
}
