// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

/*//////////////////////////////////////////////////////////////
                             NONE
//////////////////////////////////////////////////////////////*/

contract ParentVault_ExecuteRecovery_None_UnitTest is BaseUnitTest {
    function test_ParentVault_executeRecovery_NONE_RevertWhen_NoRecoveryPending() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_parentVault.executeRecovery();
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }
}

/*//////////////////////////////////////////////////////////////
                       REBALANCE_DEPOSIT
//////////////////////////////////////////////////////////////*/

contract ParentVault_ExecuteRecovery_RebalanceDeposit_UnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    uint256 internal constant REBALANCE_NONCE = 1;

    function setUp() public {
        _setParentCrosschainVault(CHILD_CHAIN_SELECTOR, address(s_childVault));
        _setParentPendingRebalance(AAVE_V3_PROTOCOL_ID, PARENT_CHAIN_SELECTOR);
        _storeRebalanceDepositRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_NoActiveAdapter() public {
        _clearParentActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_parentVault.executeRecovery();
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_parentVault.executeRecovery();
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_NoRebalanceInProgress() public {
        _setParentRebalanceState(Types.RebalanceState.NONE);

        vm.expectRevert(IParentVault.ParentVault__NoRebalanceInProgress.selector);
        s_parentVault.executeRecovery();
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_DepositsIntoActiveAdapter() public {
        s_parentVault.executeRecovery();

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_ClearsRecoveryState() public {
        s_parentVault.executeRecovery();

        Types.RebalanceDepositRecovery memory recovery = s_parentVault.getRebalanceDepositRecovery();
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.amount, 0);
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.NONE);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_RevertWhen_CalledAgainAfterRecoveryCompletes() public {
        s_parentVault.executeRecovery();
        assertTrue(s_parentVault.getRecoveryMode() == Types.RecoveryMode.NONE);

        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_parentVault.executeRecovery();
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_FinalizesRebalance() public {
        s_parentVault.executeRecovery();

        Types.Rebalance memory rebalance = s_parentVault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, REBALANCE_NONCE + 1);
        assertEq(rebalance.activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(rebalance.activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        s_parentVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_EmitsRebalanceDepositRecoveryCleared() public {
        vm.recordLogs();
        s_parentVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
    }

    function test_ParentVault_executeRecovery_REBALANCE_DEPOSIT_EmitsRebalanceCompleted() public {
        vm.recordLogs();
        s_parentVault.executeRecovery();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceCompleted(uint256,bytes32,uint64)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(log.topics[2], AAVE_V3_PROTOCOL_ID);
        assertEq(uint256(log.topics[3]), PARENT_CHAIN_SELECTOR);
    }

    function _storeRebalanceDepositRecovery() internal {
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(address(s_mockCcipRouter));
        deal(address(s_mockUsdc), address(s_parentVault), DEPOSIT_AMOUNT);
        s_parentVault.ccipReceive(_rebalanceMessage(REBALANCE_NONCE, AAVE_V3_PROTOCOL_ID));

        s_mockProtocolAdapter.setDepositReverts(false);
    }

    function _rebalanceMessage(uint256 rebalanceNonce, bytes32 protocolId)
        internal
        view
        returns (Client.Any2EVMMessage memory)
    {
        return
            _rebalanceMessage(CHILD_CHAIN_SELECTOR, address(s_childVault), rebalanceNonce, protocolId, DEPOSIT_AMOUNT);
    }
}
