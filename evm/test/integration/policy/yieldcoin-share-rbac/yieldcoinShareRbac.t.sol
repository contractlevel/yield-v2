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
        _deployParent();
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

    /// @dev batchMint has no policy chain configured. With defaultPolicyAllow = false this
    ///      makes batchMint uncallable by anyone — including the vault — effectively disabling it.
    ///      This is intentional: only the singular mint path is supported.
    function test_YieldcoinShare_batchMint_AlwaysReverts_NoPolicyConfigured() external {
        _assertSharePolicyNotConfigured(ComplianceTokenERC3643.batchMint.selector);

        _changePrank(address(parent.vault));
        _expectPolicyRevert();
        parent.share.batchMint(_twoAddresses(i_recipient1, i_recipient2), _twoAmounts(1e18, 2e18));
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

    /// @dev batchBurn has no policy chain configured. With defaultPolicyAllow = false this
    ///      makes batchBurn uncallable by anyone — including the vault — effectively disabling it.
    ///      This is intentional: only the singular burn path is supported.
    function test_YieldcoinShare_batchBurn_AlwaysReverts_NoPolicyConfigured() external {
        _assertSharePolicyNotConfigured(ComplianceTokenERC3643.batchBurn.selector);

        _changePrank(address(parent.vault));
        _expectPolicyRevert();
        parent.share.batchBurn(_twoAddresses(i_depositor, i_depositor), _twoAmounts(1e18, 2e18));
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

    function test_YieldcoinShare_batchForcedTransfer_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.batchForcedTransfer.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share
            .batchForcedTransfer(
                _twoAddresses(i_depositor, i_depositor),
                _twoAddresses(i_withdrawer, i_withdrawer),
                _twoAmounts(1e18, 2e18)
            );
    }

    function test_YieldcoinShare_batchForcedTransfer_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share
            .batchForcedTransfer(
                _twoAddresses(i_depositor, i_depositor),
                _twoAddresses(i_withdrawer, i_withdrawer),
                _twoAmounts(1e18, 2e18)
            );

        assertEq(parent.share.balanceOf(i_withdrawer), 3e18);
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

    function test_YieldcoinShare_batchSetAddressFrozen_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.batchSetAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchSetAddressFrozen(_twoAddresses(i_depositor, i_withdrawer), _twoBools(true, true));
    }

    function test_YieldcoinShare_batchSetAddressFrozen_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.batchSetAddressFrozen(_twoAddresses(i_depositor, i_withdrawer), _twoBools(true, true));

        assertTrue(parent.share.isFrozen(i_depositor));
        assertTrue(parent.share.isFrozen(i_withdrawer));
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

    function test_YieldcoinShare_batchFreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.batchFreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchFreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));
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

    function test_YieldcoinShare_batchUnfreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.batchUnfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchUnfreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));
    }

    function _twoAddresses(address first, address second) private pure returns (address[] memory accounts) {
        accounts = new address[](2);
        accounts[0] = first;
        accounts[1] = second;
    }

    function _twoAmounts(uint256 first, uint256 second) private pure returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = first;
        amounts[1] = second;
    }

    function _twoBools(bool first, bool second) private pure returns (bool[] memory values) {
        values = new bool[](2);
        values[0] = first;
        values[1] = second;
    }

    function _assertSharePolicyNotConfigured(bytes4 selector) private view {
        address[] memory policies = parent.policyEngine.getPolicies(address(parent.share), selector);
        assertEq(policies.length, 0);
    }
}
