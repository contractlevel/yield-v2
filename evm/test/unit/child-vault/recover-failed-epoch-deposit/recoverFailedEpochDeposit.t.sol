// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

contract ChildVault_RecoverFailedEpochDepositUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _storeEpochDepositRecovery();
        _changePrank(i_nonOwner);
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_NoPendingRecovery() public {
        s_childVault.recoverFailedEpochDeposit();

        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_childVault.recoverFailedEpochDeposit();
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.recoverFailedEpochDeposit();
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochDeposit_RevertWhen_AdapterDepositReverts() public {
        s_mockProtocolAdapter.setDepositReverts(true);

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__DepositFailed.selector, DEPOSIT_AMOUNT));
        s_childVault.recoverFailedEpochDeposit();
        assertTrue(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_DepositsIntoActiveAdapter() public {
        s_childVault.recoverFailedEpochDeposit();

        assertEq(s_mockProtocolAdapter.getDepositCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastDepositAmount(), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_ClearsRecoveryState() public {
        s_childVault.recoverFailedEpochDeposit();

        Types.EpochRecovery memory recovery = s_childVault.getEpochDepositRecovery();
        assertEq(recovery.epochNonce, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
        assertFalse(s_childVault.getRecoveryExists());
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_EmitsDepositToStrategySuccess() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochDeposit();

        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositToStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), DEPOSIT_AMOUNT);
    }

    function test_ChildVault_recoverFailedEpochDeposit_Success_EmitsEpochDepositRecoveryCleared() public {
        vm.recordLogs();
        s_childVault.recoverFailedEpochDeposit();

        Vm.Log memory log = _assertEmittedBy(keccak256("EpochDepositRecoveryCleared(uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
    }

    // @review test name here is misleading
    function test_ChildVault_recoverFailedEpochDeposit_Success_StoresEpochNonce() public view {
        Types.EpochRecovery memory recovery = s_childVault.getEpochDepositRecovery();

        assertEq(recovery.epochNonce, EPOCH_NONCE);
        assertEq(recovery.amount, DEPOSIT_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
        assertTrue(s_childVault.getRecoveryExists());
    }

    /*//////////////////////////////////////////////////////////////
                             HELPER UTILITY
    //////////////////////////////////////////////////////////////*/
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
