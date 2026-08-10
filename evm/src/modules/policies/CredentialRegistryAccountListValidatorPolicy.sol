// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {
    CredentialRegistryIdentityValidator
} from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidator.sol";
import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {
    ICredentialRegistryAccountListValidatorPolicy
} from "../../interfaces/policies/ICredentialRegistryAccountListValidatorPolicy.sol";

/// @title CredentialRegistryAccountListValidatorPolicy
/// @author @contractlevel
/// @notice Validates that every account in an extracted account list has the required credentials
contract CredentialRegistryAccountListValidatorPolicy is
    Policy,
    CredentialRegistryIdentityValidator,
    ICredentialRegistryAccountListValidatorPolicy
{
    /// @notice The type and version of the policy
    string public constant override typeAndVersion = "CredentialRegistryAccountListValidatorPolicy 1.0.0";

    /// @notice Configures the policy's initial credential sources and requirements
    /// @param parameters Empty bytes or an ABI-encoded tuple of CredentialSourceInput[] and CredentialRequirementInput[]
    /// @dev Empty parameters initialize the policy without credential requirements, causing run to fail closed until
    ///      a requirement is added or the policy is detached
    /// @dev Reverts if parameters is nonempty and malformed or any source or requirement configuration is invalid
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

    /// @notice Validates that every account in an extracted account list satisfies all credential requirements
    /// @param parameters Policy parameters; expects exactly one `abi.encode(address[])` item
    /// @param context Additional context passed to credential registries and data validators
    /// @return policyResult `Continue` when every account satisfies all configured credential requirements
    /// @dev The caller, subject, and selector inputs are unused
    /// @dev Reverts if parameters does not contain exactly one item or the encoded account list is malformed or empty
    /// @dev Reverts if no credential requirements are configured
    /// @dev Reverts if any account fails credential validation
    /// @dev This fail-closed check applies whether the policy was deployed/initialized without
    ///      any requirements (see `configure`) or all requirements were later
    ///      removed via the inherited `removeCredentialRequirement`. Without this check, the
    ///      inherited `validate()` would iterate zero requirements and vacuously return true,
    ///      silently approving every account instead of failing closed.
    /// @dev To intentionally disable KYC enforcement, detach this policy via
    ///      `IPolicyEngine.removePolicy(target, selector, address(this))` rather than removing
    ///      all of its credential requirements while it remains attached. Draining requirements
    ///      while still attached now causes every gated call to revert until a requirement is
    ///      restored or the policy is removed — the intended fail-closed behavior, not a bug.
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata context)
        public
        view
        override(Policy, ICredentialRegistryAccountListValidatorPolicy)
        returns (IPolicyEngine.PolicyResult policyResult)
    {
        if (parameters.length != 1) revert InvalidParameters("expected kyc account list");

        address[] memory accounts = abi.decode(parameters[0], (address[]));
        if (accounts.length == 0) revert InvalidParameters("expected at least 1 kyc account");

        if (getCredentialRequirementIds().length == 0) {
            revert CredentialRegistryAccountListValidatorPolicy__NoCredentialRequirementsConfigured();
        }

        for (uint256 i; i < accounts.length; ++i) {
            if (!validate(accounts[i], context)) {
                revert IPolicyEngine.PolicyRejected("account identity validation failed");
            }
        }

        policyResult = IPolicyEngine.PolicyResult.Continue;
    }
}
