// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Base_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(baseChild.compoundV3Adapter);
    }

    function test_Base_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(baseChild.compoundV3Adapter, address(baseChild.vault), baseChild.usdc);
    }
}
