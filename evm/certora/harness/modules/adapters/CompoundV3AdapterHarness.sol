// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";

contract CompoundV3AdapterHarness is CompoundV3Adapter, HelperHarness {
    constructor(address vault, address comet, address cometRewards)
        CompoundV3Adapter(vault, comet, cometRewards)
    {}
}
