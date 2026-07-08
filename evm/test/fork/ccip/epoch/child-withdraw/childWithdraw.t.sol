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
        _selectArbitrumFork();
        _configureCloseEpochWorkflow(SEED_WORKFLOW_ID);
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);

        _selectBaseFork();
        _configureExecuteEpochWithdrawWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID);

        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_epochChildWithdraw_RoutesUsdcBackToParent() external {
        uint256 shareAmount = _depositAndClaimParentShares(SEED_WORKFLOW_ID);

        _selectArbitrumFork();
        _approveShares(i_depositor, shareAmount);
        _changePrank(i_depositor);
        parent.vault.withdraw(shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, shareAmount);

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));

        _selectBaseFork();
        _setBaseChildActiveAdapterToAaveV3();
        vm.warp(block.timestamp + 1 days); // skip time to avoid aToken rounding at 1 USDC scale
        _executeEpochWithdrawThroughWorkflow(baseChild.workflowRouter, WITHDRAW_WORKFLOW_ID, 2, shareAmount);
        _routeUsdcMessageTo(arbitrumFork);

        _selectArbitrumFork();
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBefore = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertEq(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBefore + shareAmount);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }
}
