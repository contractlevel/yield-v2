// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest, Vm} from "../BaseAaveV4AdapterUnitTest.t.sol";

import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

contract AaveV4Adapter_DepositUnitTest is BaseAaveV4AdapterUnitTest {
    uint256 internal constant DEPOSIT_AMOUNT = 1000 * 1e6;

    function setUp() public {
        deal(address(s_mockUsdc), address(s_aaveV4Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(s_parentVault));
    }

    function test_AaveV4Adapter_deposit_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_Success() external {
        vm.recordLogs();
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Deposit(uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV4Spoke)), DEPOSIT_AMOUNT);
        assertEq(s_aaveV4Adapter.getTVL(), DEPOSIT_AMOUNT);
    }
}
