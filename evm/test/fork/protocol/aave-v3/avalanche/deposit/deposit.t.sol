// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Avalanche_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(avalancheChild.aaveV3Adapter);
    }

    function test_Avalanche_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(avalancheChild.aaveV3Adapter, address(avalancheChild.vault), avalancheChild.asset);
    }
}
