// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";

contract ParentVault_KycPolicyIntegrationTest is BaseIntegrationTest {
    uint256 private constant SHARE_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();
        _deployParent();
    }

    function test_ParentVault_deposit_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.deposit.selector);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.deposit(DEPOSIT_AMOUNT);
    }

    function test_ParentVault_deposit_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        assertGt(parent.vault.getDepositAmount(i_depositor, parent.vault.getEpochNonce()), 0);
    }

    function test_ParentVault_withdraw_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.withdraw.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.withdraw(SHARE_AMOUNT);
    }

    function test_ParentVault_withdraw_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_withdrawer);
        _mintShares(i_withdrawer, SHARE_AMOUNT);
        _approveShares(i_withdrawer, address(parent.vault), SHARE_AMOUNT);

        _changePrank(i_withdrawer);
        parent.vault.withdraw(SHARE_AMOUNT);

        assertEq(parent.vault.getWithdrawShareBurnAmount(i_withdrawer, parent.vault.getEpochNonce()), SHARE_AMOUNT);
    }

    function test_ParentVault_claimShares_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.claimShares.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.claimShares(1);
    }

    function test_ParentVault_claimShares_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_depositor);

        _changePrank(i_depositor);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 1));
        parent.vault.claimShares(1);
    }

    function test_ParentVault_claimAsset_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.claimAsset.selector);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.vault.claimAsset(1);
    }

    function test_ParentVault_claimAsset_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_withdrawer);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 1));
        parent.vault.claimAsset(1);
    }

    function test_ParentVault_cancelDeposit_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.cancelDeposit.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.cancelDeposit();
    }

    function test_ParentVault_cancelDeposit_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_depositor);

        _changePrank(i_depositor);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_depositor, 1));
        parent.vault.cancelDeposit();
    }

    function test_ParentVault_cancelWithdraw_RevertWhen_CallerIsNotKycApproved() external {
        _assertParentVaultKycPolicy(ParentVault.cancelWithdraw.selector);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.vault.cancelWithdraw();
    }

    function test_ParentVault_cancelWithdraw_ReachesVaultLogicWhen_CallerIsKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_withdrawer);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_withdrawer, 1));
        parent.vault.cancelWithdraw();
    }
}
