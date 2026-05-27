// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV4Spoke} from "../../../../mocks/MockAaveV4Spoke.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoundTrip_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant CLOSE_EPOCH_WORKFLOW_ID = keccak256("round-trip-close-epoch");
    bytes32 private constant REBALANCE_WORKFLOW_ID = keccak256("round-trip-rebalance");
    bytes10 private constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 private constant REBALANCE_WORKFLOW_NAME = bytes10("rebalance");

    uint256 private constant BPS_DENOMINATOR = 10_000;
    uint256 private constant MANAGEMENT_FEE_BPS = 100;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _registerKyc(i_depositor);
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, REBALANCE_WORKFLOW_ID, REBALANCE_WORKFLOW_NAME, i_owner
        );
    }

    function test_Epoch_roundTrip_DepositorWithdrawsNextEpochNetOfManagementFeeAndRounding() external {
        uint256 initialRebalanceCompletedAt = parent.vault.getRebalance().lastRebalanceCompletedTimestamp;
        uint256 depositAmount = DEPOSIT_AMOUNT;

        _fundAndApproveUsdc(i_depositor, depositAmount);

        _changePrank(i_depositor);
        parent.vault.deposit(depositAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 0
        );

        _changePrank(i_depositor);
        uint256 shareAmount = parent.vault.claimShares(1);

        assertEq(shareAmount, depositAmount);
        assertEq(parent.share.balanceOf(i_depositor), shareAmount);

        _initiateRebalanceThroughWorkflow(
            parent.workflowRouter,
            REBALANCE_WORKFLOW_ID,
            REBALANCE_WORKFLOW_NAME,
            i_owner,
            _parentStrategy(AAVE_V4_PROTOCOL_ID)
        );

        uint256 feeShares = _expectedManagementFeeShares(shareAmount, block.timestamp - initialRebalanceCompletedAt);
        uint256 totalSharesAfterFee = shareAmount + feeShares;
        uint256 tvl = depositAmount;
        uint256 expectedPricePerShare = tvl * SHARE_PRECISION / totalSharesAfterFee;
        uint256 expectedUsdcOut = shareAmount * expectedPricePerShare / SHARE_PRECISION;

        address aaveV4Spoke = parent.aaveV4Adapter.getProtocolPool();
        MockAaveV4Spoke(aaveV4Spoke).setWithdrawReturn(expectedUsdcOut);

        _approveShares(i_depositor, address(parent.vault), shareAmount);

        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, tvl
        );

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpoch(2).pricePerShare, expectedPricePerShare);
        assertEq(parent.vault.getEpoch(2).totalWithdrawClaimAmount, expectedUsdcOut);

        uint256 depositorUsdcBeforeClaim = IERC20(parent.usdc).balanceOf(i_depositor);

        _changePrank(i_depositor);
        uint256 usdcOut = parent.vault.claimUsdc(2);

        assertEq(usdcOut, expectedUsdcOut);
        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBeforeClaim + expectedUsdcOut);
        assertLe(usdcOut, depositAmount);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
    }

    function _expectedManagementFeeShares(uint256 totalShares, uint256 elapsed) internal pure returns (uint256) {
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        return (totalShares * MANAGEMENT_FEE_BPS * elapsed + denominator - 1) / denominator;
    }
}
