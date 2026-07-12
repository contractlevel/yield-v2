// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicy} from "@chainlink/policy-management/interfaces/IPolicy.sol";

/// @title Yieldcoin v2 YieldcoinShare Frozen Account Policy Interface
/// @author @contractlevel
/// @notice Interface for the YieldcoinShareFrozenAccountPolicy
interface IYieldcoinShareFrozenAccountPolicy is IPolicy {
    /// @dev Thrown when the zero address is provided for required configuration
    error YieldcoinShareFrozenAccountPolicy__NoZeroAddress();

    /// @notice Returns the YieldcoinShare token used as the freeze source of truth
    /// @return share The YieldcoinShare token address
    function getShare() external view returns (address share);
}
