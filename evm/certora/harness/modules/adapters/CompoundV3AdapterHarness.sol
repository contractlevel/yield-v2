// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {MockComet} from "./mocks/MockComet.sol";

contract CompoundV3AdapterHarness is CompoundV3Adapter, HelperHarness {
    constructor(address vault, address comet, address cometRewards) CompoundV3Adapter(vault, comet, cometRewards) {}

    function mockDepositDecreasesTVL() external view returns (bool) {
        return MockComet(i_comet).s_decreaseTVLOnSupply();
    }

    function mockDepositTVLChange() external view returns (uint256) {
        return MockComet(i_comet).s_supplyTVLChange();
    }

    function mockWithdrawAmount() external view returns (uint256) {
        return MockComet(i_comet).s_withdrawAmount();
    }
}
