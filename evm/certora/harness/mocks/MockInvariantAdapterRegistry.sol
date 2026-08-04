// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IAdapterRegistry} from "../../../src/interfaces/modules/IAdapterRegistry.sol";

/// @notice Deterministic adapter registry for production-ABI invariant verification.
/// @dev Function-specific missing and invalid adapter behavior is verified with MockAdapterRegistry
///      in the harnessed rules target. This model keeps arbitrary successful calls resolvable.
contract MockInvariantAdapterRegistry is IAdapterRegistry {
    address internal immutable i_adapter;

    constructor(address adapter) {
        i_adapter = adapter;
    }

    function setAdapter(bytes32 protocolId, address) external {
        emit AdapterSet(protocolId, i_adapter);
    }

    function getAdapter(bytes32) external view returns (address adapter) {
        adapter = i_adapter;
    }
}
