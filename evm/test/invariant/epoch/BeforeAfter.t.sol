// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {EpochGhosts} from "./EpochGhosts.t.sol";

abstract contract BeforeAfter is EpochGhosts {
    struct Vars {
        uint256 epochNonce;
        uint256 totalShares;
        uint256 currentEpochTotalDepositAmount;
        uint256 actorCurrentEpochDepositAmount;
    }

    Vars internal _before;
    Vars internal _after;

    function __before() internal {
        uint256 epochNonce = parent.vault.getEpochNonce();
        _before.epochNonce = epochNonce;
        _before.totalShares = parent.vault.getTotalShares();
        _before.currentEpochTotalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        _before.actorCurrentEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, epochNonce);
    }

    function __after() internal {
        uint256 epochNonce = parent.vault.getEpochNonce();
        _after.epochNonce = epochNonce;
        _after.totalShares = parent.vault.getTotalShares();
        _after.currentEpochTotalDepositAmount = parent.vault.getEpoch(epochNonce).totalDepositAmount;
        _after.actorCurrentEpochDepositAmount = parent.vault.getDepositAmount(s_currentActor, epochNonce);
    }
}
