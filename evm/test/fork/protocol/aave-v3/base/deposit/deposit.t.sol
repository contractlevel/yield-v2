// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Base_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(baseChild.aaveV3Adapter);
    }

    function test_Base_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(baseChild.aaveV3Adapter, address(baseChild.vault), baseChild.asset);
    }
}
