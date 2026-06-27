// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Optimism_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(optimismChild.aaveV3Adapter);
    }

    function test_Optimism_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(optimismChild.aaveV3Adapter, address(optimismChild.vault), optimismChild.asset);
    }
}
