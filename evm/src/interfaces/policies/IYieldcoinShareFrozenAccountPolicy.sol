// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicy} from "@chainlink/policy-management/interfaces/IPolicy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title Yieldcoin v2 YieldcoinShare Frozen Account Policy Interface
/// @author @contractlevel
/// @notice Interface for the YieldcoinShareFrozenAccountPolicy
interface IYieldcoinShareFrozenAccountPolicy is IPolicy {
    /// @dev Thrown when the zero address is provided for required configuration
    error YieldcoinShareFrozenAccountPolicy__NoZeroAddress();

    /// @notice Returns the YieldcoinShare token used as the freeze source of truth
    /// @return share The YieldcoinShare token address
    function getShare() external view returns (address share);

    /// @notice Rejects an action when the extracted account is frozen on YieldcoinShare
    /// @param parameters Policy parameters; expects exactly one `abi.encode(address)` item
    /// @return policyResult `Continue` when the account is not frozen
    /// @dev The caller, subject, selector, and context inputs are unused
    /// @dev Reverts if parameters does not contain exactly one item or the encoded account is malformed
    /// @dev Reverts with PolicyRejected if the account is frozen
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata)
        external
        view
        override
        returns (IPolicyEngine.PolicyResult policyResult);
}
