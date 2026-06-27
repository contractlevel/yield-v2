// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Arbitrum_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(parent.compoundV3Adapter);
    }

    function test_Arbitrum_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.asset);
    }
}
