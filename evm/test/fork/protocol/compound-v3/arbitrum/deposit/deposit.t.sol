// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Arbitrum_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(arbitrumChild.compoundV3Adapter);
    }

    function test_Arbitrum_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault), arbitrumChild.asset
        );
    }

    function test_Arbitrum_compoundV3_deposit_OneBaseUnitSucceedsWhenCreditRoundsToZero() external {
        _assertCompoundV3OneBaseUnitDepositRoundsToZero(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault), arbitrumChild.asset
        );
    }
}
