// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";

contract YieldcoinShare_RbacPolicyIntegrationTest is BaseIntegrationTest {
    uint256 private constant SHARE_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();
        _registerKyc(i_depositor);
        _registerKyc(i_withdrawer);
        _mintShares(i_depositor, SHARE_AMOUNT);
    }

    function test_YieldcoinShare_mint_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.mint.selector, Roles.MINTER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.mint(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_mint_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.mint(i_withdrawer, 1e18);

        assertEq(parent.share.balanceOf(i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_burn_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.burn.selector, Roles.BURNER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.burn(i_depositor, 1e18);
    }

    function test_YieldcoinShare_burn_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.burn(i_depositor, 1e18);

        assertEq(parent.share.balanceOf(i_depositor), SHARE_AMOUNT - 1e18);
    }

    function test_YieldcoinShare_setCCIPAdmin_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            YieldcoinShare.setCCIPAdmin.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setCCIPAdmin(i_nonOwner);
    }

    function test_YieldcoinShare_setCCIPAdmin_SucceedsWhen_CallerIsConfigOperator() external {
        _changePrank(networkConfig.roles.configOperator);
        parent.share.setCCIPAdmin(i_nonOwner);

        assertEq(parent.share.getCCIPAdmin(), i_nonOwner);
    }

    function test_YieldcoinShare_setName_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setName.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setName("Nope");
    }

    function test_YieldcoinShare_setSymbol_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setSymbol.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setSymbol("NOPE");
    }

    function test_YieldcoinShare_pause_RevertWhen_CallerIsNotPauser() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.pause.selector, Roles.PAUSER_ROLE, networkConfig.roles.pauser);

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.pause();
    }

    function test_YieldcoinShare_pause_SucceedsWhen_CallerIsPauser() external {
        _changePrank(networkConfig.roles.pauser);
        parent.share.pause();

        assertTrue(parent.share.paused());
    }

    function test_YieldcoinShare_unpause_RevertWhen_CallerIsNotUnpauser() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.unpause.selector, Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.unpause();
    }

    function test_YieldcoinShare_attachPolicyEngine_RevertWhen_CallerIsNotPolicyEngineManager() external {
        _assertShareRbacPolicy(
            YieldcoinShare.attachPolicyEngine.selector,
            Roles.POLICY_ENGINE_MANAGER_ROLE,
            networkConfig.roles.policyEngineManager
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.attachPolicyEngine(address(parent.policyEngine));
    }

    function test_YieldcoinShare_forcedTransfer_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.forcedTransfer.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.forcedTransfer(i_depositor, i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_forcedTransfer_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.forcedTransfer(i_depositor, i_withdrawer, 1e18);

        assertEq(parent.share.balanceOf(i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_setAddressFrozen_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setAddressFrozen(i_depositor, true);
    }

    function test_YieldcoinShare_freezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.freezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.freezePartialTokens(i_depositor, 1e18);
    }

    function test_YieldcoinShare_unfreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.unfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.unfreezePartialTokens(i_depositor, 1e18);
    }
}
