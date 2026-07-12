// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

contract ParentVault_CcipReceiveUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant BRIDGED_AMOUNT = 500 * 1e6;
    uint256 internal constant SHARE_BURN_AMOUNT = 500 * 1e18;
    uint256 internal constant PRICE_PER_SHARE = 1e12;
    uint256 internal constant TOTAL_DEPOSIT_AMOUNT = 100 * 1e6;
    uint256 internal constant TOTAL_WITHDRAW_USDC = SHARE_BURN_AMOUNT * PRICE_PER_SHARE / SHARE_PRECISION;
    uint256 internal constant EXPECTED_WITHDRAW_USDC = TOTAL_WITHDRAW_USDC - TOTAL_DEPOSIT_AMOUNT;

    function setUp() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        _setParentEpochNonce(EPOCH_NONCE + 1);
        deal(address(s_mockUsdc), address(s_parentVault), BRIDGED_AMOUNT);
        _changePrank(address(s_mockCcipRouter));
    }

    function test_ParentVault_ccipReceive_RevertWhen_CallerIsNotCCIPRouter() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(CCIPReceiver.InvalidRouter.selector, i_nonOwner));
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC));
    }

    function test_ParentVault_ccipReceive_RevertWhen_SenderIsNotAllowedSender() public {
        Client.Any2EVMMessage memory message = _withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC);
        message.sender = abi.encode(i_nonOwner);

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidSender.selector, i_nonOwner, CHILD_CHAIN_SELECTOR)
        );
        s_parentVault.ccipReceive(message);
    }

    function test_ParentVault_ccipReceive_RevertWhen_SenderAndRegisteredVaultAreZero() public {
        Client.Any2EVMMessage memory message = _withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC);
        message.sourceChainSelector = REMOTE_CHILD_CHAIN_SELECTOR;
        message.sender = abi.encode(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                IBaseVault.BaseVault__InvalidSender.selector, address(0), REMOTE_CHILD_CHAIN_SELECTOR
            )
        );
        s_parentVault.ccipReceive(message);
    }

    function test_ParentVault_ccipReceive_RevertWhen_ReceivedTokenIsNotUsdc() public {
        address wrongToken = address(s_mockLink);
        Client.Any2EVMMessage memory message = _withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC);
        message.destTokenAmounts[0].token = wrongToken;

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidReceivedToken.selector, wrongToken, address(s_mockUsdc))
        );
        s_parentVault.ccipReceive(message);
    }

    function test_ParentVault_ccipReceive_RevertWhen_TokenAmountsLengthIsZero() public {
        Client.Any2EVMMessage memory message = _withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC);
        message.destTokenAmounts = new Client.EVMTokenAmount[](0);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTokenAmountsLength.selector, 0, 1));
        s_parentVault.ccipReceive(message);
    }

    function test_ParentVault_ccipReceive_RevertWhen_TokenAmountsLengthIsGreaterThanOne() public {
        Client.Any2EVMMessage memory message = _withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC);
        message.destTokenAmounts = _twoUsdcTokenAmounts(EXPECTED_WITHDRAW_USDC, 1);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTokenAmountsLength.selector, 2, 1));
        s_parentVault.ccipReceive(message);
    }

    function test_ParentVault_ccipReceive_RevertWhen_ReceivedAmountIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, 0));
    }

    function test_ParentVault_ccipReceive_RevertWhen_TxTypeIsInvalid() public {
        Client.Any2EVMMessage memory message = _message(
            CHILD_CHAIN_SELECTOR,
            address(s_childVault),
            Types.CcipTx.EPOCH_NET_DEPOSIT,
            abi.encode(EPOCH_NONCE),
            BRIDGED_AMOUNT
        );

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidTxType.selector, Types.CcipTx.EPOCH_NET_DEPOSIT)
        );
        s_parentVault.ccipReceive(message);
    }

    /*//////////////////////////////////////////////////////////////
                             WITHDRAW PATH
    //////////////////////////////////////////////////////////////*/
    function test_ParentVault_ccipReceive_Withdraw_RevertWhen_EpochNonceDoesNotMatchPrevious() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__InvalidEpochNonce.selector, EPOCH_NONCE + 1));
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE + 1, EXPECTED_WITHDRAW_USDC));
    }

    function test_ParentVault_ccipReceive_Withdraw_RevertWhen_EpochIsNotExecuting() public {
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotExecuting.selector, EPOCH_NONCE));
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC));
    }

    function test_ParentVault_ccipReceive_Withdraw_WhenReceivedAmountIsLessThanExpected_MakesEpochClaimable() public {
        uint256 receivedWithdrawUsdc = EXPECTED_WITHDRAW_USDC - 1;
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, receivedWithdrawUsdc));

        assertEq(uint256(s_parentVault.getEpoch(EPOCH_NONCE).status), uint256(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_ccipReceive_Withdraw_WhenReceivedAmountIsLessThanExpected_EmitsEpochWithdrawAmountShort()
        public
    {
        uint256 receivedWithdrawUsdc = EXPECTED_WITHDRAW_USDC - 1;
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        vm.recordLogs();
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, receivedWithdrawUsdc));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochWithdrawAmountShort(uint256,uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), EXPECTED_WITHDRAW_USDC);
        assertEq(uint256(log.topics[3]), receivedWithdrawUsdc);
    }

    function test_ParentVault_ccipReceive_Withdraw_WhenReceivedAmountIsLessThanExpected_UpdatesWithdrawClaimAmount()
        public
    {
        uint256 receivedWithdrawUsdc = EXPECTED_WITHDRAW_USDC - 1;
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, receivedWithdrawUsdc));

        assertEq(
            s_parentVault.getEpoch(EPOCH_NONCE).totalWithdrawClaimAmount, TOTAL_DEPOSIT_AMOUNT + receivedWithdrawUsdc
        );
        assertEq(
            s_parentVault.getEpoch(EPOCH_NONCE).remainingWithdrawClaimAmount,
            TOTAL_DEPOSIT_AMOUNT + receivedWithdrawUsdc
        );
    }

    function test_ParentVault_ccipReceive_Withdraw_Success_MakesEpochClaimable() public {
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC));

        assertEq(uint256(s_parentVault.getEpoch(EPOCH_NONCE).status), uint256(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_ccipReceive_Withdraw_Success_UpdatesWithdrawClaimAmount() public {
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC));

        assertEq(s_parentVault.getEpoch(EPOCH_NONCE).totalWithdrawClaimAmount, TOTAL_WITHDRAW_USDC);
        assertEq(s_parentVault.getEpoch(EPOCH_NONCE).remainingWithdrawClaimAmount, TOTAL_WITHDRAW_USDC);
    }

    function test_ParentVault_ccipReceive_Withdraw_WhenReceivedAmountIsGreaterThanExpected_MakesEpochClaimable()
        public
    {
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC + 1));

        assertEq(uint256(s_parentVault.getEpoch(EPOCH_NONCE).status), uint256(Types.EpochStatus.CLAIMABLE));
    }

    function test_ParentVault_ccipReceive_Withdraw_WhenReceivedAmountIsGreaterThanExpected_UpdatesWithdrawClaimAmount()
        public
    {
        uint256 receivedWithdrawUsdc = EXPECTED_WITHDRAW_USDC + 1;
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, receivedWithdrawUsdc));

        assertEq(
            s_parentVault.getEpoch(EPOCH_NONCE).totalWithdrawClaimAmount, TOTAL_DEPOSIT_AMOUNT + receivedWithdrawUsdc
        );
        assertEq(
            s_parentVault.getEpoch(EPOCH_NONCE).remainingWithdrawClaimAmount,
            TOTAL_DEPOSIT_AMOUNT + receivedWithdrawUsdc
        );
    }

    function test_ParentVault_ccipReceive_Withdraw_Success_EmitsEpochClaimable() public {
        _setParentEpochStatus(EPOCH_NONCE, Types.EpochStatus.EXECUTING);
        _setParentEpochWithdrawAccounting(EPOCH_NONCE);

        vm.recordLogs();
        s_parentVault.ccipReceive(_withdrawMessage(EPOCH_NONCE, EXPECTED_WITHDRAW_USDC));

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochClaimable(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    /*//////////////////////////////////////////////////////////////
                             REBALANCE PATH
    //////////////////////////////////////////////////////////////*/
    function test_ParentVault_ccipReceive_Rebalance_RevertWhen_NoRebalanceInProgress() public {
        // s_rebalance.state == NONE by default
        vm.expectRevert(IParentVault.ParentVault__NoRebalanceInProgress.selector);
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));
    }

    function test_ParentVault_ccipReceive_Rebalance_RevertWhen_RebalanceNonceDoesNotMatch() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        uint256 wrongNonce = REBALANCE_NONCE + 1;
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__InvalidRebalanceNonce.selector, wrongNonce));
        s_parentVault.ccipReceive(_rebalanceMessage(wrongNonce, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));
    }

    function test_ParentVault_ccipReceive_Rebalance_RevertWhen_PendingProtocolIdDoesNotMatch() public {
        _setParentPendingRebalance(AAVE_V4_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        vm.expectRevert(
            abi.encodeWithSelector(IParentVault.ParentVault__InvalidPendingProtocolId.selector, AAVE_V3_PROTOCOL_ID)
        );
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));
    }

    function test_ParentVault_ccipReceive_Rebalance_RevertWhen_TargetProtocolAdapterIsNotRegistered() public {
        bytes32 unknownProtocolId = keccak256("unknown-protocol");
        _setParentPendingRebalance(unknownProtocolId, CHILD_CHAIN_SELECTOR);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__NoAdapterRegistered.selector, unknownProtocolId));
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, unknownProtocolId, BRIDGED_AMOUNT));
    }

    function test_ParentVault_ccipReceive_Rebalance_Success_DepositsIntoTargetAdapter() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), BRIDGED_AMOUNT);
    }

    function test_ParentVault_ccipReceive_Rebalance_Success_SetsActiveProtocolAdapter() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        assertEq(s_parentVault.getActiveProtocolAdapter(), address(s_mockProtocolAdapter));
    }

    function test_ParentVault_ccipReceive_Rebalance_Success_FinalizesRebalance() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, REBALANCE_NONCE + 1);
        assertEq(rebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(rebalance.activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_ccipReceive_Rebalance_Success_EmitsRebalanceDepositSuccess() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);

        vm.recordLogs();
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ParentVault_ccipReceive_Rebalance_Success_EmitsRebalanceCompleted() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);

        vm.recordLogs();
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(log.topics[2], AAVE_V3_PROTOCOL_ID);
        assertEq(uint256(log.topics[3]), PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_EmitsRebalanceDepositFailure()
        public
    {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositFailure(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ParentVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_StoresRebalanceDepositRecovery()
        public
    {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        s_mockProtocolAdapter.setDepositReverts(true);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Types.RebalanceDepositRecovery memory recovery = s_parentVault.getRebalanceDepositRecovery();
        assertEq(recovery.rebalanceNonce, REBALANCE_NONCE);
        assertEq(recovery.amount, BRIDGED_AMOUNT);
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ParentVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_EmitsRebalanceDepositRecoveryStored()
        public
    {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryStored(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ParentVault_ccipReceive_Rebalance_WhenTargetAdapterDepositReverts_LeavesRebalanceInProgress() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        s_mockProtocolAdapter.setDepositReverts(true);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(rebalance.nonce, REBALANCE_NONCE);
        assertEq(rebalance.pendingStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(rebalance.pendingStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_ccipReceive_Rebalance_RevertWhen_RecoveryExists() public {
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        s_mockProtocolAdapter.setDepositReverts(true);

        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID, BRIDGED_AMOUNT));
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _setParentEpochWithdrawAccounting(uint256 epochNonce) internal {
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(epochNonce).depth(0)
            .checked_write(TOTAL_DEPOSIT_AMOUNT);
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(epochNonce).depth(1)
            .checked_write(SHARE_BURN_AMOUNT);
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(epochNonce).depth(2)
            .checked_write(TOTAL_WITHDRAW_USDC);
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(epochNonce).depth(3)
            .checked_write(PRICE_PER_SHARE);
    }

    function _withdrawMessage(uint256 epochNonce, uint256 amount) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            CHILD_CHAIN_SELECTOR, address(s_childVault), Types.CcipTx.EPOCH_NET_WITHDRAW, abi.encode(epochNonce), amount
        );
    }

    function _rebalanceMessage(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        internal
        view
        returns (Client.Any2EVMMessage memory)
    {
        return _rebalanceMessage(CHILD_CHAIN_SELECTOR, address(s_childVault), rebalanceNonce, protocolId, amount);
    }
}
