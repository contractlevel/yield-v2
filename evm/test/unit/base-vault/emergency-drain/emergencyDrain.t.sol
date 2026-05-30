// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract BaseVault_EmergencyDrainUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    uint256 internal constant USDC_AMOUNT = 1000 * 1e6; // 1000 USDC
    uint256 internal constant TVL = 1_000 * 1e6;

    function _setUpVault() internal {
        _changePrank(i_owner);
        s_vault.grantRole(Roles.EMERGENCY_DRAINER_ROLE, i_emergencyDrainer);
        _changePrank(i_emergencyDrainer);
    }

    function test_BaseVault_emergencyDrain_RevertWhen_CallerDoesNotHaveEMERGENCY_DRAINER_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.EMERGENCY_DRAINER_ROLE
            )
        );
        s_vault.emergencyDrain(true);
    }

    function test_BaseVault_emergencyDrain_RevertWhen_DelayNotMet() external {
        _changePrank(i_pauser);
        s_vault.pause();

        _changePrank(i_emergencyDrainer);
        vm.expectRevert(IBaseVault.BaseVault__EmergencyDrainDelayNotMet.selector);
        s_vault.emergencyDrain(true);
    }

    function test_BaseVault_emergencyDrain_RevertWhen_NotPaused() external {
        vm.expectRevert(Pausable.ExpectedPause.selector);
        s_vault.emergencyDrain(true);
    }

    function test_BaseVault_emergencyDrain_Success_WhenTVLIsZero() external {
        _changePrank(i_pauser);
        s_vault.pause();

        vm.warp(block.timestamp + 1 days);

        deal(address(s_mockUsdc), address(s_vault), USDC_AMOUNT);

        _changePrank(i_emergencyDrainer);
        vm.recordLogs();
        s_vault.emergencyDrain(true);

        assertEq(s_mockUsdc.balanceOf(i_emergencyReceiver), USDC_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_emergencyDrainer), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), 0);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 0);

        Vm.Log memory log = _assertEmittedBy(keccak256("EmergencyDrainExecuted(address,uint256)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_emergencyReceiver);
        assertEq(uint256(log.topics[2]), USDC_AMOUNT);
    }

    function test_BaseVault_emergencyDrain_Success_WhenTVLIsGreaterThanZero() external {
        _changePrank(i_pauser);
        s_vault.pause();

        vm.warp(block.timestamp + 1 days);

        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);
        deal(address(s_mockUsdc), address(s_vault), USDC_AMOUNT);

        _changePrank(i_emergencyDrainer);
        s_vault.emergencyDrain(true);

        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockUsdc.balanceOf(i_emergencyReceiver), USDC_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_emergencyDrainer), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), 0);
    }

    function test_BaseVault_emergencyDrain_RevertWhen_WithdrawFailsAndRevertOnFailureIsTrue() external {
        _changePrank(i_pauser);
        s_vault.pause();

        vm.warp(block.timestamp + 1 days);

        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_emergencyDrainer);
        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, type(uint256).max));
        s_vault.emergencyDrain(true);
    }

    function test_BaseVault_emergencyDrain_Success_WhenWithdrawFailsAndRevertOnFailureIsFalse() external {
        _changePrank(i_pauser);
        s_vault.pause();

        vm.warp(block.timestamp + 1 days);

        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);
        s_mockProtocolAdapter.setWithdrawReverts(true);
        deal(address(s_mockUsdc), address(s_vault), USDC_AMOUNT);

        _changePrank(i_emergencyDrainer);
        vm.expectCall(
            address(s_mockProtocolAdapter),
            abi.encodeWithSelector(s_mockProtocolAdapter.withdraw.selector, type(uint256).max)
        );
        s_vault.emergencyDrain(false);

        assertEq(s_mockUsdc.balanceOf(i_emergencyReceiver), USDC_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(i_emergencyDrainer), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), 0);
    }

    function _setActiveAdapter() internal virtual;
}

contract ParentVault_EmergencyDrainUnitTest is BaseVault_EmergencyDrainUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _setUpVault();
    }

    function _setActiveAdapter() internal override {}
}

contract ChildVault_EmergencyDrainUnitTest is BaseVault_EmergencyDrainUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _setUpVault();
    }

    function _setActiveAdapter() internal override {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
    }
}
