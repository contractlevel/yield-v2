// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.t.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
    function setUp() public override {
        setup();

        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = TargetFunctions.handler_deposit.selector;
        selectors[1] = TargetFunctions.handler_cancelDeposit.selector;
        selectors[2] = TargetFunctions.handler_closeEpoch.selector;
        selectors[3] = TargetFunctions.handler_claimShares.selector;
        selectors[4] = TargetFunctions.handler_withdraw.selector;
        selectors[5] = TargetFunctions.handler_cancelWithdraw.selector;
        selectors[6] = TargetFunctions.handler_claimUsdc.selector;

        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
    }

    function test_crytic() public {
        /// @dev Actor seed 0 selects the first configured actor
        handler_deposit(0, MIN_DEPOSIT_AMOUNT);
        handler_cancelDeposit(0, MIN_DEPOSIT_AMOUNT);
        handler_closeEpoch(0);
        handler_claimShares(0, 0, MIN_DEPOSIT_AMOUNT);
        handler_withdraw(0, MIN_DEPOSIT_AMOUNT, 0, MIN_DEPOSIT_AMOUNT);
        handler_cancelWithdraw(0, MIN_DEPOSIT_AMOUNT, 0, MIN_DEPOSIT_AMOUNT);
        handler_claimUsdc(0, 0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
    }
}
