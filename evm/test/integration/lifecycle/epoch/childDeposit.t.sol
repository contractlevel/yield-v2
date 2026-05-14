// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChildDeposit_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("child-deposit-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");
    uint256 private constant TVL = 0;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();
    }

    function test_Epoch_childDeposit_ParentClaimableAfterLocalCcipSendToChild() external {
        address childPool = child.aaveV3Adapter.getProtocolPool();

        assertEq(parent.vault.getThisChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(child.vault.getThisChainSelector(), CHILD_CHAIN_SELECTOR);
        assertEq(child.vault.getParentChainSelector(), PARENT_CHAIN_SELECTOR);
        assertEq(parent.vault.getCrosschainVault(CHILD_CHAIN_SELECTOR), address(child.vault));
        assertEq(child.vault.getCrosschainVault(PARENT_CHAIN_SELECTOR), address(parent.vault));

        (uint256 netDepositAmount,) = parent.vault.getNetAmountAndOperationFee(DEPOSIT_AMOUNT);
        uint256 childPoolBalanceBefore = IERC20(parent.usdc).balanceOf(childPool);

        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 1, TVL);

        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.OPEN));
        assertEq(IERC20(parent.usdc).balanceOf(childPool), childPoolBalanceBefore + netDepositAmount);

        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        assertEq(parent.share.balanceOf(i_depositor), netDepositAmount);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
    }
}
