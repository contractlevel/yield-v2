// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {MockAaveV4Spoke} from "./mocks/MockAaveV4Spoke.sol";

contract AaveV4AdapterHarness is AaveV4Adapter, HelperHarness {
    constructor(address vault, address spoke) AaveV4Adapter(vault, spoke) {}

    function mockDepositDecreasesTVL() external view returns (bool) {
        return MockAaveV4Spoke(i_spoke).s_decreaseTVLOnSupply();
    }

    function mockDepositTVLChange() external view returns (uint256) {
        return MockAaveV4Spoke(i_spoke).s_supplyTVLChange();
    }

    function mockWithdrawAmount() external view returns (uint256) {
        return MockAaveV4Spoke(i_spoke).s_withdrawAmount();
    }
}
