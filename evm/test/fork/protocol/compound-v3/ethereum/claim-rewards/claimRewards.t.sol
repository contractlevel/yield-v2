// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Ethereum_CompoundV3ClaimRewardsForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_compoundV3_claimRewards_RevertWhen_CallerDoesNotHaveRewardsOperatorRoleOnVault() external {
        _assertCompoundV3ClaimRewardsRevertsWhenCallerIsNotRewardsOperator(ethereumChild.compoundV3Adapter);
    }

    function test_Ethereum_compoundV3_claimRewards_Success() external {
        _assertCompoundV3ClaimRewardsSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumForkDeployer
        );
    }
}
