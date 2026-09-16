// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {MockAaveV3Pool} from "./mocks/MockAaveV3Pool.sol";

contract AaveV3AdapterHarness is AaveV3Adapter, HelperHarness {
    constructor(address vault, address poolAddressesProvider) AaveV3Adapter(vault, poolAddressesProvider) {}

    function mockUsesBufferedAssets() external pure returns (bool) {
        return true;
    }

    function mockDepositCanSupply(uint256 amount) external view returns (bool) {
        MockAaveV3Pool pool = MockAaveV3Pool(_getAavePool());
        uint256 index = pool.s_reserveNormalizedIncome();
        return !pool.s_normalizedIncomeReverts() && index != 0 && amount > (index - 1) / RAY;
    }

    function mockDepositCanBuffer(uint256 amount) external view returns (bool) {
        MockAaveV3Pool pool = MockAaveV3Pool(_getAavePool());
        uint256 index = pool.s_reserveNormalizedIncome();
        return !pool.s_normalizedIncomeReverts() && index != 0 && amount <= (index - 1) / RAY;
    }

    function mockDepositDecreasesTVL() external view returns (bool) {
        return MockAaveV3Pool(_getAavePool()).s_decreaseTVLOnSupply();
    }

    function mockDepositReverts() external view returns (bool) {
        return MockAaveV3Pool(_getAavePool()).s_supplyReverts();
    }

    function mockWithdrawReverts() external view returns (bool) {
        return MockAaveV3Pool(_getAavePool()).s_withdrawReverts();
    }

    function mockDepositTVLChange() external view returns (uint256) {
        return MockAaveV3Pool(_getAavePool()).s_supplyTVLChange();
    }

    function mockWithdrawAmount() external view returns (uint256) {
        return MockAaveV3Pool(_getAavePool()).s_withdrawAmount();
    }
}
