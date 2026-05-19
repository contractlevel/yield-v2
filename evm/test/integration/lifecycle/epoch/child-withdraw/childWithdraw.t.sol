// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant PARENT_WORKFLOW_ID = keccak256("child-withdraw-parent-epoch");
    bytes32 private constant CHILD_WORKFLOW_ID = keccak256("child-withdraw-child-epoch");
    bytes10 private constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 private constant EXECUTE_WITHDRAW_WORKFLOW_NAME = bytes10("epochDraw");

    uint256 private s_shareAmount;
    address private s_childAaveV3Pool;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();

        s_childAaveV3Pool = child.aaveV3Adapter.getProtocolPool();
        _registerKyc(i_depositor);
        _configureCloseEpochWorkflow(parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _configureExecuteEpochWithdrawWorkflow(
            child.workflowRouter, CHILD_WORKFLOW_ID, EXECUTE_WITHDRAW_WORKFLOW_NAME, i_owner
        );
        s_shareAmount = _depositAndClaimShares();

        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();
    }

    function test_Epoch_childWithdraw_ParentClaimableAfterRemoteWithdrawSettles() external {
        _approveShares(i_depositor, address(parent.vault), s_shareAmount);

        _changePrank(i_depositor);
        parent.vault.withdraw(s_shareAmount);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 2, s_shareAmount
        );

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));

        deal(parent.usdc, s_childAaveV3Pool, s_shareAmount);
        MockAaveV3Pool(s_childAaveV3Pool).setWithdrawReturn(s_shareAmount);

        _executeEpochWithdrawThroughWorkflow(
            child.workflowRouter, CHILD_WORKFLOW_ID, EXECUTE_WITHDRAW_WORKFLOW_NAME, i_owner, 2, s_shareAmount
        );

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

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
        _closeEpochThroughWorkflow(parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 1, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        return DEPOSIT_AMOUNT;
    }
}
