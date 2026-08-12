// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockCometRewards {
    address internal immutable i_rewardToken;
    address internal s_lastTo;

    constructor(address rewardToken) {
        i_rewardToken = rewardToken;
    }

    function rewardConfig(address) external view returns (address) {
        return i_rewardToken;
    }

    function claimTo(address, address, address to, bool) external {
        s_lastTo = to;
    }

    function lastTo() external view returns (address) {
        return s_lastTo;
    }
}
