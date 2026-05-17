// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCompoundV3ForkTest} from "../../BaseCompoundV3ForkTest.t.sol";

contract Ethereum_CompoundV3DepositForkTest is BaseCompoundV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_compoundV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertCompoundV3DepositRevertsWhenCallerIsNotVault(ethereumChild.compoundV3Adapter);
    }

    function test_Ethereum_compoundV3_deposit_Success() external {
        _assertCompoundV3DepositSucceeds(
            ethereumChild.compoundV3Adapter, address(ethereumChild.vault), ethereumChild.usdc
        );
    }
}
