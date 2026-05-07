// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

contract ParentVault_GetNetAmountAndOperationFeeUnitTest is BaseUnitTest {
    uint256 internal constant AMOUNT = 1_000 * 1e6;
    uint256 internal constant OPERATION_FEE_BPS = 100;
    uint256 internal constant BPS_DENOMINATOR = 100_000;

    function test_ParentVault_getNetAmountAndOperationFee_ReturnsNetAmountAndOperationFee() public view {
        uint256 expectedFee = (AMOUNT * OPERATION_FEE_BPS + BPS_DENOMINATOR - 1) / BPS_DENOMINATOR;

        (uint256 netAmount, uint256 fee) = s_parentVault.getNetAmountAndOperationFee(AMOUNT);

        assertEq(netAmount, AMOUNT - expectedFee);
        assertEq(fee, expectedFee);
    }
}
