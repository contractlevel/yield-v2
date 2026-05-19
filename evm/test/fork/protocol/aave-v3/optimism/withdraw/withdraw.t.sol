// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Optimism_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(optimismChild.aaveV3Adapter);
    }

    function test_Optimism_aaveV3_withdraw_Success_EpochWithdraw() external {
        _assertAaveV3EpochWithdrawSucceeds(
            optimismChild.aaveV3Adapter, address(optimismChild.vault), optimismChild.usdc
        );
    }

    function test_Optimism_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(
            optimismChild.aaveV3Adapter, address(optimismChild.vault), optimismChild.usdc
        );
    }
}
