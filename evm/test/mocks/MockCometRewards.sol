// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockCometRewards {
    address public lastTo;
    address public rewardToken;

    function setRewardToken(address rewardToken_) external {
        rewardToken = rewardToken_;
    }

    function rewardConfig(address) external view returns (address) {
        return rewardToken;
    }

    function claimTo(address, address, address to, bool) external {
        lastTo = to;
    }
}
