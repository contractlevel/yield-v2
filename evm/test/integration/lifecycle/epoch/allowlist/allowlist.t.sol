// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../../BaseIntegrationTest.t.sol";

import {DeployParent} from "../../../../../script/deploy/DeployParent.s.sol";
import {IAllowlist} from "../../../../../src/interfaces/modules/IAllowlist.sol";
import {MockAaveV3Pool} from "../../../../mocks/MockAaveV3Pool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Allowlist_EpochIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("allowlist-epoch");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");

    function setUp() public override {
        super.setUp();
        networkConfig.allowlist.enabled = true;
        networkConfig.allowlist.initialUsers = new address[](2);
        networkConfig.allowlist.initialUsers[0] = i_depositor;
        networkConfig.allowlist.initialUsers[1] = i_recipient1;

        DeployParent deployer = new DeployParent();
        parent = _parentFromDeployment(deployer.deployWithConfig(networkConfig, address(deployer)));
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
    }

    function test_Epoch_allowlist_SeededDepositorClaimsShares() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _closeEpoch(0);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(parent.share.balanceOf(i_depositor), expectedShares);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
        assertEq(IERC20(parent.asset).balanceOf(i_depositor), 0);
    }

    function test_Epoch_allowlist_SeededBeneficiaryClaimsSponsoredDeposit() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.depositFor(i_recipient1, DEPOSIT_AMOUNT);

        _closeEpoch(0);
        _changePrank(i_recipient1);
        parent.vault.claimShares(1);

        uint256 expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        assertEq(parent.share.balanceOf(i_recipient1), expectedShares);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(IERC20(parent.asset).balanceOf(i_depositor), 0);
    }

    function test_Epoch_allowlist_RevertWhen_DepositorNotAllowlisted() external {
        _fundAndApproveUsdc(i_recipient2, DEPOSIT_AMOUNT);
        _changePrank(i_recipient2);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_recipient2));
        parent.vault.deposit(DEPOSIT_AMOUNT);

        assertEq(IERC20(parent.asset).balanceOf(i_recipient2), DEPOSIT_AMOUNT);
        assertEq(IERC20(parent.asset).balanceOf(address(parent.vault)), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient2, 1), 0);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, 0);
    }

    function test_Epoch_allowlist_RevertWhen_SponsorNotAllowlisted() external {
        _fundAndApproveUsdc(i_recipient2, DEPOSIT_AMOUNT);
        _changePrank(i_recipient2);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_recipient2));
        parent.vault.depositFor(i_recipient1, DEPOSIT_AMOUNT);

        assertEq(IERC20(parent.asset).balanceOf(i_recipient2), DEPOSIT_AMOUNT);
        assertEq(IERC20(parent.asset).balanceOf(address(parent.vault)), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, 0);
    }

    function test_Epoch_allowlist_RevertWhen_BeneficiaryNotAllowlisted() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);

        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_recipient2));
        parent.vault.depositFor(i_recipient2, DEPOSIT_AMOUNT);

        assertEq(IERC20(parent.asset).balanceOf(i_depositor), DEPOSIT_AMOUNT);
        assertEq(IERC20(parent.asset).balanceOf(address(parent.vault)), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient2, 1), 0);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, 0);
    }

    function test_Epoch_allowlist_RemovedDepositorCancelsExistingDeposit() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT * 2);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);
        _setAllowlistedUser(i_depositor, false);

        _changePrank(i_depositor);
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_depositor));
        parent.vault.deposit(DEPOSIT_AMOUNT);

        assertEq(parent.vault.getDepositAmount(i_depositor, 1), DEPOSIT_AMOUNT);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, DEPOSIT_AMOUNT);
        parent.vault.cancelDeposit();

        assertEq(IERC20(parent.asset).balanceOf(i_depositor), DEPOSIT_AMOUNT * 2);
        assertEq(parent.vault.getDepositAmount(i_depositor, 1), 0);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, 0);
        assertTrue(parent.vault.getAllowlistEnabled());
    }

    function test_Epoch_allowlist_RemovedBeneficiaryCancelsSponsoredDeposit() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT * 2);
        _changePrank(i_depositor);
        parent.vault.depositFor(i_recipient1, DEPOSIT_AMOUNT);
        _setAllowlistedUser(i_recipient1, false);

        _changePrank(i_depositor);
        vm.expectRevert(abi.encodeWithSelector(IAllowlist.Allowlist__UserNotAllowlisted.selector, i_recipient1));
        parent.vault.depositFor(i_recipient1, DEPOSIT_AMOUNT);

        _changePrank(i_recipient1);
        parent.vault.cancelDeposit();

        assertEq(IERC20(parent.asset).balanceOf(i_recipient1), DEPOSIT_AMOUNT);
        assertEq(IERC20(parent.asset).balanceOf(i_depositor), DEPOSIT_AMOUNT);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(parent.vault.getEpoch(1).totalDepositAmount, 0);
        assertTrue(parent.vault.getAllowlistEnabled());
    }

    function test_Epoch_allowlist_RemovedBeneficiaryClaimsSharesAndWithdraws() external {
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.depositFor(i_recipient1, DEPOSIT_AMOUNT);
        _setAllowlistedUser(i_depositor, false);
        _setAllowlistedUser(i_recipient1, false);

        _closeEpoch(0);
        _changePrank(i_recipient1);
        uint256 shareAmount = parent.vault.claimShares(1);
        assertEq(shareAmount, DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION);

        address aaveV3Pool = parent.aaveV3Adapter.getProtocolPool();
        deal(parent.asset, aaveV3Pool, DEPOSIT_AMOUNT);
        MockAaveV3Pool(aaveV3Pool).setWithdrawReturn(DEPOSIT_AMOUNT);
        _approveShares(i_recipient1, address(parent.vault), shareAmount);

        _changePrank(i_recipient1);
        parent.vault.withdraw(shareAmount);

        _closeEpoch(DEPOSIT_AMOUNT);
        _changePrank(i_recipient1);
        parent.vault.claimAsset(2);

        assertEq(IERC20(parent.asset).balanceOf(i_recipient1), DEPOSIT_AMOUNT);
        assertEq(parent.share.balanceOf(i_recipient1), 0);
        assertEq(parent.share.balanceOf(i_depositor), 0);
        assertEq(parent.vault.getDepositAmount(i_recipient1, 1), 0);
        assertEq(parent.vault.getWithdrawShareBurnAmount(i_recipient1, 2), 0);
        assertEq(parent.vault.getTotalShares(), 0);
        assertTrue(parent.vault.getAllowlistEnabled());
        assertFalse(parent.vault.getAllowlistedUser(i_recipient1));
    }

    function _setAllowlistedUser(address user, bool allowed) private {
        _changePrank(networkConfig.roles.allowlistOperator);
        address[] memory users = new address[](1);
        users[0] = user;
        parent.vault.setAllowlistedUsers(users, allowed);
    }

    function _closeEpoch(uint256 tvl) private {
        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, tvl);
    }
}
