// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3AdapterUnitTest, Vm} from "../BaseCompoundV3AdapterUnitTest.t.sol";

import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

contract CompoundV3Adapter_ClaimRewardsUnitTest is BaseCompoundV3AdapterUnitTest {
    address private s_rewardsOperator = makeAddr("rewardsOperator");

    function setUp() public {
        _changePrank(i_owner);
        s_parentVault.grantRole(Roles.REWARDS_OPERATOR_ROLE, s_rewardsOperator);
    }

    function test_CompoundV3Adapter_claimRewards_RevertWhen_CallerNotRewardsOperator() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__CallerNotRewardsOperator.selector);
        s_compoundV3Adapter.claimRewards(i_nonOwner);
    }

    function test_CompoundV3Adapter_claimRewards_RevertWhen_ToIsZeroAddress() external {
        _changePrank(s_rewardsOperator);
        vm.expectRevert(CompoundV3Adapter.CompoundV3Adapter__NoZeroAddress.selector);
        s_compoundV3Adapter.claimRewards(address(0));
    }

    function test_CompoundV3Adapter_claimRewards_Success() external {
        _changePrank(s_rewardsOperator);
        vm.recordLogs();
        s_compoundV3Adapter.claimRewards(i_nonOwner);

        Vm.Log memory log = _assertEmittedBy(keccak256("RewardsClaimed(address)"), address(s_compoundV3Adapter));
        assertEq(address(uint160(uint256(log.topics[1]))), i_nonOwner);
        assertEq(s_mockCometRewards.lastTo(), i_nonOwner);
    }
}
