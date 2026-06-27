// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Optimism_CompoundV3ClaimRewardsForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_compoundV3_claimRewards_RevertWhen_CallerDoesNotHaveRewardsOperatorRoleOnVault() external {
        _assertCompoundV3ClaimRewardsRevertsWhenCallerIsNotRewardsOperator(optimismChild.compoundV3Adapter);
    }

    function test_Optimism_compoundV3_claimRewards_Success() external {
        _assertCompoundV3ClaimRewardsSucceeds(
            optimismChild.compoundV3Adapter, address(optimismChild.vault), optimismForkDeployer
        );
    }
}
