// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Arbitrum_CompoundV3WithdrawForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_compoundV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3WithdrawRevertsWhenCallerIsNotVault(arbitrumChild.compoundV3Adapter);
    }

    function test_Arbitrum_compoundV3_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        _assertCompoundV3EpochWithdrawRevertsWhenAmountExceedsTVL(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault)
        );
    }

    function test_Arbitrum_compoundV3_withdraw_Success_EpochWithdraw() external {
        _assertCompoundV3EpochWithdrawSucceeds(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault), arbitrumChild.asset
        );
    }

    function test_Arbitrum_compoundV3_withdraw_Success_RebalanceWithdraw() external {
        _assertCompoundV3RebalanceWithdrawSucceeds(
            arbitrumChild.compoundV3Adapter, address(arbitrumChild.vault), arbitrumChild.asset
        );
    }
}
