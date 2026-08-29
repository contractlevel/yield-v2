// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IChildVault} from "../../../../src/interfaces/vaults/IChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {MockCCIPRouter} from "../../../mocks/MockCCIPRouter.sol";
import {MockProtocolAdapter} from "../../../mocks/MockProtocolAdapter.sol";

/*//////////////////////////////////////////////////////////////
                             NONE
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_None_UnitTest is BaseUnitTest {
    function test_ChildVault_executeRecovery_NONE_RevertWhen_NoRecoveryPending() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }
}

/*//////////////////////////////////////////////////////////////
                          EPOCH_DEPOSIT
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_EpochDeposit_UnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _storeEpochDepositRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_RevertWhen_Paused()
        public
        givenContractIsPaused(address(s_childVault))
    {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_childVault.executeRecovery();

        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
        assertEq(s_mockProtocolAdapter.getDepositCalls(), 0);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_DepositsIntoActiveAdapter() public {
        s_childVault.executeRecovery();

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_ClearsRecoveryState() public {
        s_childVault.executeRecovery();

        Types.EpochRecovery memory recovery = s_childVault.getEpochDepositRecovery();
        assertEq(recovery.epochNonce, 0);
        assertEq(recovery.amount, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_EmitsEpochDepositToStrategySuccess() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositToStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_DEPOSIT_EmitsEpochDepositRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochDepositRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    function _storeEpochDepositRecovery() internal {
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(address(s_mockCcipRouter));
        deal(address(s_mockUsdc), address(s_childVault), DEPOSIT_AMOUNT);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        s_mockProtocolAdapter.setDepositReverts(false);
    }

    function _depositMessage(uint256 epochNonce) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            PARENT_CHAIN_SELECTOR,
            address(s_parentVault),
            Types.CcipTx.EPOCH_NET_DEPOSIT,
            abi.encode(epochNonce),
            DEPOSIT_AMOUNT
        );
    }
}

/*//////////////////////////////////////////////////////////////
                         EPOCH_WITHDRAW
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_EpochWithdraw_UnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), WITHDRAW_AMOUNT);
        _storeEpochWithdrawRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_RevertWhen_AdapterWithdrawReverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, WITHDRAW_AMOUNT));
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_RevertWhen_AdapterReturnsZero() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_RevertWhen_CcipSendExceedsTokenPoolCapacity() public {
        uint256 capacity = WITHDRAW_AMOUNT - 1;
        bytes memory err = _mockCcipSendTokenMaxCapacityExceeded(capacity, WITHDRAW_AMOUNT);

        vm.expectRevert(err);
        s_childVault.executeRecovery();

        Types.EpochRecovery memory recovery = s_childVault.getEpochWithdrawRecovery();
        assertEq(recovery.epochNonce, EPOCH_NONCE);
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_childVault)), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_WithdrawsFromActiveAdapter() public {
        s_childVault.executeRecovery();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_BridgesToParent() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.executeRecovery();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_ClearsRecoveryState() public {
        s_childVault.executeRecovery();

        Types.EpochRecovery memory recovery = s_childVault.getEpochWithdrawRecovery();
        assertEq(recovery.epochNonce, 0);
        assertEq(recovery.amount, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_DoesNotAllowOriginalCreActionToBeReplayed() public {
        s_childVault.executeRecovery();

        assertEq(s_childVault.getLastHandledEpochNonce(), EPOCH_NONCE);
        _changePrank(i_epochOperator);
        vm.expectRevert(
            abi.encodeWithSelector(IChildVault.ChildVault__InvalidEpochNonce.selector, EPOCH_NONCE, EPOCH_NONCE)
        );
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_EmitsEpochWithdrawFromStrategySuccess() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochWithdrawFromStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_EPOCH_WITHDRAW_EmitsEpochWithdrawRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochWithdrawRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    function _storeEpochWithdrawRecovery() internal {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        s_mockProtocolAdapter.setWithdrawReverts(false);
    }
}

/*//////////////////////////////////////////////////////////////
                       REBALANCE_DEPOSIT
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_RebalanceDeposit_UnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;

    function setUp() public {
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _storeRebalanceDepositRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_DepositsIntoActiveAdapter() public {
        s_childVault.executeRecovery();

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_ClearsRecoveryState() public {
        s_childVault.executeRecovery();

        Types.RebalanceDepositRecovery memory recovery = s_childVault.getRebalanceDepositRecovery();
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.amount, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_DEPOSIT_EmitsRebalanceDepositRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
    }

    function _storeRebalanceDepositRecovery() internal {
        s_mockProtocolAdapter.setVault(address(s_childVault));
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(address(s_mockCcipRouter));
        deal(address(s_mockUsdc), address(s_childVault), DEPOSIT_AMOUNT);
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        s_mockProtocolAdapter.setDepositReverts(false);
    }

    function _rebalanceMessage(uint256 rebalanceNonce, bytes32 protocolId)
        internal
        view
        returns (Client.Any2EVMMessage memory)
    {
        return _rebalanceMessage(
            PARENT_CHAIN_SELECTOR, address(s_parentVault), rebalanceNonce, protocolId, DEPOSIT_AMOUNT
        );
    }
}

/*//////////////////////////////////////////////////////////////
                      REBALANCE_WITHDRAW
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_RebalanceWithdraw_UnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant REBALANCE_AMOUNT = 500 * 1e6;

    MockProtocolAdapter internal s_newMockProtocolAdapter;

    function setUp() public {
        s_newMockProtocolAdapter = new MockProtocolAdapter();
        s_newMockProtocolAdapter.setVault(address(s_childVault));

        _registerAdapter(AAVE_V4_PROTOCOL_ID, address(s_newMockProtocolAdapter));
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), REBALANCE_AMOUNT);
        _storeRebalanceWithdrawRecovery();
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_RevertWhen_AdapterWithdrawReverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, type(uint256).max));
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_RevertWhen_AdapterReturnsZero() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_childVault.executeRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_RevertWhen_CcipSendExceedsTokenPoolCapacity() public {
        uint256 capacity = REBALANCE_AMOUNT - 1;
        bytes memory err = _mockCcipSendTokenMaxCapacityExceeded(capacity, REBALANCE_AMOUNT);

        vm.expectRevert(err);
        s_childVault.executeRecovery();

        Types.RebalanceWithdrawRecovery memory recovery = s_childVault.getRebalanceWithdrawRecovery();
        assertEq(recovery.rebalanceNonce, REBALANCE_NONCE);
        assertEq(recovery.strategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(recovery.strategy.chainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 0);
        assertEq(s_childVault.getActiveProtocolAdapter(), address(s_mockProtocolAdapter));
        assertEq(s_mockUsdc.balanceOf(address(s_childVault)), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_WithdrawsFromActiveAdapter() public {
        s_childVault.executeRecovery();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_BridgesToTargetChild() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.executeRecovery();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_ClearsRecoveryState() public {
        s_childVault.executeRecovery();

        Types.RebalanceWithdrawRecovery memory recovery = s_childVault.getRebalanceWithdrawRecovery();
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.strategy.protocolId, bytes32(0));
        assertEq(recovery.strategy.chainSelector, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_DoesNotAllowOriginalCreActionToBeReplayed() public {
        s_childVault.executeRecovery();

        assertEq(s_childVault.getLastHandledRebalanceNonce(), REBALANCE_NONCE);
        _changePrank(i_rebalanceOperator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IChildVault.ChildVault__InvalidRebalanceNonce.selector, REBALANCE_NONCE, REBALANCE_NONCE
            )
        );
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_EmitsRebalanceWithdrawSuccess() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRecovery_REBALANCE_WITHDRAW_EmitsRebalanceWithdrawRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.executeRecovery();

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

/*//////////////////////////////////////////////////////////////
                           CCIP_SEND
//////////////////////////////////////////////////////////////*/

contract ChildVault_ExecuteRecovery_CcipSend_UnitTest is BaseUnitTest {
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

    // Storage tests (verify that operations store CCIP_SEND recovery on send failure)

    function test_ChildVault_executeEpochWithdraw_WhenGetFeeReverts_StoresCcipSendRecovery() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(recovery.nonce, EPOCH_NONCE);
        assertEq(recovery.protocolId, bytes32(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
    }

    function test_ChildVault_executeEpochWithdraw_WhenCcipSendReverts_StoresCcipSendRecovery() public {
        s_mockCcipRouter.setCcipSendReverts(true);

        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(recovery.nonce, EPOCH_NONCE);
        assertEq(recovery.protocolId, bytes32(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
    }

    function test_ChildVault_executeRebalance_WhenGetFeeReverts_StoresCcipSendRecovery() public {
        _storeRebalanceCcipSendRecoveryFromGetFee();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.REBALANCE));
        assertEq(recovery.amount, REBALANCE_AMOUNT);
        assertEq(recovery.destinationChainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertEq(recovery.nonce, REBALANCE_NONCE);
        assertEq(recovery.protocolId, AAVE_V4_PROTOCOL_ID);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
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

    // executeRecovery tests

    function test_ChildVault_executeRecovery_CCIP_SEND_ClearsRecoveryAndBridges() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.executeRecovery();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + WITHDRAW_AMOUNT);
        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.destinationChainSelector, 0);
        assertEq(recovery.nonce, 0);
        assertEq(recovery.protocolId, bytes32(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_CCIP_SEND_Rebalance_ClearsRecoveryAndBridges() public {
        _storeRebalanceCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.executeRecovery();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.destinationChainSelector, 0);
        assertEq(recovery.nonce, 0);
        assertEq(recovery.protocolId, bytes32(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_executeRecovery_CCIP_SEND_EmitsCcipSendRecoveryCleared() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);

        vm.recordLogs();
        s_childVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(uint64(uint256(log.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[3]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeRecovery_CCIP_SEND_RevertWhen_RetryFails() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();

        vm.expectRevert(MockCCIPRouter.MockCCIPRouter__GetFeeReverts.selector);
        s_childVault.executeRecovery();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(recovery.nonce, EPOCH_NONCE);
        assertEq(recovery.protocolId, bytes32(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
    }

    function test_ChildVault_executeRecovery_CCIP_SEND_Rebalance_RevertWhen_RetryFails() public {
        _storeRebalanceCcipSendRecoveryFromGetFee();

        vm.expectRevert(MockCCIPRouter.MockCCIPRouter__GetFeeReverts.selector);
        s_childVault.executeRecovery();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.REBALANCE));
        assertEq(recovery.amount, REBALANCE_AMOUNT);
        assertEq(recovery.destinationChainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertEq(recovery.nonce, REBALANCE_NONCE);
        assertEq(recovery.protocolId, AAVE_V4_PROTOCOL_ID);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
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
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
    }

    function test_ChildVault_executeRecovery_CCIP_SEND_AllowsLaterDifferentSendType() public {
        _storeEpochWithdrawCcipSendRecoveryFromGetFee();
        s_mockCcipRouter.setGetFeeReverts(false);
        s_childVault.executeRecovery();
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);

        _changePrank(i_rebalanceOperator);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
        assertEq(s_childVault.getCcipSendRecovery().amount, 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
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
