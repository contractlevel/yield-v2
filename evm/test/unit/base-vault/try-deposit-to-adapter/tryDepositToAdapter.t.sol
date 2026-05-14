// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";

abstract contract BaseVault_TryDepositToAdapterUnitTest is BaseUnitTest {
    BaseVault internal s_vault;


    function test_BaseVault_tryDepositToAdapter_RevertWhen_CallerIsNotSelf() external {
        vm.expectRevert(IBaseVault.BaseVault__OnlySelf.selector);
        s_vault.tryDepositToAdapter(address(s_mockProtocolAdapter), DEPOSIT_AMOUNT);
    }

    function test_BaseVault_tryDepositToAdapter_Success() external {
        deal(address(s_mockUsdc), address(s_vault), DEPOSIT_AMOUNT);

        _changePrank(address(s_vault));
        s_vault.tryDepositToAdapter(address(s_mockProtocolAdapter), DEPOSIT_AMOUNT);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockProtocolAdapter)), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), 0);
    }

    function test_BaseVault_tryDepositToAdapter_RevertWhen_AdapterDepositReverts() external {
        deal(address(s_mockUsdc), address(s_vault), DEPOSIT_AMOUNT);
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(address(s_vault));
        vm.expectRevert(bytes("MockProtocolAdapter: deposit reverted"));
        s_vault.tryDepositToAdapter(address(s_mockProtocolAdapter), DEPOSIT_AMOUNT);

        assertEq(s_mockUsdc.balanceOf(address(s_mockProtocolAdapter)), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_vault)), DEPOSIT_AMOUNT);
    }
}

contract ParentVault_TryDepositToAdapterUnitTest is BaseVault_TryDepositToAdapterUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }
}

contract ChildVault_TryDepositToAdapterUnitTest is BaseVault_TryDepositToAdapterUnitTest {
    function setUp() public {
        s_vault = s_childVault;
    }
}
