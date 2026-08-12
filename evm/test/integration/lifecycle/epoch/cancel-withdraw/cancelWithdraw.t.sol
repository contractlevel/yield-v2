// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

contract CancelWithdraw_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("cancel-withdraw-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");

    uint256 private s_shareAmount;

    function setUp() public override {
        super.setUp();
        _deployParent();
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        s_shareAmount = _depositAndClaimShares();
    }

    function test_Epoch_cancelWithdraw_ReturnsSharesAndClearsBurnRequest() external {
        _approveShares(i_depositor, address(parent.vault), s_shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(s_shareAmount);

        parent.vault.cancelWithdraw();

        assertEq(parent.share.balanceOf(i_depositor), s_shareAmount);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
    }

    function _depositAndClaimShares() private returns (uint256 shareAmount) {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        shareAmount = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
    }
}
