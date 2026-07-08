// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IShare} from "../../interfaces/IShare.sol";

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";

/// @title YieldcoinShareFrozenAccountPolicy
/// @author @contractlevel
/// @notice Rejects actions for accounts frozen on the YieldcoinShare ERC-3643 token.
contract YieldcoinShareFrozenAccountPolicy is Policy {
    /// @dev Thrown when the zero address is provided for required configuration
    error YieldcoinShareFrozenAccountPolicy__NoZeroAddress();

    /// @notice The type and version of the policy
    string public constant override typeAndVersion = "YieldcoinShareFrozenAccountPolicy 1.0.0";

    /// @dev Yieldcoin (YIELD) share token used as the freeze source of truth
    IShare internal immutable i_share;

    constructor(address share) {
        if (share == address(0)) revert YieldcoinShareFrozenAccountPolicy__NoZeroAddress();
        i_share = IShare(share);
    }

    /// @notice Returns the YieldcoinShare token used as the freeze source of truth
    /// @return share The YieldcoinShare token address
    function getShare() external view returns (address share) {
        share = address(i_share);
    }

    /// @notice Rejects when the extracted account is frozen on YieldcoinShare.
    /// @param parameters Policy parameters; expects exactly one `abi.encode(address)` item
    /// @return The policy result, `Continue` when the account is not frozen
    function run(address, address, bytes4, bytes[] calldata parameters, bytes calldata)
        public
        view
        override
        returns (IPolicyEngine.PolicyResult)
    {
        if (parameters.length != 1) revert InvalidParameters("expected account");

        address account = abi.decode(parameters[0], (address));
        if (i_share.isFrozen(account)) revert IPolicyEngine.PolicyRejected("account is frozen");

        return IPolicyEngine.PolicyResult.Continue;
    }
}
