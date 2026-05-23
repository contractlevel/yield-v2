// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {CcipGhosts} from "../shared/CcipGhosts.t.sol";

abstract contract EpochGhosts is CcipGhosts {
    uint256 internal ghost_totalDeposited;
    mapping(address actor => uint256 amount) internal ghost_totalDepositedByActor;

    function _clampDepositAmount(uint256 amountSeed) internal pure returns (uint256) {
        return _boundToRange(amountSeed, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
    }

    function _recordDeposit(address actor, uint256 amount) internal {
        ghost_totalDeposited += amount;
        ghost_totalDepositedByActor[actor] += amount;
    }
}
