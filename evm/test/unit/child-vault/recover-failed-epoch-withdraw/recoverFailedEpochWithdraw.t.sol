// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVault_RecoverFailedEpochWithdrawUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), WITHDRAW_AMOUNT);
        _storeEpochWithdrawRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_recoverFailedEpochWithdraw_RevertWhen_NoPendingRecovery() public {
        s_childVault.recoverFailedEpochWithdraw();

        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedEpochWithdraw();
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochWithdraw_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.recoverFailedEpochWithdraw();
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochWithdraw_RevertWhen_AdapterWithdrawReverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, WITHDRAW_AMOUNT));
        s_childVault.recoverFailedEpochWithdraw();
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochWithdraw_RevertWhen_AdapterReturnsZero() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_childVault.recoverFailedEpochWithdraw();
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochWithdraw_Success_WithdrawsFromActiveAdapter() public {
        s_childVault.recoverFailedEpochWithdraw();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochWithdraw_Success_BridgesToParent() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.recoverFailedEpochWithdraw();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + WITHDRAW_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochWithdraw_Success_ClearsRecoveryState() public {
        s_childVault.recoverFailedEpochWithdraw();

        Types.EpochRecovery memory recovery = s_childVault.getEpochWithdrawRecovery();
        assertEq(recovery.epochNonce, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochWithdraw_Success_EmitsWithdrawFromStrategySuccess() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochWithdraw();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawFromStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochWithdraw_Success_EmitsEpochWithdrawRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochWithdraw();

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochWithdrawRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    // @review test name
    function test_ChildVault_recoverFailedEpochWithdraw_Success_StoresEpochNonce() public view {
        Types.EpochRecovery memory recovery = s_childVault.getEpochWithdrawRecovery();

        assertEq(recovery.epochNonce, EPOCH_NONCE);
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _storeEpochWithdrawRecovery() internal {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        s_mockProtocolAdapter.setWithdrawReverts(false);
    }
}
