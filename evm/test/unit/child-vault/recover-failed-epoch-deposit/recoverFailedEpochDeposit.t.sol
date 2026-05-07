// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";

contract ChildVault_RecoverFailedEpochDepositUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant DEPOSIT_AMOUNT = 500 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _storeEpochDepositRecovery();
        _changePrank(i_recoveryOperator);
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_CallerDoesNotHaveRECOVERY_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        vm.expectRevert();
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedEpochDeposit(2);
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_DepositsIntoActiveAdapter() public {
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_ClearsRecoveryState() public {
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);

        Types.AmountRecovery memory recovery = s_childVault.getEpochDepositRecovery(EPOCH_NONCE);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_EmitsDepositToStrategySuccess() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositToStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_EmitsEpochDepositRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochDeposit(EPOCH_NONCE);

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochDepositRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
    function _storeEpochDepositRecovery() internal {
        s_mockProtocolAdapter.setDepositReverts(true);

        _changePrank(address(s_mockCcipRouter));
        s_childVault.ccipReceive(_depositMessage(EPOCH_NONCE));

        s_mockProtocolAdapter.setDepositReverts(false);
    }

    function _depositMessage(uint256 epochNonce) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            PARENT_CHAIN_SELECTOR, address(s_parentVault), Types.CcipTx.DEPOSIT, abi.encode(epochNonce), DEPOSIT_AMOUNT
        );
    }
}
