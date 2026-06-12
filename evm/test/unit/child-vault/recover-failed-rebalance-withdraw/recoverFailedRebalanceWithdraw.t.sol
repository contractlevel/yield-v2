// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {MockProtocolAdapter} from "../../../mocks/MockProtocolAdapter.sol";

contract ChildVault_RecoverFailedRebalanceWithdrawUnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant REBALANCE_AMOUNT = 500 * 1e6;

    MockProtocolAdapter internal s_newMockProtocolAdapter;

    function setUp() public {
        s_newMockProtocolAdapter = new MockProtocolAdapter();

        _registerAdapter(AAVE_V4_PROTOCOL_ID, address(s_newMockProtocolAdapter));
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), REBALANCE_AMOUNT);
        _storeRebalanceWithdrawRecovery();
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_RevertWhen_NoPendingRecovery() public {
        s_childVault.recoverFailedRebalanceWithdraw();

        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedRebalanceWithdraw();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.recoverFailedRebalanceWithdraw();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_RevertWhen_AdapterWithdrawReverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, type(uint256).max));
        s_childVault.recoverFailedRebalanceWithdraw();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_RevertWhen_AdapterReturnsZero() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_childVault.recoverFailedRebalanceWithdraw();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_Success_WithdrawsFromActiveAdapter() public {
        s_childVault.recoverFailedRebalanceWithdraw();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_Success_BridgesToTargetChild() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.recoverFailedRebalanceWithdraw();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_Success_ClearsRecoveryState() public {
        s_childVault.recoverFailedRebalanceWithdraw();

        Types.RebalanceWithdrawRecovery memory recovery = s_childVault.getRebalanceWithdrawRecovery();
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.strategy.protocolId, bytes32(0));
        assertEq(recovery.strategy.chainSelector, 0);
        assertEq(recovery.createdAt, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_Success_EmitsRebalanceWithdrawSuccess() public {
        vm.recordLogs();
        s_childVault.recoverFailedRebalanceWithdraw();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ChildVault_recoverFailedRebalanceWithdraw_Success_EmitsRebalanceWithdrawRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.recoverFailedRebalanceWithdraw();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
    }

    function _storeRebalanceWithdrawRecovery() internal {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_rebalanceOperator);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        s_mockProtocolAdapter.setWithdrawReverts(false);
    }

    function _remoteChildStrategy() internal pure returns (Types.Strategy memory) {
        return _strategy(AAVE_V4_PROTOCOL_ID, REMOTE_CHILD_CHAIN_SELECTOR);
    }
}
