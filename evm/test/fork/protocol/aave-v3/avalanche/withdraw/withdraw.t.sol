// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Avalanche_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(avalancheChild.aaveV3Adapter);
    }

    function test_Avalanche_aaveV3_withdraw_Success_UserWithdraw() external {
        _assertAaveV3WithdrawSucceeds(avalancheChild.aaveV3Adapter, address(avalancheChild.vault), avalancheChild.usdc);
    }

    function test_Avalanche_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(
            avalancheChild.aaveV3Adapter, address(avalancheChild.vault), avalancheChild.usdc
        );
    }
}
