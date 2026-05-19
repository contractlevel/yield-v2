// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IChildVault} from "../../../../src/interfaces/IChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

contract ChildVault_CcipReceiveUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant BRIDGED_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), BRIDGED_AMOUNT);
        _changePrank(address(s_mockCcipRouter));
    }

    function test_ChildVault_ccipReceive_RevertWhen_CallerIsNotCCIPRouter() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(CCIPReceiver.InvalidRouter.selector, i_nonOwner));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
    }

    function test_ChildVault_ccipReceive_RevertWhen_SenderIsNotAllowedSender() public {
        Client.Any2EVMMessage memory message = _depositMessage(EPOCH_NONCE);
        message.sender = abi.encode(i_nonOwner);

        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidSender.selector, i_nonOwner, PARENT_CHAIN_SELECTOR)
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

    /*//////////////////////////////////////////////////////////////
                              DEPOSIT PATH
    //////////////////////////////////////////////////////////////*/
    function test_ChildVault_ccipReceive_Deposit_RevertWhen_NoActiveAdapter() public {
        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));
    }

    function test_ChildVault_ccipReceive_Deposit_Success_DepositsIntoActiveAdapter() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_Success_EmitsDepositToStrategySuccess() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));

        vm.recordLogs();
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositToStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_WhenActiveAdapterDepositReverts_EmitsDepositToStrategyFailure()
        public
    {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositToStrategyFailure(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), BRIDGED_AMOUNT);
    }

    function test_ChildVault_ccipReceive_Deposit_WhenActiveAdapterDepositReverts_StoresEpochDepositRecovery() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        s_mockProtocolAdapter.setDepositReverts(true);

        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        Types.AmountRecovery memory recovery = s_childVault.getEpochDepositRecovery(EPOCH_NONCE);
        assertEq(recovery.amount, BRIDGED_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
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
    }

    /*//////////////////////////////////////////////////////////////
                             REBALANCE PATH
    //////////////////////////////////////////////////////////////*/
    function test_ChildVault_ccipReceive_Rebalance_RevertWhen_TargetProtocolAdapterIsNotRegistered() public {
        bytes32 unknownProtocolId = keccak256("unknown-protocol");

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__NoAdapterRegistered.selector, unknownProtocolId));
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, unknownProtocolId));
    }

    function test_ChildVault_ccipReceive_Rebalance_Success_DepositsIntoTargetAdapter() public {
        s_childVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

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

        Types.AmountRecovery memory recovery = s_childVault.getRebalanceDepositRecovery(REBALANCE_NONCE);
        assertEq(recovery.amount, BRIDGED_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
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
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _depositMessage(uint256 epochNonce) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            PARENT_CHAIN_SELECTOR, address(s_parentVault), Types.CcipTx.DEPOSIT, abi.encode(epochNonce), BRIDGED_AMOUNT
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
