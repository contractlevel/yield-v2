// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant SEED_WORKFLOW_ID = keccak256("ccip-fork-child-withdraw-seed");
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-child-withdraw-close");
    bytes32 private constant WITHDRAW_WORKFLOW_ID = keccak256("ccip-fork-child-withdraw-execute");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);

        _selectArbitrumFork();
        _configureExecuteEpochWithdrawWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID);

        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_epochChildWithdraw_RoutesUsdcBackToParent() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);
        uint256 withdrawAmount = shareAmount * ASSET_PRECISION / YIELD_PRECISION;

        _selectBaseFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, withdrawAmount);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _selectArbitrumFork();
        _setArbitrumChildActiveAdapterToAaveV3();
        vm.warp(block.timestamp + 12 hours); // Avoid Aave rounding while keeping forked CCIP prices fresh.
        _executeEpochWithdrawThroughWorkflow(arbitrumChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, withdrawAmount);
        _routeUsdcMessageTo(baseFork);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertApproxEqAbs(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + withdrawAmount, 1);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }

    function test_CcipFork_epochChildWithdraw_RoutesPolygonUsdcBackToParent() external {
        _setParentRemoteStrategyToPolygon();
        _setPolygonChildActiveAdapterToAaveV3();
        _configureExecuteEpochWithdrawWorkflow(polygonChild.workflowRouter, WITHDRAW_WORKFLOW_ID);

        _fundAndApproveParentUsdc(i_depositor, REMOTE_WITHDRAW_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(REMOTE_WITHDRAW_AMOUNT);
        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(SEED_WORKFLOW_ID, 0);
        _setPolygonChildActiveAdapterToAaveV3();
        _selectBaseFork();
        _routeUsdcMessageTo(polygonFork);
        _completeEpochDepositThroughWorkflow(SEED_WORKFLOW_ID, 1, REMOTE_WITHDRAW_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        uint256 shareAmount = REMOTE_WITHDRAW_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        uint256 withdrawAmount = shareAmount * ASSET_PRECISION / YIELD_PRECISION;

        _selectBaseFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, withdrawAmount);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _selectPolygonFork();
        _setPolygonChildActiveAdapterToAaveV3();
        vm.warp(block.timestamp + 12 hours); // Avoid Aave rounding while keeping forked CCIP prices fresh.
        _executeEpochWithdrawThroughWorkflow(polygonChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, withdrawAmount);
        _routeUsdcMessageTo(baseFork);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertApproxEqAbs(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + withdrawAmount, 1);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }
}
