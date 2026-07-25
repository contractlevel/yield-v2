// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV4ForkTest} from "../../BaseAaveV4ForkTest.t.sol";

contract Avalanche_AaveV4DepositForkTest is BaseAaveV4ForkTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_aaveV4_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV4DepositRevertsWhenCallerIsNotVault(avalancheChild.aaveV4Adapter);
    }

    function test_Avalanche_aaveV4_deposit_Success() external {
        _assertAaveV4DepositSucceeds(avalancheChild.aaveV4Adapter, address(avalancheChild.vault), avalancheChild.asset);
    }
}
