// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Optimism_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(optimismChild.compoundV3Adapter);
    }

    function test_Optimism_compoundV3_deposit_OneBaseUnitSucceedsWhenCreditRoundsToZero() external {
        _assertCompoundV3OneBaseUnitDepositRoundsToZero(
            optimismChild.compoundV3Adapter, address(optimismChild.vault), optimismChild.asset
        );
    }

    function test_Optimism_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(
            optimismChild.compoundV3Adapter, address(optimismChild.vault), optimismChild.asset
        );
    }
}
