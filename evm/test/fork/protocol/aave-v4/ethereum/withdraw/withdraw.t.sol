// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4ForkTest} from "../../BaseAaveV4ForkTest.t.sol";

contract Ethereum_AaveV4WithdrawForkTest is BaseAaveV4ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_aaveV4_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV4WithdrawRevertsWhenCallerIsNotVault(ethereumChild.aaveV4Adapter);
    }

    function test_Ethereum_aaveV4_withdraw_Success_EpochWithdraw() external {
        _assertAaveV4EpochWithdrawSucceeds(ethereumChild.aaveV4Adapter, address(ethereumChild.vault), ethereumChild.usdc);
    }

    function test_Ethereum_aaveV4_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV4RebalanceWithdrawSucceeds(
            ethereumChild.aaveV4Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }
}
