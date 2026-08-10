// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicy} from "@chainlink/policy-management/interfaces/IPolicy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title Yieldcoin v2 CredentialRegistryAccountListValidatorPolicy Interface
/// @author @contractlevel
/// @notice Interface for the CredentialRegistryAccountListValidatorPolicy
interface ICredentialRegistryAccountListValidatorPolicy is IPolicy {
    /// @dev Thrown when no credential requirements are configured
    error CredentialRegistryAccountListValidatorPolicy__NoCredentialRequirementsConfigured();

    /// @notice Validates that every account in an extracted account list satisfies all credential requirements
    /// @param parameters Policy parameters; expects exactly one `abi.encode(address[])` item
    /// @param context Additional context passed to credential registries and data validators
    /// @return policyResult `Continue` when every account satisfies all configured credential requirements
    /// @dev The caller, subject, and selector inputs are unused
    /// @dev Reverts if parameters does not contain exactly one item or the encoded account list is malformed or empty
    /// @dev Reverts if no credential requirements are configured
    /// @dev Reverts if any account fails credential validation
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata context)
        external
        view
        override
        returns (IPolicyEngine.PolicyResult policyResult);
}
