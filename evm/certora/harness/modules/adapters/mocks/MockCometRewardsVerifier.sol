// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockCometRewardsVerifier {
    address internal immutable i_rewardToken;
    bool internal s_rewardTokenDisabled;
    address public s_lastComet;
    address public s_lastSrc;
    address public s_lastTo;
    bool public s_lastShouldAccrue;
    uint256 public s_claimToCallCount;

    constructor(address rewardToken) {
        i_rewardToken = rewardToken;
    }

    function disableRewardToken() external {
        s_rewardTokenDisabled = true;
    }

    function rewardConfig(address) external view returns (address) {
        return s_rewardTokenDisabled ? address(0) : i_rewardToken;
    }

    function claimTo(address comet, address src, address to, bool shouldAccrue) external {
        s_lastComet = comet;
        s_lastSrc = src;
        s_lastTo = to;
        s_lastShouldAccrue = shouldAccrue;
        ++s_claimToCallCount;
    }
}
