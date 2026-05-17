// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Arbitrum_CompoundV3WithdrawForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_compoundV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(parent.compoundV3Adapter);
    }

    // @review UserWithdraw should be renamed EpochWithdraw across the codebase where appropriate
    function test_Arbitrum_compoundV3_withdraw_RevertWhen_UserWithdrawAmountExceedsTVL() external {
        _assertCompoundV3WithdrawRevertsWhenAmountExceedsTVL(parent.compoundV3Adapter, address(parent.vault));
    }

    function test_Arbitrum_compoundV3_withdraw_Success_UserWithdraw() external {
        _assertCompoundV3WithdrawSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.usdc);
    }

    function test_Arbitrum_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.usdc);
    }
}
