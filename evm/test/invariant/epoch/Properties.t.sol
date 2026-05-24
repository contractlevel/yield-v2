// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BeforeAfter} from "./BeforeAfter.t.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Types} from "../../../src/libraries/Types.sol";

abstract contract Properties is BeforeAfter, Asserts {
    function invariant_EPOCH_001_currentEpochIsOpen() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        t(
            parent.vault.getEpoch(currentEpochNonce).status == Types.EpochStatus.OPEN,
            "EPOCH-001: current epoch is not open"
        );
    }

    function invariant_depositGhostMatchesOpenEpochTotal() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        eq(
            parent.vault.getEpoch(currentEpochNonce).totalDepositAmount,
            ghost_totalDepositedByEpoch[currentEpochNonce],
            "deposit ghost does not match open epoch total"
        );
    }
}
