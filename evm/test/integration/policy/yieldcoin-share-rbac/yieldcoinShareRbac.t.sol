// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {MockPolicyEngine} from "../../../mocks/MockPolicyEngine.sol";

contract YieldcoinShare_RbacPolicyIntegrationTest is BaseIntegrationTest {
    uint256 private constant SHARE_AMOUNT = 100e18;

    function setUp() public override {
        super.setUp();
        _deployParent();
        _registerKyc(i_depositor);
        _registerKyc(i_withdrawer);
        _mintShares(i_depositor, SHARE_AMOUNT);
    }

    function test_YieldcoinShare_AC_005_mint_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.mint.selector, Roles.MINTER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.mint(i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_AC_005_mint_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.mint(i_withdrawer, 1e18);

        assertEq(parent.share.balanceOf(i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_AC_005_batchMint_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.mint.selector, Roles.MINTER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchMint(_twoAddresses(i_recipient1, i_recipient2), _twoAmounts(1e18, 2e18));
    }

    function test_YieldcoinShare_AC_005_batchMint_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.batchMint(_twoAddresses(i_recipient1, i_recipient2), _twoAmounts(1e18, 2e18));

        assertEq(parent.share.balanceOf(i_recipient1), 1e18);
        assertEq(parent.share.balanceOf(i_recipient2), 2e18);
    }

    function test_YieldcoinShare_AC_005_burn_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.burn.selector, Roles.BURNER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.burn(i_depositor, 1e18);
    }

    function test_YieldcoinShare_AC_005_burn_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.burn(i_depositor, 1e18);

        assertEq(parent.share.balanceOf(i_depositor), SHARE_AMOUNT - 1e18);
    }

    function test_YieldcoinShare_AC_005_batchBurn_RevertWhen_CallerIsNotParentVault() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.burn.selector, Roles.BURNER_ROLE, address(parent.vault));

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchBurn(_twoAddresses(i_depositor, i_depositor), _twoAmounts(1e18, 2e18));
    }

    function test_YieldcoinShare_AC_005_batchBurn_SucceedsWhen_CallerIsParentVault() external {
        _changePrank(address(parent.vault));
        parent.share.batchBurn(_twoAddresses(i_depositor, i_depositor), _twoAmounts(1e18, 2e18));

        assertEq(parent.share.balanceOf(i_depositor), SHARE_AMOUNT - 3e18);
    }

    function test_YieldcoinShare_AC_005_TOKEN_001_setCCIPAdmin_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            YieldcoinShare.setCCIPAdmin.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setCCIPAdmin(i_nonOwner);
    }

    function test_YieldcoinShare_AC_005_TOKEN_001_setCCIPAdmin_SucceedsWhen_CallerIsConfigOperator() external {
        _changePrank(networkConfig.roles.configOperator);
        parent.share.setCCIPAdmin(i_nonOwner);

        assertEq(parent.share.getCCIPAdmin(), i_nonOwner);
    }

    function test_YieldcoinShare_AC_005_setName_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setName.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setName("Nope");
    }

    function test_YieldcoinShare_AC_005_setName_SucceedsWhen_CallerIsConfigOperator() external {
        _changePrank(networkConfig.roles.configOperator);
        parent.share.setName("Yieldcoin V2");

        assertEq(parent.share.name(), "Yieldcoin V2");
    }

    function test_YieldcoinShare_AC_005_setSymbol_RevertWhen_CallerIsNotConfigOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setSymbol.selector, Roles.CONFIG_OPERATOR_ROLE, networkConfig.roles.configOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setSymbol("NOPE");
    }

    function test_YieldcoinShare_AC_005_setSymbol_SucceedsWhen_CallerIsConfigOperator() external {
        _changePrank(networkConfig.roles.configOperator);
        parent.share.setSymbol("YIELD2");

        assertEq(parent.share.symbol(), "YIELD2");
    }

    function test_YieldcoinShare_AC_005_pause_RevertWhen_CallerIsNotPauser() external {
        _assertShareRbacPolicy(ComplianceTokenERC3643.pause.selector, Roles.PAUSER_ROLE, networkConfig.roles.pauser);

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.pause();
    }

    function test_YieldcoinShare_AC_005_pause_SucceedsWhen_CallerIsPauser() external {
        _changePrank(networkConfig.roles.pauser);
        parent.share.pause();

        assertTrue(parent.share.paused());
    }

    function test_YieldcoinShare_AC_005_unpause_RevertWhen_CallerIsNotUnpauser() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.unpause.selector, Roles.UNPAUSER_ROLE, networkConfig.roles.unpauser
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.unpause();
    }

    function test_YieldcoinShare_AC_005_unpause_SucceedsWhen_CallerIsUnpauser() external {
        _changePrank(networkConfig.roles.pauser);
        parent.share.pause();

        _changePrank(networkConfig.roles.unpauser);
        parent.share.unpause();

        assertFalse(parent.share.paused());
    }

    function test_YieldcoinShare_AC_005_TOKEN_001_attachPolicyEngine_RevertWhen_CallerIsNotPolicyEngineManager()
        external
    {
        _assertShareRbacPolicy(
            YieldcoinShare.attachPolicyEngine.selector,
            Roles.POLICY_ENGINE_MANAGER_ROLE,
            networkConfig.roles.policy.engineManager
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.attachPolicyEngine(address(parent.policyEngine));
    }

    function test_YieldcoinShare_AC_005_TOKEN_001_attachPolicyEngine_SucceedsWhen_CallerIsPolicyEngineManager()
        external
    {
        MockPolicyEngine replacement = new MockPolicyEngine();

        _changePrank(networkConfig.roles.policy.engineManager);
        parent.share.attachPolicyEngine(address(replacement));

        assertEq(parent.share.getPolicyEngine(), address(replacement));
    }

    function test_YieldcoinShare_AC_005_forcedTransfer_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.forcedTransfer.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.forcedTransfer(i_depositor, i_withdrawer, 1e18);
    }

    function test_YieldcoinShare_AC_005_forcedTransfer_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.forcedTransfer(i_depositor, i_withdrawer, 1e18);

        assertEq(parent.share.balanceOf(i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_AC_005_batchForcedTransfer_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.forcedTransfer.selector,
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

    function test_YieldcoinShare_AC_005_batchForcedTransfer_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share
            .batchForcedTransfer(
                _twoAddresses(i_depositor, i_depositor),
                _twoAddresses(i_withdrawer, i_withdrawer),
                _twoAmounts(1e18, 2e18)
            );

        assertEq(parent.share.balanceOf(i_withdrawer), 3e18);
    }

    function test_YieldcoinShare_AC_005_setAddressFrozen_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.setAddressFrozen(i_depositor, true);
    }

    function test_YieldcoinShare_AC_005_setAddressFrozen_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.setAddressFrozen(i_depositor, true);

        assertTrue(parent.share.isFrozen(i_depositor));
    }

    function test_YieldcoinShare_AC_005_batchSetAddressFrozen_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.setAddressFrozen.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchSetAddressFrozen(_twoAddresses(i_depositor, i_withdrawer), _twoBools(true, true));
    }

    function test_YieldcoinShare_AC_005_batchSetAddressFrozen_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.batchSetAddressFrozen(_twoAddresses(i_depositor, i_withdrawer), _twoBools(true, true));

        assertTrue(parent.share.isFrozen(i_depositor));
        assertTrue(parent.share.isFrozen(i_withdrawer));
    }

    function test_YieldcoinShare_AC_005_freezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.freezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.freezePartialTokens(i_depositor, 1e18);
    }

    function test_YieldcoinShare_AC_005_freezePartialTokens_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.freezePartialTokens(i_depositor, 1e18);

        assertEq(parent.share.getFrozenTokens(i_depositor), 1e18);
    }

    function test_YieldcoinShare_AC_005_batchFreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.freezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchFreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));
    }

    function test_YieldcoinShare_AC_005_batchFreezePartialTokens_SucceedsWhen_CallerIsComplianceOperator() external {
        _mintShares(i_withdrawer, 1e18);

        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.batchFreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));

        assertEq(parent.share.getFrozenTokens(i_depositor), 1e18);
        assertEq(parent.share.getFrozenTokens(i_withdrawer), 1e18);
    }

    function test_YieldcoinShare_AC_005_unfreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.unfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.unfreezePartialTokens(i_depositor, 1e18);
    }

    function test_YieldcoinShare_AC_005_unfreezePartialTokens_SucceedsWhen_CallerIsComplianceOperator() external {
        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.freezePartialTokens(i_depositor, 1e18);
        parent.share.unfreezePartialTokens(i_depositor, 1e18);

        assertEq(parent.share.getFrozenTokens(i_depositor), 0);
    }

    function test_YieldcoinShare_AC_005_batchUnfreezePartialTokens_RevertWhen_CallerIsNotComplianceOperator() external {
        _assertShareRbacPolicy(
            ComplianceTokenERC3643.unfreezePartialTokens.selector,
            Roles.COMPLIANCE_OPERATOR_ROLE,
            networkConfig.roles.complianceOperator
        );

        _changePrank(i_nonOwner);
        _expectPolicyRevert();
        parent.share.batchUnfreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));
    }

    function test_YieldcoinShare_AC_005_batchUnfreezePartialTokens_SucceedsWhen_CallerIsComplianceOperator() external {
        _mintShares(i_withdrawer, 1e18);

        _changePrank(networkConfig.roles.complianceOperator);
        parent.share.batchFreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));
        parent.share.batchUnfreezePartialTokens(_twoAddresses(i_depositor, i_withdrawer), _twoAmounts(1e18, 1e18));

        assertEq(parent.share.getFrozenTokens(i_depositor), 0);
        assertEq(parent.share.getFrozenTokens(i_withdrawer), 0);
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
}
