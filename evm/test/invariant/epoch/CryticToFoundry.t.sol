// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.t.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
    function setUp() public override {
        setup();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = TargetFunctions.handler_deposit.selector;

        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
    }

    function test_crytic() public {
        handler_deposit(MIN_DEPOSIT_AMOUNT);
    }
}
