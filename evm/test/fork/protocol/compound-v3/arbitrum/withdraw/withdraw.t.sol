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

    function test_Arbitrum_compoundV3_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        _assertCompoundV3EpochWithdrawRevertsWhenAmountExceedsTVL(parent.compoundV3Adapter, address(parent.vault));
    }

    function test_Arbitrum_compoundV3_withdraw_Success_EpochWithdraw() external {
        _assertCompoundV3EpochWithdrawSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.asset);
    }

    function test_Arbitrum_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(parent.compoundV3Adapter, address(parent.vault), parent.asset);
    }
}
