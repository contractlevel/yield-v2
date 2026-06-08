// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4ForkTest} from "../../BaseAaveV4ForkTest.t.sol";

contract Ethereum_AaveV4DepositForkTest is BaseAaveV4ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_aaveV4_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV4DepositRevertsWhenCallerIsNotVault(ethereumChild.aaveV4Adapter);
    }

    function test_Ethereum_aaveV4_deposit_Success() external {
        _assertAaveV4DepositSucceeds(ethereumChild.aaveV4Adapter, address(ethereumChild.vault), ethereumChild.asset);
    }
}
