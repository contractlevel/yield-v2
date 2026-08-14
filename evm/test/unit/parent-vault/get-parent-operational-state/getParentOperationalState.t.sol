// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";

contract ParentVault_GetParentOperationalStateUnitTest is BaseUnitTest {
    uint256 internal constant TVL = 1_000 * 1e6;

    function test_ParentVault_getParentOperationalState_Success() external {
        s_mockProtocolAdapter.setTVL(TVL);

        _changePrank(i_pauser);
        s_parentVault.pause();

        Types.ParentOperationalState memory state = s_parentVault.getParentOperationalState();
        uint256 currentEpochNonce = s_parentVault.getEpochNonce();

        assertTrue(state.paused);
        assertEq(uint256(state.recoveryMode), uint256(s_parentVault.getRecoveryMode()));
        assertEq(state.currentEpochNonce, currentEpochNonce);
        assertEq(
            keccak256(abi.encode(state.currentEpoch)), keccak256(abi.encode(s_parentVault.getEpoch(currentEpochNonce)))
        );
        assertEq(
            keccak256(abi.encode(state.previousEpoch)),
            keccak256(abi.encode(s_parentVault.getEpoch(currentEpochNonce - 1)))
        );
        assertEq(keccak256(abi.encode(state.rebalance)), keccak256(abi.encode(s_parentVault.getRebalance())));
        assertEq(state.tvl, TVL);
        assertEq(state.tvl, s_parentVault.getTVL());
    }

    function test_ParentVault_getParentOperationalState_ReturnsZeroTVLWhen_NoActiveAdapter() external {
        _clearParentActiveAdapter();

        Types.ParentOperationalState memory state = s_parentVault.getParentOperationalState();

        assertEq(state.tvl, 0);
        assertEq(state.tvl, s_parentVault.getTVL());
    }
}
