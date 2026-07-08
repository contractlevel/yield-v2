// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

contract ParentVault_FreezePolicyIntegrationTest is BaseIntegrationTest {
    uint256 private constant SHARE_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();
        _deployParent();
    }

    function test_ParentVault_freezePolicy_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setAddressFrozen(i_depositor, true);
    }

    function test_ParentVault_freezePolicy_SucceedsWhen_CallerIsComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _freeze(i_depositor);

        assertTrue(parent.share.isFrozen(i_depositor));
    }

    function test_ParentVault_deposit_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.deposit.selector);
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _freeze(i_depositor);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.deposit(DEPOSIT_AMOUNT);
    }

    function test_ParentVault_withdraw_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.withdraw.selector);
        _registerKyc(i_withdrawer);
        _mintShares(i_withdrawer, SHARE_AMOUNT);
        _approveShares(i_withdrawer, address(parent.vault), SHARE_AMOUNT);
        _freeze(i_withdrawer);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.vault.withdraw(SHARE_AMOUNT);
    }

    function test_ParentVault_claimShares_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.claimShares.selector);
        _registerKyc(i_depositor);
        _freeze(i_depositor);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.claimShares(1);
    }

    function test_ParentVault_claimAsset_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.claimAsset.selector);
        _registerKyc(i_withdrawer);
        _freeze(i_withdrawer);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.vault.claimAsset(1);
    }

    function test_ParentVault_cancelDeposit_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.cancelDeposit.selector);
        _registerKyc(i_depositor);
        _freeze(i_depositor);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.vault.cancelDeposit();
    }

    function test_ParentVault_cancelWithdraw_RevertWhen_CallerIsFrozen() external {
        _assertParentVaultKycPolicy(ParentVault.cancelWithdraw.selector);
        _registerKyc(i_withdrawer);
        _freeze(i_withdrawer);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.vault.cancelWithdraw();
    }

    function _freeze(address account) internal {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.setAddressFrozen(account, true);
    }
}
