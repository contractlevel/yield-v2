// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ParentDeposit_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("parent-deposit-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");
    uint256 private constant TVL = 0;

    function setUp() public override {
        super.setUp();
        _deployParent();
    }

    function test_Epoch_parentDeposit_ClosesThroughWorkflowRouterAndDepositorClaimsShares() external {
        address aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();
        uint256 poolBalanceBefore = IERC20(parent.asset).balanceOf(aaveV3Pool);

        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, TVL);

        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.OPEN));
        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(parent.vault.getTotalShares(), expectedShares);
        assertEq(IERC20(parent.asset).balanceOf(aaveV3Pool), poolBalanceBefore + DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        assertEq(parent.share.balanceOf(i_depositor), expectedShares);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
