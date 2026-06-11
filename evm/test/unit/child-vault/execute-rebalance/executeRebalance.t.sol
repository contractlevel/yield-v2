// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {MockProtocolAdapter} from "../../../mocks/MockProtocolAdapter.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVault_ExecuteRebalanceUnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant REBALANCE_AMOUNT = 500 * 1e6;

    MockProtocolAdapter internal s_newMockProtocolAdapter;

    function setUp() public {
        s_newMockProtocolAdapter = new MockProtocolAdapter();

        _registerAdapter(AAVE_V4_PROTOCOL_ID, address(s_newMockProtocolAdapter));
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(REMOTE_CHILD_CHAIN_SELECTOR, address(s_parentVault));
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);
        deal(address(s_mockUsdc), address(s_childVault), REBALANCE_AMOUNT);
        _changePrank(i_rebalanceOperator);
    }

    function test_ChildVault_executeRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        vm.expectRevert();
        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());
    }

    function test_ChildVault_executeRebalance_RevertWhen_RecoveryExists() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE + 1, _remoteChildStrategy());
    }

    function test_ChildVault_executeRebalance_SameChild_RevertWhen_TargetProtocolAdapterIsNotRegistered() public {
        bytes32 unknownProtocolId = keccak256("unknown-protocol");

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__NoAdapterRegistered.selector, unknownProtocolId));
        s_childVault.executeRebalance(REBALANCE_NONCE, _strategy(unknownProtocolId, CHILD_CHAIN_SELECTOR));
    }

    function test_ChildVault_executeRebalance_SameChild_WithdrawsFromAdapter() public {
        _executeSameChildRebalance();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ChildVault_executeRebalance_SameChild_DepositsIntoTargetAdapter() public {
        _executeSameChildRebalance();

        assertEq(s_newMockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_newMockProtocolAdapter.getLastDepositAmount(), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRebalance_SameChild_EmitsRebalanceWithdrawSuccess() public {
        vm.recordLogs();
        _executeSameChildRebalance();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRebalance_SameChild_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        _executeSameChildRebalance();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRebalance_RemoteChild_WithdrawsFromAdapter() public {
        _executeRemoteChildRebalance();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ChildVault_executeRebalance_RemoteChild_BridgesToTargetChild() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        _executeRemoteChildRebalance();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRebalance_RemoteChild_EmitsCCIPBridged() public {
        vm.recordLogs();
        _executeRemoteChildRebalance();

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPBridged(bytes32,uint256,uint8)"), address(s_childVault));
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
        assertEq(uint256(log.topics[3]), uint256(Types.CcipTx.REBALANCE));
    }

    function test_ChildVault_executeRebalance_RemoteChild_WhenCcipSendReverts_StoresCcipSendRecovery() public {
        s_mockCcipRouter.setCcipSendReverts(true);

        _executeRemoteChildRebalance();

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(recovery.txData, (uint256, bytes32));
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.REBALANCE));
        assertEq(recovery.amount, REBALANCE_AMOUNT);
        assertEq(recovery.destinationChainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertEq(rebalanceNonce, REBALANCE_NONCE);
        assertEq(protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_RemoteChild_ClearsActiveProtocolAdapter() public {
        _executeRemoteChildRebalance();

        assertEq(s_childVault.getActiveProtocolAdapter(), address(0));
    }

    function test_ChildVault_executeRebalance_WhenWithdrawAdapterReverts_EmitsFailureWithoutBridging() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        vm.recordLogs();
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        _assertEmittedBy(keccak256("RebalanceWithdrawFailure(uint256)"), address(s_childVault));
        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore);
    }

    function test_ChildVault_executeRebalance_WhenWithdrawAdapterReverts_EmitsRebalanceWithdrawRecoveryStored() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.recordLogs();
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        Vm.Log memory log = _assertEmittedBy(
            keccak256("RebalanceWithdrawRecoveryStored(uint256,bytes32,uint64)"), address(s_childVault)
        );
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(bytes32(log.topics[2]), AAVE_V4_PROTOCOL_ID);
        assertEq(uint64(uint256(log.topics[3])), REMOTE_CHILD_CHAIN_SELECTOR);
    }


    function test_ChildVault_executeRebalance_WhenWithdrawAdapterReturnsZero_EmitsRebalanceWithdrawSuccess() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.recordLogs();
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), 0);
    }

    function test_ChildVault_executeRebalance_WhenWithdrawReturnsFalse_StoresRebalanceWithdrawRecovery() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        Types.RebalanceWithdrawRecovery memory recovery = s_childVault.getRebalanceWithdrawRecovery();
        assertEq(recovery.rebalanceNonce, REBALANCE_NONCE);
        assertEq(recovery.strategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(recovery.strategy.chainSelector, REMOTE_CHILD_CHAIN_SELECTOR);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenRebalanceWithdrawRecoveryAlreadyExists_Reverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenRebalanceWithdrawRecoveryStateAlreadyExists_Reverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE + 1, _remoteChildStrategy());
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenSameChildDepositAdapterReverts_EmitsDepositFailure() public {
        s_newMockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());

        _assertEmittedBy(keccak256("RebalanceDepositFailure(uint256,uint256)"), address(s_childVault));
    }

    function test_ChildVault_executeRebalance_WhenSameChildDepositAdapterReverts_StoresRebalanceDepositRecovery()
        public
    {
        s_newMockProtocolAdapter.setDepositReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());

        Types.RebalanceDepositRecovery memory recovery = s_childVault.getRebalanceDepositRecovery();
        assertEq(recovery.rebalanceNonce, REBALANCE_NONCE);
        assertEq(recovery.amount, REBALANCE_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenSameChildDepositAdapterReverts_EmitsRebalanceDepositRecoveryStored()
        public
    {
        s_newMockProtocolAdapter.setDepositReverts(true);

        vm.recordLogs();
        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryStored(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ChildVault_executeRebalance_WhenRebalanceDepositRecoveryAlreadyExists_Reverts() public {
        s_newMockProtocolAdapter.setDepositReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_executeRebalance_WhenRebalanceDepositRecoveryStateAlreadyExists_Reverts() public {
        s_newMockProtocolAdapter.setDepositReverts(true);

        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeRebalance(REBALANCE_NONCE + 1, _sameChildStrategy());
        assertTrue(s_childVault.getRecoveryExists());
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _executeSameChildRebalance() internal {
        s_childVault.executeRebalance(REBALANCE_NONCE, _sameChildStrategy());
    }

    function _executeRemoteChildRebalance() internal {
        s_childVault.executeRebalance(REBALANCE_NONCE, _remoteChildStrategy());
    }

    function _sameChildStrategy() internal pure returns (Types.Strategy memory) {
        return _strategy(AAVE_V4_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
    }

    function _remoteChildStrategy() internal pure returns (Types.Strategy memory) {
        return _strategy(AAVE_V4_PROTOCOL_ID, REMOTE_CHILD_CHAIN_SELECTOR);
    }
}
