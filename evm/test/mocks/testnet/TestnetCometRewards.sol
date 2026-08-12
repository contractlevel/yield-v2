// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ICometRewards} from "../../../src/interfaces/external/ICometRewards.sol";
import {IComet} from "../../../src/interfaces/external/IComet.sol";

contract TestnetCometRewards is ICometRewards {
    event RewardsClaimed(address indexed comet, address indexed src, address indexed to, bool shouldAccrue);

    function rewardConfig(address comet) external view returns (address) {
        return IComet(comet).baseToken();
    }

    function claimTo(address comet, address src, address to, bool shouldAccrue) external {
        emit RewardsClaimed(comet, src, to, shouldAccrue);
    }
}
