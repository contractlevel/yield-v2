// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Base_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(parent.compoundV3Adapter);
    }

    function test_Base_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.asset);
    }

    function test_Base_compoundV3_deposit_OneBaseUnitSucceedsWhenCreditRoundsToZero() external {
        _assertCompoundV3OneBaseUnitDepositRoundsToZero(parent.compoundV3Adapter, address(parent.vault), parent.asset);
    }
}
