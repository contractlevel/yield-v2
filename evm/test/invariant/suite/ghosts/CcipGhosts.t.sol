// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ActorGhosts} from "./ActorGhosts.t.sol";

abstract contract CcipGhosts is ActorGhosts {
    enum Mode {
        SYNC,
        ASYNC
    }

    uint256 internal constant MAX_PENDING_CCIP = 32;

    Mode internal s_mode = Mode.SYNC;

    mapping(uint64 srcChainSelector => mapping(uint64 dstChainSelector => uint256 count)) internal ghost_inflightCount;
    mapping(uint64 srcChainSelector => mapping(uint64 dstChainSelector => uint256 amount)) internal ghost_inflightUsdc;
    uint256 internal ghost_pendingCcipLength;

    function _pendingCcipQueueIsNotFull() internal view returns (bool) {
        return ghost_pendingCcipLength < MAX_PENDING_CCIP;
    }
}
