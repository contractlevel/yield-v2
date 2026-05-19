// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiUser_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("multi-user-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");
    uint256 private constant DEPOSIT_AMOUNT_B = DEPOSIT_AMOUNT * 2;

    function setUp() public override {
        super.setUp();
        _deployParent();
        _registerKyc(i_depositor);
        _registerKyc(i_recipient1);
        _registerKyc(i_withdrawer);
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
    }

    function test_Epoch_multiUser_TwoDepositors_EachClaimProportionalShares() external {
        address aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();
        uint256 poolBalanceBefore = IERC20(parent.usdc).balanceOf(aaveV3Pool);

        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _fundAndApproveUsdc(i_recipient1, DEPOSIT_AMOUNT_B);
        _changePrank(i_recipient1);
        parent.vault.deposit(DEPOSIT_AMOUNT_B);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, 0);

        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.OPEN));
        assertEq(parent.vault.getTotalShares(), DEPOSIT_AMOUNT + DEPOSIT_AMOUNT_B);
        assertEq(IERC20(parent.usdc).balanceOf(aaveV3Pool), poolBalanceBefore + DEPOSIT_AMOUNT + DEPOSIT_AMOUNT_B);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        _changePrank(i_recipient1);
        parent.vault.claimShares(1);

        assertEq(parent.share.balanceOf(i_depositor), DEPOSIT_AMOUNT);
        assertEq(parent.share.balanceOf(i_recipient1), DEPOSIT_AMOUNT_B);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
    }

    function test_Epoch_multiUser_TwoWithdrawers_EachClaimProportionalUsdc() external {
        (uint256 sharesA, uint256 sharesB) = _seedBothWithdrawers();
        uint256 tvl = sharesA + sharesB;
        address aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();

        _approveShares(i_depositor, address(parent.vault), sharesA);
        _changePrank(i_depositor);
        parent.vault.withdraw(sharesA);

        _approveShares(i_withdrawer, address(parent.vault), sharesB);
        _changePrank(i_withdrawer);
        parent.vault.withdraw(sharesB);

        deal(parent.usdc, aaveV3Pool, tvl);
        MockAaveV3Pool(aaveV3Pool).setWithdrawReturn(tvl);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 2, tvl);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));

        uint256 depositorUsdcBefore = IERC20(parent.usdc).balanceOf(i_depositor);
        uint256 withdrawerUsdcBefore = IERC20(parent.usdc).balanceOf(i_withdrawer);

        _changePrank(i_depositor);
        parent.vault.claimUsdc(2);

        _changePrank(i_withdrawer);
        parent.vault.claimUsdc(2);

        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBefore + sharesA);
        assertEq(IERC20(parent.usdc).balanceOf(i_withdrawer), withdrawerUsdcBefore + sharesB);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.share.balanceOf(i_withdrawer), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_withdrawer, 2), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }

    function test_Epoch_multiUser_DepositorAndWithdrawer_BothClaimInSameEpoch() external {
        uint256 withdrawerShares = _seedWithdrawerShares();

        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT_B);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT_B);

        _approveShares(i_withdrawer, address(parent.vault), withdrawerShares);
        _changePrank(i_withdrawer);
        parent.vault.withdraw(withdrawerShares);

        uint256 withdrawerUsdcBefore = IERC20(parent.usdc).balanceOf(i_withdrawer);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 2, withdrawerShares);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));

        _changePrank(i_depositor);
        parent.vault.claimShares(2);

        _changePrank(i_withdrawer);
        parent.vault.claimUsdc(2);

        assertEq(parent.share.balanceOf(i_depositor), DEPOSIT_AMOUNT_B);
        assertEq(parent.vault.getDepositAmount(i_depositor, 2), 0);
        assertEq(IERC20(parent.usdc).balanceOf(i_withdrawer), withdrawerUsdcBefore + withdrawerShares);
        assertEq(parent.share.balanceOf(i_withdrawer), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_withdrawer, 2), 0);
    }

    function _seedBothWithdrawers() private returns (uint256 sharesA, uint256 sharesB) {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _fundAndApproveUsdc(i_withdrawer, DEPOSIT_AMOUNT_B);
        _changePrank(i_withdrawer);
        parent.vault.deposit(DEPOSIT_AMOUNT_B);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        _changePrank(i_withdrawer);
        parent.vault.claimShares(1);

        return (DEPOSIT_AMOUNT, DEPOSIT_AMOUNT_B);
    }

    function _seedWithdrawerShares() private returns (uint256 shares) {
        _fundAndApproveUsdc(i_withdrawer, DEPOSIT_AMOUNT);
        _changePrank(i_withdrawer);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, 0);

        _changePrank(i_withdrawer);
        parent.vault.claimShares(1);

        return DEPOSIT_AMOUNT;
    }
}
