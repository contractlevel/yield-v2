// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Base_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(parent.aaveV3Adapter);
    }

    function test_Base_aaveV3_withdraw_Success_EpochWithdraw() external {
        _assertAaveV3EpochWithdrawSucceeds(parent.aaveV3Adapter, address(parent.vault), parent.asset);
    }

    function test_Base_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(parent.aaveV3Adapter, address(parent.vault), parent.asset);
    }
}
