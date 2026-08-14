// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVault_GetChildOperationalStateUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    uint256 internal constant TVL = 1_000 * 1e6;
    uint256 internal constant EPOCH_RECOVERY_AMOUNT = 100 * 1e6;
    uint256 internal constant REBALANCE_RECOVERY_AMOUNT = 200 * 1e6;
    uint256 internal constant CCIP_RECOVERY_AMOUNT = 300 * 1e6;
    uint256 internal constant LAST_HANDLED_EPOCH_NONCE = 7;
    uint256 internal constant LAST_HANDLED_REBALANCE_NONCE = 9;

    function test_ChildVault_getChildOperationalState_Success() external {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildRecoveryMode(Types.RecoveryMode.EPOCH_DEPOSIT);
        _setLastHandledNonces(LAST_HANDLED_EPOCH_NONCE, LAST_HANDLED_REBALANCE_NONCE);
        _setEpochDepositRecoveryAmount(EPOCH_RECOVERY_AMOUNT);
        _setRebalanceDepositRecoveryAmount(REBALANCE_RECOVERY_AMOUNT);
        _setChildCcipSendRecoveryAmount(CCIP_RECOVERY_AMOUNT);
        s_mockProtocolAdapter.setTVL(TVL);

        _changePrank(i_pauser);
        s_childVault.pause();

        Types.ChildOperationalState memory state = s_childVault.getChildOperationalState();

        assertTrue(state.paused);
        assertEq(uint256(state.recoveryMode), uint256(Types.RecoveryMode.EPOCH_DEPOSIT));
        assertEq(state.lastHandledEpochNonce, LAST_HANDLED_EPOCH_NONCE);
        assertEq(state.lastHandledRebalanceNonce, LAST_HANDLED_REBALANCE_NONCE);
        assertEq(state.tvl, TVL + EPOCH_RECOVERY_AMOUNT + REBALANCE_RECOVERY_AMOUNT + CCIP_RECOVERY_AMOUNT);
        assertEq(state.tvl, s_childVault.getTVL());
    }

    function test_ChildVault_getChildOperationalState_ReturnsCcipSendRecoveryTVLWhen_NoActiveAdapter() external {
        _clearChildActiveAdapter();
        _setChildCcipSendRecoveryAmount(CCIP_RECOVERY_AMOUNT);

        Types.ChildOperationalState memory state = s_childVault.getChildOperationalState();

        assertEq(state.tvl, CCIP_RECOVERY_AMOUNT);
        assertEq(state.tvl, s_childVault.getTVL());
    }

    function _setChildRecoveryMode(Types.RecoveryMode mode) internal {
        stdstore.enable_packed_slots().target(address(s_childVault)).sig("getRecoveryMode()")
            .checked_write(uint256(mode));
    }

    function _setLastHandledNonces(uint256 epochNonce, uint256 rebalanceNonce) internal {
        stdstore.target(address(s_childVault)).sig("getLastHandledEpochNonce()").checked_write(epochNonce);
        stdstore.target(address(s_childVault)).sig("getLastHandledRebalanceNonce()").checked_write(rebalanceNonce);
    }

    function _setEpochDepositRecoveryAmount(uint256 amount) internal {
        stdstore.target(address(s_childVault)).sig("getEpochDepositRecovery()").depth(1).checked_write(amount);
    }

    function _setRebalanceDepositRecoveryAmount(uint256 amount) internal {
        stdstore.target(address(s_childVault)).sig("getRebalanceDepositRecovery()").depth(1).checked_write(amount);
    }
}
