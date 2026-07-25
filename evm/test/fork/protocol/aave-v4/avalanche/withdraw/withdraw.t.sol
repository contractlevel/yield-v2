// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV4ForkTest} from "../../BaseAaveV4ForkTest.t.sol";

contract Avalanche_AaveV4WithdrawForkTest is BaseAaveV4ForkTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_aaveV4_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV4WithdrawRevertsWhenCallerIsNotVault(avalancheChild.aaveV4Adapter);
    }

    function test_Avalanche_aaveV4_withdraw_Success_EpochWithdraw() external {
        _assertAaveV4EpochWithdrawSucceeds(
            avalancheChild.aaveV4Adapter, address(avalancheChild.vault), avalancheChild.asset
        );
    }

    function test_Avalanche_aaveV4_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV4RebalanceWithdrawSucceeds(
            avalancheChild.aaveV4Adapter, address(avalancheChild.vault), avalancheChild.asset
        );
    }
}
