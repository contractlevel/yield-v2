// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Ethereum_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(ethereumChild.aaveV3Adapter);
    }

    function test_Ethereum_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(ethereumChild.aaveV3Adapter, address(ethereumChild.vault), ethereumChild.asset);
    }
}
