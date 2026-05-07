// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_CancelDepositUnitTest is BaseUnitTest {
    uint256 internal constant DEPOSIT_AMOUNT = MIN_DEPOSIT_AMOUNT;
    uint256 internal s_netDepositAmount;

    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.deposit(DEPOSIT_AMOUNT);

        (s_netDepositAmount,) = s_parentVault.getNetAmountAndOperationFee(DEPOSIT_AMOUNT);
    }

    function test_ParentVault_cancelDeposit_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.cancelDeposit();
    }

    function test_ParentVault_cancelDeposit_RevertWhen_EpochNotOpen() public {
        _setParentEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotOpen.selector, 1));
        s_parentVault.cancelDeposit();
    }

    function test_ParentVault_cancelDeposit_RevertWhen_NoDeposit() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_nonOwner, 1));
        s_parentVault.cancelDeposit();
    }

    function test_ParentVault_cancelDeposit_Success_TransfersUsdc() public {
        uint256 vaultBefore = s_mockUsdc.balanceOf(address(s_parentVault));
        uint256 depositorBefore = s_mockUsdc.balanceOf(i_depositor);
        s_parentVault.cancelDeposit();
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), vaultBefore - s_netDepositAmount);
        assertEq(s_mockUsdc.balanceOf(i_depositor), depositorBefore + s_netDepositAmount);
    }

    function test_ParentVault_cancelDeposit_Success_DeletesDepositMapping() public {
        s_parentVault.cancelDeposit();
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
    }

    function test_ParentVault_cancelDeposit_Success_UpdatesEpochTotal() public {
        s_parentVault.cancelDeposit();
        assertEq(s_parentVault.getEpoch(1).totalDepositAmount, 0);
    }

    function test_ParentVault_cancelDeposit_Success_EmitsDepositCancelled() public {
        vm.recordLogs();
        s_parentVault.cancelDeposit();
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositCancelled(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_depositor);
        assertEq(uint256(log.topics[3]), s_netDepositAmount);
    }
}
