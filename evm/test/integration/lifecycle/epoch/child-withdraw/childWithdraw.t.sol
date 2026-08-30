// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAToken} from "../../../../mocks/MockAToken.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildWithdraw_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant PARENT_WORKFLOW_ID = keccak256("child-withdraw-parent-epoch");
    bytes32 private constant CHILD_WORKFLOW_ID = keccak256("child-withdraw-child-epoch");
    bytes10 private constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 private constant EXECUTE_WITHDRAW_WORKFLOW_NAME = bytes10("epochDraw");
    uint256 private constant REMOTE_DEPOSIT_AMOUNT = 100 * ASSET_PRECISION;

    uint256 private s_shareAmount;
    address private s_childAaveV3Pool;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();

        s_childAaveV3Pool = child.aaveV3Adapter.getProtocolPool();
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
            parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, REMOTE_DEPOSIT_AMOUNT
        );

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.EXECUTING));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));

        MockAToken(MockAaveV3Pool(s_childAaveV3Pool).getReserveData(parent.asset).aTokenAddress)
            .mint(address(child.aaveV3Adapter), REMOTE_DEPOSIT_AMOUNT);
        deal(parent.asset, s_childAaveV3Pool, REMOTE_DEPOSIT_AMOUNT);
        MockAaveV3Pool(s_childAaveV3Pool).setWithdrawReturn(REMOTE_DEPOSIT_AMOUNT);

        uint256 treasuryUsdcBeforeSettlement = IERC20(parent.asset).balanceOf(networkConfig.treasury);

        _executeEpochWithdrawThroughWorkflow(
            child.workflowRouter, CHILD_WORKFLOW_ID, EXECUTE_WITHDRAW_WORKFLOW_NAME, i_owner, 2, REMOTE_DEPOSIT_AMOUNT
        );

        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));

        uint256 depositorUsdcBeforeClaim = IERC20(parent.asset).balanceOf(i_depositor);

        _changePrank(i_depositor);
        parent.vault.claimAsset(2);

        assertEq(
            IERC20(parent.asset).balanceOf(i_depositor),
            depositorUsdcBeforeClaim + REMOTE_DEPOSIT_AMOUNT - parent.vault.getMinAssetAmount()
        );
        assertEq(
            IERC20(parent.asset).balanceOf(networkConfig.treasury),
            treasuryUsdcBeforeSettlement + parent.vault.getMinAssetAmount()
        );
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, 2), 0);
        assertEq(parent.vault.getTotalShares(), 0);
    }

    function test_Epoch_childWithdraw_RepeatedRemoteDustClosesWithoutChildExecution() external {
        uint256 minAssetAmount = parent.vault.getMinAssetAmount();
        uint256 childLinkBalance = local.link.balanceOf(address(child.vault));
        uint256 totalDustSharesBurned;

        _approveShares(i_depositor, address(parent.vault), s_shareAmount);

        for (uint256 epochNonce = 2; epochNonce < 5; ++epochNonce) {
            uint256 dustShareAmount = minAssetAmount * parent.vault.getTotalShares() / REMOTE_DEPOSIT_AMOUNT;
            totalDustSharesBurned += dustShareAmount;
            _changePrank(i_depositor);
            parent.vault.withdraw(dustShareAmount);

            _warpPastMinEpoch();
            _closeEpochThroughWorkflow(
                parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, REMOTE_DEPOSIT_AMOUNT
            );

            assertEq(uint256(parent.vault.getEpoch(epochNonce).status), uint256(Types.EpochStatus.CLAIMABLE));
            assertEq(parent.vault.getEpoch(epochNonce).totalWithdrawClaimAmount, 0);
            assertEq(parent.vault.getEpochNonce(), epochNonce + 1);
            assertEq(local.link.balanceOf(address(child.vault)), childLinkBalance);

            uint256 depositorUsdcBeforeClaim = IERC20(parent.asset).balanceOf(i_depositor);
            _changePrank(i_depositor);
            parent.vault.claimAsset(epochNonce);

            assertEq(IERC20(parent.asset).balanceOf(i_depositor), depositorUsdcBeforeClaim);
            assertEq(parent.vault.getWithdrawShareBurnAmount(i_depositor, epochNonce), 0);
        }

        assertEq(parent.share.balanceOf(i_depositor), s_shareAmount - totalDustSharesBurned);
    }

    function _depositAndClaimShares() private returns (uint256 shareAmount) {
        _fundAndApproveUsdc(i_depositor, REMOTE_DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(REMOTE_DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, PARENT_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        shareAmount = REMOTE_DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
    }
}
