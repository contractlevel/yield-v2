// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {
    CredentialRegistryIdentityValidator
} from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidator.sol";
import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";

/// @title CredentialRegistryAccountListValidatorPolicy
/// @author @contractlevel
/// @notice Validates that every account in an extracted account list has the required credentials.
contract CredentialRegistryAccountListValidatorPolicy is Policy, CredentialRegistryIdentityValidator {
    /// @notice The type and version of the policy
    string public constant override typeAndVersion = "CredentialRegistryAccountListValidatorPolicy 1.0.0";

    /// @notice Configures credential sources and requirements.
    /// @param parameters ABI-encoded credential source and requirement inputs
    function configure(bytes calldata parameters) internal override onlyInitializing {
        if (parameters.length == 0) {
            __CredentialRegistryIdentitityValidator_init_unchained(
                new ICredentialRequirements.CredentialSourceInput[](0),
                new ICredentialRequirements.CredentialRequirementInput[](0)
            );
            return;
        }

        (
            ICredentialRequirements.CredentialSourceInput[] memory sources,
            ICredentialRequirements.CredentialRequirementInput[] memory requirements
        ) = abi.decode(
            parameters,
            (ICredentialRequirements.CredentialSourceInput[], ICredentialRequirements.CredentialRequirementInput[])
        );

        __CredentialRegistryIdentitityValidator_init_unchained(sources, requirements);
    }

    /// @notice Validates all accounts passed as the single encoded address array parameter.
    /// @param parameters Policy parameters; expects exactly one `abi.encode(address[])` item
    /// @param context Additional policy context passed to the credential validator
    /// @return The policy result, `Continue` when every account validates
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata context)
        public
        view
        override
        returns (IPolicyEngine.PolicyResult)
    {
        if (parameters.length != 1) revert InvalidParameters("expected kyc account list");

        address[] memory accounts = abi.decode(parameters[0], (address[]));
        if (accounts.length == 0) revert InvalidParameters("expected at least 1 kyc account");

        for (uint256 i; i < accounts.length; ++i) {
            if (!validate(accounts[i], context)) {
                revert IPolicyEngine.PolicyRejected("account identity validation failed");
            }
        }

        return IPolicyEngine.PolicyResult.Continue;
    }
}
