// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

contract ChildVault_RecoverFailedRebalanceDepositUnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant DEPOSIT_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _storeRebalanceDepositRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedRebalanceDeposit(2);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_Success_DepositsIntoActiveAdapter() public {
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_Success_ClearsRecoveryState() public {
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);

        Types.AmountRecovery memory recovery = s_childVault.getRebalanceDepositRecovery(REBALANCE_NONCE);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_Success_EmitsRebalanceDepositSuccess() public {
        vm.recordLogs();
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositSuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedRebalanceDeposit_Success_EmitsRebalanceDepositRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.recoverFailedRebalanceDeposit(REBALANCE_NONCE);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("RebalanceDepositRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), REBALANCE_NONCE);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _storeRebalanceDepositRecovery() internal {
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
