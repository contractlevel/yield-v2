// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Arbitrum_CompoundV3ClaimRewardsForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_compoundV3_claimRewards_RevertWhen_CallerDoesNotHaveRewardsOperatorRoleOnVault() external {
        _assertCompoundV3ClaimRewardsRevertsWhenCallerIsNotRewardsOperator(arbitrumChild.compoundV3Adapter);
    }

    function test_Arbitrum_compoundV3_claimRewards_Success() external {
        _assertCompoundV3ClaimRewardsSucceeds(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault), arbitrumForkDeployer
        );
    }
}
