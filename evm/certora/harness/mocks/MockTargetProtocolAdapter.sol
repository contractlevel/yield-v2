// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MockProtocolAdapter} from "./MockProtocolAdapter.sol";

/// @notice A distinct valid adapter instance for local-to-local ParentVault verification.
contract MockTargetProtocolAdapter is MockProtocolAdapter {
    constructor(address vault, address asset) MockProtocolAdapter(vault, asset) {}
}
