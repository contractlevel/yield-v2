// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {HelperHarness} from "../../HelperHarness.sol";

import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";

contract AaveV3AdapterHarness is AaveV3Adapter, HelperHarness {
    constructor(address vault, address poolAddressesProvider) AaveV3Adapter(vault, poolAddressesProvider) {}
}
