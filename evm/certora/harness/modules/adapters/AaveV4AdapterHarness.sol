// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";

contract AaveV4AdapterHarness is AaveV4Adapter, HelperHarness {
    constructor(address vault, address spoke) AaveV4Adapter(vault, spoke) {}
}
