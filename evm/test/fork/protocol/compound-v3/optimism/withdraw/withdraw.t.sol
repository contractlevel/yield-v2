// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Optimism_CompoundV3WithdrawForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_compoundV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(optimismChild.compoundV3Adapter);
    }

    function test_Optimism_compoundV3_withdraw_RevertWhen_UserWithdrawAmountExceedsTVL() external {
        _assertCompoundV3WithdrawRevertsWhenAmountExceedsTVL(
            optimismChild.compoundV3Adapter, address(optimismChild.vault)
        );
    }

    function test_Optimism_compoundV3_withdraw_Success_UserWithdraw() external {
        _assertCompoundV3WithdrawSucceeds(
            optimismChild.compoundV3Adapter, address(optimismChild.vault), optimismChild.usdc
        );
    }

    function test_Optimism_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(
            optimismChild.compoundV3Adapter, address(optimismChild.vault), optimismChild.usdc
        );
    }
}
