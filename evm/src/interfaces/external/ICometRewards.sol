// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Compound V3 Comet Rewards Interface
/// @notice Minimal Compound V3 CometRewards interface used by the CompoundV3Adapter
interface ICometRewards {
    function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}
