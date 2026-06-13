// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {HelperHarness} from "../HelperHarness.sol";

import {AdapterRegistry} from "../../../src/modules/AdapterRegistry.sol";

contract AdapterRegistryHarness is AdapterRegistry, HelperHarness {
    constructor(uint48 initialDelay, address initialOwner) AdapterRegistry(initialDelay, initialOwner) {}
}
