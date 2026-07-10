// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3AdapterUnitTest, Vm} from "../BaseAaveV3AdapterUnitTest.t.sol";

import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract AaveV3Adapter_DepositUnitTest is BaseAaveV3AdapterUnitTest {
    uint256 internal constant PARTIAL_DEPOSIT_AMOUNT = DEPOSIT_AMOUNT / 2;
    uint256 internal constant TOLERANCE_SHORTFALL_AMOUNT = DEPOSIT_AMOUNT - 10;

    function setUp() public {
        deal(address(s_mockUsdc), address(s_aaveV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(s_parentVault));
    }

    function test_AaveV3Adapter_deposit_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_DepositAmountIsLessThanRequested() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(PARTIAL_DEPOSIT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncompleteDeposit.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_SucceedsWhen_CreditedAmountIsWithinRoundingTolerance() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(TOLERANCE_SHORTFALL_AMOUNT);

        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_aaveV3Adapter.getTVL(), TOLERANCE_SHORTFALL_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_Success() external {
        vm.recordLogs();
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Deposit(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV3Pool)), DEPOSIT_AMOUNT);
    }
}
