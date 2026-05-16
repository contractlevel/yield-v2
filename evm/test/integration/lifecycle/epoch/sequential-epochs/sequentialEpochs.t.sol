// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../../src/libraries/Types.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

contract SequentialEpochs_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("sequential-epochs");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");

    uint256 private s_netA;
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
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, 0);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);
        s_netA = parent.share.balanceOf(i_depositor);
    }

    function test_Epoch_sequential_SharePriceUpdatesAndStateIsolated() external {
        deal(parent.usdc, s_aaveV3Pool, 2 * s_netA);

        _fundAndApproveUsdc(i_recipient1, DEPOSIT_AMOUNT * 2);
        _changePrank(i_recipient1);
        parent.vault.deposit(DEPOSIT_AMOUNT * 2);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 2, 2 * s_netA);

        _changePrank(i_recipient1);
        parent.vault.claimShares(2);

        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(uint256(parent.vault.getEpoch(3).status), uint256(Types.EpochStatus.OPEN));
        assertEq(parent.vault.getEpochNonce(), 3);
        assertEq(parent.share.balanceOf(i_depositor), s_netA);
        assertEq(parent.share.balanceOf(i_recipient1), s_netA);
        assertEq(parent.vault.getDepositAmount(i_depositor, 2), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 2), 0);
    }
}
