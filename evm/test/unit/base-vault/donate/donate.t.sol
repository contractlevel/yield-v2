// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";

abstract contract BaseVault_DonateUnitTest is BaseUnitTest {
    BaseVault internal s_vault;
    address internal immutable i_donor = makeAddr("donor");

    function _setUpDonateTest(BaseVault vault) internal {
        s_vault = vault;
        deal(address(s_mockUsdc), i_donor, DEPOSIT_AMOUNT);
        _changePrank(i_donor);
        s_mockUsdc.approve(address(s_vault), DEPOSIT_AMOUNT);
    }

    function test_BaseVault_donate_RevertWhen_AmountIsZero() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_vault.donate(0);
    }

    function test_BaseVault_donate_RevertWhen_ChainIsNotActiveStrategy() external {
        _clearActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_vault.donate(DEPOSIT_AMOUNT);
    }

    function test_BaseVault_donate_RevertWhen_DepositFails() external {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_vault.donate(DEPOSIT_AMOUNT);
    }

    function test_BaseVault_donate_Success_DepositsUsdcIntoActiveStrategy() external {
        uint256 donorBalanceBefore = s_mockUsdc.balanceOf(i_donor);

        s_vault.donate(DEPOSIT_AMOUNT);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockProtocolAdapter)), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), 0);
        assertEq(s_mockUsdc.balanceOf(i_donor), donorBalanceBefore - DEPOSIT_AMOUNT);
    }

    function test_BaseVault_donate_Success_EmitsDonation() external {
        vm.recordLogs();
        s_vault.donate(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Donation(address,uint256)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_donor);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_BaseVault_donate_Success_DoesNotMintShares() external {
        uint256 totalSupplyBefore = s_yieldcoin.totalSupply();

        s_vault.donate(DEPOSIT_AMOUNT);

        assertEq(s_yieldcoin.totalSupply(), totalSupplyBefore);
    }

    function test_BaseVault_donate_Success_WhenPaused() external {
        _changePrank(i_pauser);
        s_vault.pause();

        _changePrank(i_donor);
        s_vault.donate(DEPOSIT_AMOUNT);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function _clearActiveAdapter() internal virtual;
}

contract ParentVault_DonateUnitTest is BaseVault_DonateUnitTest {
    function setUp() public {
        _setUpDonateTest(s_parentVault);
    }

    function test_BaseVault_donate_Success_DoesNotChangeTotalShares() external {
        uint256 totalSharesBefore = s_parentVault.getTotalShares();

        s_vault.donate(DEPOSIT_AMOUNT);

        assertEq(s_parentVault.getTotalShares(), totalSharesBefore);
    }

    function _clearActiveAdapter() internal override {
        _clearParentActiveAdapter();
    }
}

contract ChildVault_DonateUnitTest is BaseVault_DonateUnitTest {
    function setUp() public {
        _setUpDonateTest(s_childVault);
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
    }

    function _clearActiveAdapter() internal override {
        _clearChildActiveAdapter();
    }
}
