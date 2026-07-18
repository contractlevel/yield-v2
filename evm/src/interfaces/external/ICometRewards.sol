// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Compound V3 Comet Rewards Interface
/// @notice Minimal Compound V3 CometRewards interface used by the CompoundV3Adapter
interface ICometRewards {
    /// @notice Claims rewards accrued by `src` in the given Comet instance and sends them to `to`
    /// @param comet The address of the Comet instance rewards are being claimed from
    /// @param src The address that has accrued the rewards being claimed
    /// @param to The address to receive the claimed rewards
    /// @param shouldAccrue Whether to accrue rewards for `src` before claiming
    function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}
