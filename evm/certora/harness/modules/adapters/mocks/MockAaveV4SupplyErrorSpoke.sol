// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MockAaveV4Spoke} from "./MockAaveV4Spoke.sol";
import {IAaveV4Adapter} from "../../../../../src/interfaces/adapters/IAaveV4Adapter.sol";

contract MockAaveV4SupplyErrorSpoke is MockAaveV4Spoke {
    error SupplyFailed();

    uint8 internal s_supplyErrorMode;
    bytes3 internal s_shortErrorPrefix;
    uint8 internal s_shortErrorLength;

    constructor(address underlying, address hub, uint16 hubAssetId) MockAaveV4Spoke(underlying, hub, hubAssetId) {}

    function setSupplyError(uint8 mode, bytes3 prefix, uint8 length) external {
        require(mode <= 2 && length < 4);
        s_supplyErrorMode = mode;
        s_shortErrorPrefix = prefix;
        s_shortErrorLength = length;
    }

    function _revertSupply() internal view override {
        if (s_supplyErrorMode == 0) revert SupplyFailed();
        if (s_supplyErrorMode == 1) {
            bytes4 selector = IAaveV4Adapter.InvalidShares.selector;
            assembly ("memory-safe") {
                mstore(0, selector)
                revert(0, 5)
            }
        }
        bytes3 prefix = s_shortErrorPrefix;
        uint8 length = s_shortErrorLength;
        assembly ("memory-safe") {
            mstore(0, prefix)
            revert(0, length)
        }
    }
}
