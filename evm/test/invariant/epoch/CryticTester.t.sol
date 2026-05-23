// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {CryticAsserts} from "@chimera/CryticAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.t.sol";

contract CryticTester is TargetFunctions, CryticAsserts {
    constructor() payable {
        setup();
    }
}
