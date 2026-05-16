// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CancelDeposit_EpochIntegrationTest is BaseIntegrationTest {
    function setUp() public override {
        super.setUp();
        _deployParent();
        _registerKyc(i_depositor);
    }

    function test_Epoch_cancelDeposit_ReturnsNetUsdcAndClearsDeposit() external {
        (uint256 netAmount,) = parent.vault.getNetAmountAndOperationFee(DEPOSIT_AMOUNT);

        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        uint256 usdcBefore = IERC20(parent.usdc).balanceOf(i_depositor);

        parent.vault.cancelDeposit();

        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), usdcBefore + netAmount);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
