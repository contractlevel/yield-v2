// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Base_CompoundV3WithdrawForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_compoundV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(baseChild.compoundV3Adapter);
    }

    function test_Base_compoundV3_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        _assertCompoundV3EpochWithdrawRevertsWhenAmountExceedsTVL(baseChild.compoundV3Adapter, address(baseChild.vault));
    }

    function test_Base_compoundV3_withdraw_Success_EpochWithdraw() external {
        _assertCompoundV3EpochWithdrawSucceeds(baseChild.compoundV3Adapter, address(baseChild.vault), baseChild.asset);
    }

    function test_Base_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(
            baseChild.compoundV3Adapter, address(baseChild.vault), baseChild.asset
        );
    }
}
