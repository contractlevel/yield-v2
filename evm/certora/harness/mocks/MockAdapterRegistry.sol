// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IAdapterRegistry} from "../../../src/interfaces/IAdapterRegistry.sol";

contract MockAdapterRegistry is IAdapterRegistry {
    mapping(bytes32 protocolId => address adapter) internal s_adapters;

    function setAdapter(bytes32 protocolId, address adapter) external {
        s_adapters[protocolId] = adapter;
        emit AdapterSet(protocolId, adapter);
    }

    function getAdapter(bytes32 protocolId) external view returns (address adapter) {
        adapter = s_adapters[protocolId];
    }
}
