// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {MockCCIPRouter} from "../../../mocks/MockCCIPRouter.sol";

contract ChildVault_CcipSendRecoveryUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant REBALANCE_NONCE = 2;
    uint256 internal constant WITHDRAW_AMOUNT = 100 * 1e6;
    uint256 internal constant REBALANCE_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), WITHDRAW_AMOUNT + REBALANCE_AMOUNT);
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_recoverFailedCcipSend_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedCcipSend();
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeEpochWithdraw_WhenGetFeeReverts_StoresCcipSendRecovery() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(abi.decode(recovery.txData, (uint256)), EPOCH_NONCE);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeEpochWithdraw_WhenCcipSendReverts_StoresCcipSendRecovery() public {
        s_mockCcipRouter.setCcipSendReverts(true);

        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(abi.decode(recovery.txData, (uint256)), EPOCH_NONCE);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenGetFeeReverts_StoresCcipSendRecovery() public {
        _storeRebalanceCcipSendRecoveryFromGetFee();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(recovery.txData, (uint256, bytes32));
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.REBALANCE));
        assertEq(recovery.amount, REBALANCE_AMOUNT);
        assertEq(recovery.destinationChainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertEq(rebalanceNonce, REBALANCE_NONCE);
        assertEq(protocolId, AAVE_V4_PROTOCOL_ID);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeEpochWithdraw_WhenGetFeeReverts_EmitsCcipSendRecoveryStored() public {
        s_mockCcipRouter.setGetFeeReverts(true);

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(log.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[3]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_recoverFailedCcipSend_Success_ClearsRecoveryAndBridges() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.recoverFailedCcipSend();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + WITHDRAW_AMOUNT);
        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.destinationChainSelector, 0);
        assertEq(recovery.txData.length, 0);
        assertEq(recovery.createdAt, 0);
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedCcipSend_Success_EmitsCcipSendRecoveryCleared() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);

        vm.recordLogs();
        s_childVault.recoverFailedCcipSend();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(log.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[3]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_recoverFailedCcipSend_WhenRetryFails_RevertsAndPreservesRecovery() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();

        vm.expectRevert(MockCCIPRouter.MockCCIPRouter__GetFeeReverts.selector);
        s_childVault.recoverFailedCcipSend();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(abi.decode(recovery.txData, (uint256)), EPOCH_NONCE);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenCcipSendRecoveryPending_RevertsWithoutOverwrite() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);

        _changePrank(i_rebalanceOperator);
        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedCcipSend_WhenCleared_AllowsLaterDifferentSendType() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        s_childVault.recoverFailedCcipSend();
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);

        _changePrank(i_rebalanceOperator);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
        assertEq(s_childVault.getCcipSendRecovery().amount, 0);
        assertFalse(s_childVault.getRecoveryExists());
    }

    function _storeEpochWithdrawCcipSendRecoveryFromGetFee() internal {
        s_mockProtocolAdapter.setWithdrawReturnAmount(WITHDRAW_AMOUNT);
        s_mockCcipRouter.setGetFeeReverts(true);
        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
        _changePrank(i_nonOwner);
    }

    function _storeRebalanceCcipSendRecoveryFromGetFee() internal {
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);
        s_mockCcipRouter.setGetFeeReverts(true);
        _changePrank(i_rebalanceOperator);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());
        _changePrank(i_nonOwner);
    }

    function _remoteChildStrategy() internal pure returns (Types.Strategy memory) {
        return _strategy(AAVE_V4_PROTOCOL_ID, REMOTE_CHILD_CHAIN_SELECTOR);
    }
}
