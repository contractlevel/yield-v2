// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MockAaveV4Spoke} from "./MockAaveV4Spoke.sol";
import {IAaveV4Adapter} from "../../../../../src/interfaces/adapters/IAaveV4Adapter.sol";

contract MockAaveV4InvalidSharesSpoke is MockAaveV4Spoke {
    constructor(address underlying, address hub, uint16 hubAssetId) MockAaveV4Spoke(underlying, hub, hubAssetId) {}

    function _revertSupply() internal pure override {
        revert IAaveV4Adapter.InvalidShares();
    }
}
