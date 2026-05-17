// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Arbitrum_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(parent.aaveV3Adapter);
    }

    function test_Arbitrum_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(parent.aaveV3Adapter, address(parent.vault), parent.usdc);
    }
}
