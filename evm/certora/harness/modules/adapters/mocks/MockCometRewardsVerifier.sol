// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockCometRewardsVerifier {
    address internal immutable i_rewardToken;
    address internal s_rewardTokenOverride;
    bool internal s_rewardTokenOverridden;
    address public s_lastComet;
    address public s_lastSrc;
    address public s_lastTo;
    bool public s_lastShouldAccrue;
    uint256 public s_claimToCallCount;

    constructor(address rewardToken) {
        i_rewardToken = rewardToken;
    }

    function disableRewardToken() external {
        s_rewardTokenOverride = address(0);
        s_rewardTokenOverridden = true;
    }

    function setRewardToken(address rewardToken) external {
        s_rewardTokenOverride = rewardToken;
        s_rewardTokenOverridden = true;
    }

    function rewardConfig(address) external view returns (address) {
        return s_rewardTokenOverridden ? s_rewardTokenOverride : i_rewardToken;
    }

    function claimTo(address comet, address src, address to, bool shouldAccrue) external {
        s_lastComet = comet;
        s_lastSrc = src;
        s_lastTo = to;
        s_lastShouldAccrue = shouldAccrue;
        ++s_claimToCallCount;
    }
}
