// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Ethereum_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(ethereumChild.aaveV3Adapter);
    }

    function test_Ethereum_aaveV3_withdraw_Success_UserWithdraw() external {
        _assertAaveV3WithdrawSucceeds(ethereumChild.aaveV3Adapter, address(ethereumChild.vault), ethereumChild.usdc);
    }

    function test_Ethereum_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(
            ethereumChild.aaveV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }
}
