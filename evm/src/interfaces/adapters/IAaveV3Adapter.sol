// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "./IProtocolAdapter.sol";

/// @title Yieldcoin v2 Aave v3 Adapter Interface
/// @author @contractlevel
/// @notice Interface for Aave v3-specific adapter behavior
interface IAaveV3Adapter is IProtocolAdapter {
    /// @notice Gets the address of the Aave v3 pool addresses provider
    /// @return poolAddressesProvider The address of the Aave v3 pool addresses provider
    function getPoolAddressesProvider() external view returns (address poolAddressesProvider);
}
