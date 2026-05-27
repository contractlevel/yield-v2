// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {MockCCIPRouter} from "../../../mocks/MockCCIPRouter.sol";
import {MockProtocolAdapter} from "../../../mocks/MockProtocolAdapter.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_InitiateRebalanceUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    uint256 internal constant REBALANCE_AMOUNT = 500 * 1e6;

    MockProtocolAdapter internal s_newMockProtocolAdapter;

    function setUp() public {
        s_newMockProtocolAdapter = new MockProtocolAdapter();

        _registerAdapter(AAVE_V4_PROTOCOL_ID, address(s_newMockProtocolAdapter));
        deal(address(s_mockUsdc), address(s_parentVault), REBALANCE_AMOUNT);
        s_mockProtocolAdapter.setWithdrawReturnAmount(REBALANCE_AMOUNT);

        _changePrank(i_rebalanceOperator);
    }

    function test_ParentVault_initiateRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        vm.expectRevert();
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_RevertWhen_RebalanceInProgress() public {
        _setParentRebalanceState(Types.RebalanceState.REBALANCING);

        vm.expectRevert(IParentVault.ParentVault__RebalanceInProgress.selector);
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_RevertWhen_RecoveryExists() public {
        stdstore.target(address(s_parentVault)).sig("getRebalanceDepositRecovery()").depth(1).checked_write(
            REBALANCE_AMOUNT
        );

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_RevertWhen_SameStrategy() public {
        vm.expectRevert(IParentVault.ParentVault__SameStrategy.selector);
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V3_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_RevertWhen_PriorEpochExecuting() public {
        _setParentEpochNonce(2);
        _setParentEpochStatus(1, Types.EpochStatus.EXECUTING);

        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochExecuting.selector, 1));
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_RevertWhen_LocalWithdrawAdapterReverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__WithdrawFailed.selector, type(uint256).max));
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_WhenLocalWithdrawReturnsZero_EmitsRebalanceWithdrawSuccess() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        vm.recordLogs();
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), 0);
    }

    function test_ParentVault_initiateRebalance_RevertWhen_LocalDepositAdapterReverts() public {
        s_newMockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, REBALANCE_AMOUNT));
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_WithdrawsFromOldAdapter() public {
        _initiateLocalToLocal();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_DepositsIntoNewAdapter() public {
        _initiateLocalToLocal();

        assertEq(s_newMockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_newMockProtocolAdapter.getLastDepositAmount(), REBALANCE_AMOUNT);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_EmitsRebalanceInitiated() public {
        vm.recordLogs();
        _initiateLocalToLocal();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceInitiated(uint256,uint64,bytes32)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint64(uint256(log.topics[2])), PARENT_CHAIN_SELECTOR);
        assertEq(bytes32(log.topics[3]), AAVE_V4_PROTOCOL_ID);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_StoresLastRebalanceInitiatedTimestamp() public {
        _initiateLocalToLocal();

        assertEq(s_parentVault.getRebalance().lastRebalanceInitiatedTimestamp, block.timestamp);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_EmitsRebalanceWithdrawSuccess() public {
        vm.recordLogs();
        _initiateLocalToLocal();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceWithdrawSuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        _initiateLocalToLocal();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), REBALANCE_AMOUNT);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_FinalizesRebalance() public {
        _initiateLocalToLocal();

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, 2);
        assertEq(rebalance.activeStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(rebalance.activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_initiateRebalance_LocalToLocal_DeletesPendingStrategy() public {
        _initiateLocalToLocal();

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(rebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(rebalance.pendingStrategy.chainSelector, 0);
    }

    function test_ParentVault_initiateRebalance_LocalToChild_WithdrawsFromOldAdapter() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        _initiateLocalToChild();

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), type(uint256).max);
    }

    function test_ParentVault_initiateRebalance_LocalToChild_BridgesToChild() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        _initiateLocalToChild();

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + REBALANCE_AMOUNT);
    }

    function test_ParentVault_initiateRebalance_LocalToChild_RevertWhen_CcipSendReverts() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        s_mockCcipRouter.setCcipSendReverts(true);

        vm.expectRevert(MockCCIPRouter.MockCCIPRouter__CcipSendReverts.selector);
        _initiateLocalToChild();
    }

    function test_ParentVault_initiateRebalance_LocalToChild_ClearsActiveProtocolAdapter() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));

        _initiateLocalToChild();

        assertEq(s_parentVault.getActiveProtocolAdapter(), address(0));
    }

    function test_ParentVault_initiateRebalance_LocalToChild_LeavesRebalancePending() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        _initiateLocalToChild();

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.REBALANCING));
        assertEq(rebalance.nonce, 1);
        assertEq(rebalance.pendingStrategy.protocolId, AAVE_V4_PROTOCOL_ID);
        assertEq(rebalance.pendingStrategy.chainSelector, CHILD_CHAIN_SELECTOR);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _initiateLocalToLocal() internal {
        _changePrank(i_rebalanceOperator);
        s_parentVault.initiateRebalance(_localStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function _initiateLocalToChild() internal {
        _changePrank(i_rebalanceOperator);
        s_parentVault.initiateRebalance(_childStrategy(AAVE_V4_PROTOCOL_ID));
    }

    function _localStrategy(bytes32 protocolId) internal pure returns (Types.Strategy memory) {
        return _strategy(protocolId, PARENT_CHAIN_SELECTOR);
    }

    function _childStrategy(bytes32 protocolId) internal pure returns (Types.Strategy memory) {
        return _strategy(protocolId, CHILD_CHAIN_SELECTOR);
    }
}
