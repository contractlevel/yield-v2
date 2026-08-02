// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IChildVault} from "../../../../src/interfaces/vaults/IChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

contract ChildVault_CcipReceiveUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant BRIDGED_AMOUNT = 500 * 1e6;

    function setUp() public {
        s_mockProtocolAdapter.setVault(address(s_childVault));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), BRIDGED_AMOUNT);
        _changePrank(address(s_mockCcipRouter));
    }

    function test_ChildVault_ccipReceive_RevertWhen_CallerIsNotCCIPRouter() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(CCIPReceiver.InvalidRouter.selector, i_nonOwner));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_Paused()
        public
        givenContractIsPaused(address(s_childVault))
    {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 0);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_Paused()
        public
        givenContractIsPaused(address(s_childVault))
    {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 0);
        assertEq(s_childVault.getActiveProtocolAdapter(), address(0));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ChildVault_ccipReceive_RevertWhen_SenderIsNotAllowedSender() public {
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.sender = abi.encode(i_nonOwner);

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidSender.selector, i_nonOwner, PARENT_CHAIN_SELECTOR)
        );
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_SourceChainIsNotParentChain() public {
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        _changePrank(address(s_mockCcipRouter));
        Client.Any2EVMMessage memory message = _message(
            REMOTE_CHILD_CHAIN_SELECTOR,
            address(s_parentVault),
            Types.CcipTx.EPOCH_NET_DEPOSIT,
            abi.encode(EPOCH_NONCE),
            BRIDGED_AMOUNT
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IBaseVault.BaseVault__InvalidSourceChainSelector.selector,
                REMOTE_CHILD_CHAIN_SELECTOR,
                PARENT_CHAIN_SELECTOR
            )
        );
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_RevertWhen_SenderAndRegisteredVaultAreZero() public {
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.sourceChainSelector = REMOTE_CHILD_CHAIN_SELECTOR;
        message.sender = abi.encode(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                IBaseVault.BaseVault__InvalidSender.selector, address(0), REMOTE_CHILD_CHAIN_SELECTOR
            )
        );
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_RevertWhen_ReceivedTokenIsNotUsdc() public {
        address wrongToken = address(s_mockLink);
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.destTokenAmounts[0].token = wrongToken;

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidReceivedToken.selector, wrongToken, address(s_mockUsdc))
        );
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_RevertWhen_TokenAmountsLengthIsZero() public {
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.destTokenAmounts = new Client.EVMTokenAmount[](0);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTokenAmountsLength.selector, 0, 1));
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_RevertWhen_TokenAmountsLengthIsGreaterThanOne() public {
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.destTokenAmounts = _twoUsdcTokenAmounts(BRIDGED_AMOUNT, 1);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTokenAmountsLength.selector, 2, 1));
        s_childVault.ccipReceive(message);
    }

    function test_ChildVault_ccipReceive_RevertWhen_ReceivedAmountIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE, 0));
    }

    function test_ChildVault_ccipReceive_RevertWhen_RecoveryExists() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));
    }

    function test_ChildVault_ccipReceive_RevertWhen_TxTypeIsInvalid() public {
        Client.Any2EVMMessage memory message = _message(
            PARENT_CHAIN_SELECTOR,
            address(s_parentVault),
            Types.CcipTx.EPOCH_NET_WITHDRAW,
            abi.encode(EPOCH_NONCE),
            BRIDGED_AMOUNT
        );

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTxType.selector, Types.CcipTx.EPOCH_NET_WITHDRAW)
        );
        s_childVault.ccipReceive(message);
    }

    /*//////////////////////////////////////////////////////////////
                              DEPOSIT PATH
    //////////////////////////////////////////////////////////////*/
    function test_ChildVault_ccipReceive_Deposit_RevertWhen_NoActiveAdapter() public {
        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        assertEq(s_childVault.getLastHandledEpochNonce(), 0);
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_EpochNonceIsZero() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        vm.expectRevert(abi.encodeWithSelector(IChildVault.ChildVault__InvalidEpochNonce.selector, 0, 0));
        s_childVault.ccipReceive(_depositMessage(0));
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_EpochNonceWasAlreadyHandled() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        vm.expectRevert(
            abi.encodeWithSelector(IChildVault.ChildVault__InvalidEpochNonce.selector, EPOCH_NONCE, EPOCH_NONCE)
        );
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_EpochNonceIsOlderThanLastHandled() public {
        uint256 laterNonce = EPOCH_NONCE + 2;
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_childVault.ccipReceive(_depositMessage(laterNonce));

        vm.expectRevert(
            abi.encodeWithSelector(IChildVault.ChildVault__InvalidEpochNonce.selector, EPOCH_NONCE, laterNonce)
        );
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
    }

    function test_ChildVault_ccipReceive_Deposit_RevertWhen_NonceWasHandledByCcipThenReplayedByCre() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        _changePrank(i_epochOperator);
        vm.expectRevert(
            abi.encodeWithSelector(IChildVault.ChildVault__InvalidEpochNonce.selector, EPOCH_NONCE, EPOCH_NONCE)
        );
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_Success_DepositsIntoActiveAdapter() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), BRIDGED_AMOUNT);
        assertEq(s_childVault.getLastHandledEpochNonce(), EPOCH_NONCE);
    }

    function test_ChildVault_ccipReceive_Deposit_Success_EmitsEpochDepositToStrategySuccess() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        vm.recordLogs();
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositToStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_Success_EmitsCCIPReceived() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.messageId = keccak256("ccip-message");

        vm.recordLogs();
        s_childVault.ccipReceive(message);

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPReceived(bytes32,uint64,uint8)"), address(s_childVault));
        assertEq(log.topics[1], message.messageId);
        assertEq(uint256(log.topics[2]), PARENT_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[3]), uint256(Types.CcipTx.EPOCH_NET_DEPOSIT));
    }

    function test_ChildVault_ccipReceive_Deposit_WhenActiveAdapterDepositReverts_EmitsEpochDepositToStrategyFailure()
        public
    {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositToStrategyFailure(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_WhenActiveAdapterDepositReverts_StoresEpochDepositRecovery() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Types.EpochRecovery memory recovery = s_childVault.getEpochDepositRecovery();
        assertEq(recovery.epochNonce, EPOCH_NONCE);
        assertEq(recovery.amount, BRIDGED_AMOUNT);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
        assertEq(s_childVault.getLastHandledEpochNonce(), EPOCH_NONCE);
    }

    function test_ChildVault_ccipReceive_Deposit_WhenActiveAdapterDepositReverts_EmitsEpochDepositRecoveryStored()
        public
    {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochDepositRecoveryStored(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_WhenEpochDepositRecoveryAlreadyExists_Reverts() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT);
    }

    /*//////////////////////////////////////////////////////////////
                             REBALANCE PATH
    //////////////////////////////////////////////////////////////*/
    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_TargetProtocolAdapterIsNotRegistered() public {
        bytes32 unknownProtocolId = keccak256("unknown-protocol");

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__NoAdapterRegistered.selector, unknownProtocolId));
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, unknownProtocolId));

        assertEq(s_childVault.getLastHandledRebalanceNonce(), 0);
    }

    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_RebalanceNonceIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(IChildVault.ChildVault__InvalidRebalanceNonce.selector, 0, 0));
        s_childVault.ccipReceive(_rebalanceMessage(0, AAVE_V3_PROTOCOL_ID));
    }

    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_RebalanceNonceWasAlreadyHandled() public {
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        vm.expectRevert(
            abi.encodeWithSelector(
                IChildVault.ChildVault__InvalidRebalanceNonce.selector, REBALANCE_NONCE, REBALANCE_NONCE
            )
        );
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));
    }

    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_RebalanceNonceIsOlderThanLastHandled() public {
        uint256 laterNonce = REBALANCE_NONCE + 2;
        s_childVault.ccipReceive(_rebalanceMessage(laterNonce, AAVE_V3_PROTOCOL_ID));

        vm.expectRevert(
            abi.encodeWithSelector(IChildVault.ChildVault__InvalidRebalanceNonce.selector, REBALANCE_NONCE, laterNonce)
        );
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));
    }

    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_NonceWasHandledByCcipThenReplayedByCre() public {
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        _changePrank(i_rebalanceOperator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IChildVault.ChildVault__InvalidRebalanceNonce.selector, REBALANCE_NONCE, REBALANCE_NONCE
            )
        );
        s_childVault.executeRebalance(REBALANCE_NONCE, _strategy(AAVE_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR));
    }

    function test_ChildVault_ccipReceive_Rebalance_Success_DepositsIntoTargetAdapter() public {
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), BRIDGED_AMOUNT);
        assertEq(s_childVault.getLastHandledRebalanceNonce(), REBALANCE_NONCE);
    }

    function test_ChildVault_ccipReceive_Rebalance_Success_WhenSourceIsRegisteredChildChain() public {
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        _changePrank(address(s_mockCcipRouter));

        s_childVault.ccipReceive(
            _rebalanceMessage(
                REMOTE_CHILD_CHAIN_SELECTOR,
                address(s_parentVault),
                REBALANCE_NONCE,
                AAVE_V3_PROTOCOL_ID,
                BRIDGED_AMOUNT
            )
        );

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Rebalance_Success_SetsActiveProtocolAdapter() public {
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        assertEq(s_childVault.getActiveProtocolAdapter(), address(s_mockProtocolAdapter));
    }

    function test_ChildVault_ccipReceive_Rebalance_Success_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_EmitsRebalanceDepositFailure()
        public
    {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositFailure(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_StoresRebalanceDepositRecovery()
        public
    {
        s_mockProtocolAdapter.setDepositReverts(true);

        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        Types.RebalanceDepositRecovery memory recovery = s_childVault.getRebalanceDepositRecovery();
        assertEq(recovery.rebalanceNonce, REBALANCE_NONCE);
        assertEq(recovery.amount, BRIDGED_AMOUNT);
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
        assertEq(s_childVault.getLastHandledRebalanceNonce(), REBALANCE_NONCE);
    }

    function test_ChildVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_EmitsRebalanceDepositRecoveryStored()
        public
    {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryStored(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Rebalance_WhenRebalanceDepositRecoveryAlreadyExists_Reverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _depositMessage(uint256 epochNonce) internal view returns (Client.Any2EVMMessage memory) {
        return _depositMessage(epochNonce, BRIDGED_AMOUNT);
    }

    function _depositMessage(uint256 epochNonce, uint256 amount) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            PARENT_CHAIN_SELECTOR,
            address(s_parentVault),
            Types.CcipTx.EPOCH_NET_DEPOSIT,
            abi.encode(epochNonce),
            amount
        );
    }

    function _rebalanceMessage(uint256 rebalanceNonce, bytes32 protocolId)
        internal
        view
        returns (Client.Any2EVMMessage memory)
    {
        return _rebalanceMessage(
            PARENT_CHAIN_SELECTOR, address(s_parentVault), rebalanceNonce, protocolId, BRIDGED_AMOUNT
        );
    }
}
