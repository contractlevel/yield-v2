// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

contract SequentialEpochs_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("sequential-epochs");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");
    uint256 private constant PERFORMANCE_FEE_BPS = 777;
    uint256 private constant BPS_DENOMINATOR = 10_000;

    uint256 private s_sharesA;
    address private s_aaveV3Pool;

    function setUp() public override {
        super.setUp();
        _deployParent();
        _registerKyc(i_depositor);
        _registerKyc(i_recipient1);
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        s_aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();

        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);
        s_sharesA = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
    }

    function test_Epoch_sequential_MultipleUsersClaimCorrectSharesAcrossEpochs() external {
        uint256 epochTwoTvl = DEPOSIT_AMOUNT * 2;
        uint256 epochTwoDeposit = DEPOSIT_AMOUNT * 2;
        deal(parent.asset, s_aaveV3Pool, epochTwoTvl);

        _fundAndApproveUsdc(i_recipient1, epochTwoDeposit);
        _changePrank(i_recipient1);
        parent.vault.deposit(epochTwoDeposit);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, epochTwoTvl);

        uint256 grossPricePerShare = epochTwoTvl * YIELD_PRECISION / s_sharesA;
        uint256 yieldAmount = (grossPricePerShare - ASSET_PRECISION) * s_sharesA / YIELD_PRECISION;
        uint256 performanceFee = _mulDivUp(yieldAmount, PERFORMANCE_FEE_BPS, BPS_DENOMINATOR);
        uint256 feeShares = _mulDivUp(performanceFee, s_sharesA, epochTwoTvl - performanceFee);
        uint256 expectedPricePerShare = epochTwoTvl * YIELD_PRECISION / (s_sharesA + feeShares);
        uint256 expectedRecipientShares = epochTwoDeposit * (s_sharesA + feeShares) / epochTwoTvl;

        _changePrank(i_recipient1);
        parent.vault.claimShares(2);

        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(parent.vault.getEpoch(2).pricePerShare, expectedPricePerShare);
        assertEq(parent.share.balanceOf(i_depositor), s_sharesA);
        assertEq(parent.share.balanceOf(i_recipient1), expectedRecipientShares);
        assertEq(parent.vault.getDepositAmount(i_depositor, 2), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 2), 0);
    }

    function _mulDivUp(uint256 x, uint256 y, uint256 denominator) private pure returns (uint256) {
        return (x * y + denominator - 1) / denominator;
    }
}
