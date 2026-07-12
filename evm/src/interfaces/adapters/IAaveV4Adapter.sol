// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "./IProtocolAdapter.sol";

/// @title Yieldcoin v2 Aave v4 Adapter Interface
/// @author @contractlevel
/// @notice Interface for Aave v4-specific adapter behavior
interface IAaveV4Adapter is IProtocolAdapter {
    /// @dev Thrown when the configured asset token is listed more than once on the Spoke
    error AaveV4Adapter__DuplicateReserveFound();

    /// @notice Gets the Aave v4 reserve id for the underlying asset on the Spoke
    /// @return reserveId The Aave v4 reserve id
    function getReserveId() external view returns (uint256 reserveId);
}
