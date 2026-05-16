// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../BaseIntegrationTest.t.sol";

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";

contract YieldcoinShare_KycPolicyIntegrationTest is BaseIntegrationTest {
    uint256 private constant SHARE_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();
        _deployParent();
        _registerKyc(i_depositor);
        _mintShares(i_depositor, SHARE_AMOUNT);
    }

    function test_YieldcoinShare_transfer_RevertWhen_RecipientIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.transfer.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.share.transfer(i_recipient1, 1e18);
    }

    function test_YieldcoinShare_transfer_RevertWhen_CallerIsNotKycApproved() external {
        _registerKyc(i_recipient1);
        _mintShares(i_nonKycUser, 1e18);

        _changePrank(i_nonKycUser);
        _expectPolicyRevert();
        parent.share.transfer(i_recipient1, 1e18);
    }

    function test_YieldcoinShare_transfer_SucceedsWhen_AccountsAreKycApproved() external {
        _registerKyc(i_recipient1);

        _changePrank(i_depositor);
        parent.share.transfer(i_recipient1, 1e18);

        assertEq(parent.share.balanceOf(i_recipient1), 1e18);
    }

    function test_YieldcoinShare_batchTransfer_RevertWhen_RecipientIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.batchTransfer.selector);
        _registerKyc(i_recipient1);

        address[] memory recipients = new address[](2);
        recipients[0] = i_recipient1;
        recipients[1] = i_recipient2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.share.batchTransfer(recipients, amounts);
    }

    function test_YieldcoinShare_batchTransfer_RevertWhen_CallerIsNotKycApproved() external {
        _registerKyc(i_recipient1);
        _registerKyc(i_recipient2);
        _mintShares(i_nonKycUser, 2e18);

        address[] memory recipients = new address[](2);
        recipients[0] = i_recipient1;
        recipients[1] = i_recipient2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        _changePrank(i_nonKycUser);
        _expectPolicyRevert();
        parent.share.batchTransfer(recipients, amounts);
    }

    function test_YieldcoinShare_batchTransfer_SucceedsWhen_AccountsAreKycApproved() external {
        _registerKyc(i_recipient1);
        _registerKyc(i_recipient2);

        address[] memory recipients = new address[](2);
        recipients[0] = i_recipient1;
        recipients[1] = i_recipient2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 2e18;

        _changePrank(i_depositor);
        parent.share.batchTransfer(recipients, amounts);

        assertEq(parent.share.balanceOf(i_recipient1), 1e18);
        assertEq(parent.share.balanceOf(i_recipient2), 2e18);
    }

    function test_YieldcoinShare_transferFrom_RevertWhen_RecipientIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.transferFrom.selector);
        _registerKyc(i_withdrawer);
        _approveShares(i_depositor, i_withdrawer, 1e18);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.share.transferFrom(i_depositor, i_recipient1, 1e18);
    }

    function test_YieldcoinShare_transferFrom_RevertWhen_FromIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.transferFrom.selector);
        address from = makeAddr("from");
        _mintShares(from, SHARE_AMOUNT);
        _registerKyc(i_withdrawer);
        _registerKyc(i_recipient1);
        _approveShares(from, i_withdrawer, 1e18);

        _changePrank(i_withdrawer);
        _expectPolicyRevert();
        parent.share.transferFrom(from, i_recipient1, 1e18);
    }

    function test_YieldcoinShare_transferFrom_SucceedsWhen_AccountsAreKycApproved() external {
        _registerKyc(i_withdrawer);
        _registerKyc(i_recipient1);
        _approveShares(i_depositor, i_withdrawer, 1e18);

        _changePrank(i_withdrawer);
        parent.share.transferFrom(i_depositor, i_recipient1, 1e18);

        assertEq(parent.share.balanceOf(i_recipient1), 1e18);
    }

    function test_YieldcoinShare_approve_RevertWhen_SpenderIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.approve.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.share.approve(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_approve_RevertWhen_CallerIsNotKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_nonKycUser);
        _expectPolicyRevert();
        parent.share.approve(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_approve_SucceedsWhen_AccountsAreKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_depositor);
        parent.share.approve(i_withdrawer, 1e18);

        assertEq(parent.share.allowance(i_depositor, i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_increaseAllowance_RevertWhen_SpenderIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.increaseAllowance.selector);

        _changePrank(i_depositor);
        _expectPolicyRevert();
        parent.share.increaseAllowance(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_increaseAllowance_RevertWhen_CallerIsNotKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_nonKycUser);
        _expectPolicyRevert();
        parent.share.increaseAllowance(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_increaseAllowance_SucceedsWhen_AccountsAreKycApproved() external {
        _registerKyc(i_withdrawer);

        _changePrank(i_depositor);
        parent.share.increaseAllowance(i_withdrawer, 1e18);

        assertEq(parent.share.allowance(i_depositor, i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_decreaseAllowance_SucceedsWhen_SpenderIsNotKycApproved() external {
        _assertShareKycPolicy(ComplianceTokenERC3643.decreaseAllowance.selector);

        _changePrank(i_depositor);
        parent.share.decreaseAllowance(i_withdrawer, 0);
    }

    function test_YieldcoinShare_decreaseAllowance_RevertWhen_CallerIsNotKycApproved() external {
        _changePrank(i_nonKycUser);
        _expectPolicyRevert();
        parent.share.decreaseAllowance(i_withdrawer, 0);
    }

    function test_YieldcoinShare_decreaseAllowance_SucceedsWhen_CallerIsKycApproved() external {
        _registerKyc(i_withdrawer); // approve requires spender KYC; only setting up the prior allowance

        _changePrank(i_depositor);
        parent.share.approve(i_withdrawer, 2e18);
        parent.share.decreaseAllowance(i_withdrawer, 1e18);

        assertEq(parent.share.allowance(i_depositor, i_withdrawer), 1e18);
    }
}
