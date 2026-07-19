// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicy} from "@chainlink/policy-management/interfaces/IPolicy.sol";

/// @title Yieldcoin v2 CredentialRegistryAccountListValidatorPolicy Interface
/// @author @contractlevel
/// @notice Interface for the CredentialRegistryAccountListValidatorPolicy
interface ICredentialRegistryAccountListValidatorPolicy is IPolicy {
    /// @dev Thrown when no credential requirements are configured
    error CredentialRegistryAccountListValidatorPolicy__NoCredentialRequirementsConfigured();
}
