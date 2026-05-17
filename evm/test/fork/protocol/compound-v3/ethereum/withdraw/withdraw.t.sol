// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Ethereum_CompoundV3WithdrawForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_compoundV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(ethereumChild.compoundV3Adapter);
    }

    function test_Ethereum_compoundV3_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        _assertCompoundV3EpochWithdrawRevertsWhenAmountExceedsTVL(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault)
        );
    }

    function test_Ethereum_compoundV3_withdraw_Success_EpochWithdraw() external {
        _assertCompoundV3EpochWithdrawSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }

    function test_Ethereum_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }
}
