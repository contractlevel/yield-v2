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

    function test_Ethereum_compoundV3_withdraw_RevertWhen_UserWithdrawAmountExceedsTVL() external {
        _assertCompoundV3WithdrawRevertsWhenAmountExceedsTVL(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault)
        );
    }

    function test_Ethereum_compoundV3_withdraw_Success_UserWithdraw() external {
        _assertCompoundV3WithdrawSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }

    function test_Ethereum_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }
}
