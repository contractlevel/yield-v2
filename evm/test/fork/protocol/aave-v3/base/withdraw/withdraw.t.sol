// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Base_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(baseChild.aaveV3Adapter);
    }

    function test_Base_aaveV3_withdraw_Success_EpochWithdraw() external {
        _assertAaveV3EpochWithdrawSucceeds(baseChild.aaveV3Adapter, address(baseChild.vault), baseChild.usdc);
    }

    function test_Base_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(baseChild.aaveV3Adapter, address(baseChild.vault), baseChild.usdc);
    }
}
