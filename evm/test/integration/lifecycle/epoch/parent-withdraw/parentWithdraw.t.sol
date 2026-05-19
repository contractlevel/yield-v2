// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ParentWithdraw_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("parent-withdraw-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");

    uint256 private s_shareAmount;
    address private s_aaveV3Pool;

    function setUp() public override {
        super.setUp();
        _deployParent();

        s_aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();
        _registerKyc(i_depositor);
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        s_shareAmount = _depositAndClaimShares();
    }

    function test_Epoch_parentWithdraw_ClosesThroughWorkflowRouterAndDepositorClaimsUsdc() external {
        deal(parent.usdc, s_aaveV3Pool, s_shareAmount);
        MockAaveV3Pool(s_aaveV3Pool).setWithdrawReturn(s_shareAmount);

        _approveShares(i_depositor, address(parent.vault), s_shareAmount);

        _changePrank(i_depositor);
        parent.vault.withdraw(s_shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 2, s_shareAmount);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));

        uint256 depositorUsdcBeforeClaim = IERC20(parent.usdc).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimUsdc(2);

        assertEq(IERC20(parent.usdc).balanceOf(i_depositor), depositorUsdcBeforeClaim + s_shareAmount);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }

    function _depositAndClaimShares() private returns (uint256 shareAmount) {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        return DEPOSIT_AMOUNT;
    }
}
