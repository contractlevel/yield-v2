// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";

/// @title TerminalAllowPolicy
/// @author @contractlevel
/// @notice Final policy in a fail-closed ACE policy chain
/// @dev ACE policies such as KYC checks may return `Continue` after successful validation,
///      which means "keep evaluating" rather than "allow execution". This policy is attached
///      last to return `Allowed` only after all earlier policies have passed. It allows the
///      PolicyEngine to keep `defaultPolicyAllow` set to false, so missing or misconfigured
///      policy chains reject by default instead of silently bypassing compliance checks.
/// @dev This policy MUST be attached last.
contract TerminalAllowPolicy is Policy {
    /// @notice The type and version of the policy
    string public constant override typeAndVersion = "TerminalAllowPolicy 1.0.0";

    /// @notice Explicitly allows execution after all earlier policies in the chain have passed
    /// @param parameters Policy parameters; expects an empty array because this policy performs no validation
    /// @return allowed `Allowed`, which terminates policy evaluation and permits the protected call
    /// @dev This policy MUST be attached last. It expects no parameters because it performs no
    ///      validation itself; validation belongs in earlier policies. Returning `Allowed` here
    ///      prevents successful `Continue`-only policy chains from falling through to the
    ///      PolicyEngine default rule.
    /// @dev The unnamed `IPolicy.run` parameters (caller, subject, selector, context) are unused; only
    ///      `parameters` is checked.
    /// @dev Reverts if parameters is not empty
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata)
        public
        pure
        override
        returns (IPolicyEngine.PolicyResult allowed)
    {
        if (parameters.length != 0) revert InvalidParameters("expected 0 parameters");
        allowed = IPolicyEngine.PolicyResult.Allowed;
    }
}
