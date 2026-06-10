// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Base_CompoundV3ClaimRewardsForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_compoundV3_claimRewards_RevertWhen_CallerDoesNotHaveRewardsOperatorRoleOnVault() external {
        _assertCompoundV3ClaimRewardsRevertsWhenCallerIsNotRewardsOperator(baseChild.compoundV3Adapter);
    }

    function test_Base_compoundV3_claimRewards_Success() external {
        _assertCompoundV3ClaimRewardsSucceeds(baseChild.compoundV3Adapter, address(baseChild.vault), baseForkDeployer);
    }
}
