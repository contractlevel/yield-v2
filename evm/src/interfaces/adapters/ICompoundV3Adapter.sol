// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "./IProtocolAdapter.sol";

/// @title Yieldcoin v2 Compound v3 Adapter Interface
/// @author @contractlevel
/// @notice Interface for Compound v3-specific adapter behavior
interface ICompoundV3Adapter is IProtocolAdapter {
    /// @dev Thrown when the caller does not have REWARDS_OPERATOR_ROLE on the vault
    error CompoundV3Adapter__CallerNotRewardsOperator();

    /// @notice Emitted when rewards are claimed
    /// @param to The address that received the claimed rewards
    event RewardsClaimed(address indexed to);

    /// @notice Claims any rewards from the Comet Rewards contract
    /// @param to The address to receive the claimed rewards
    /// @dev Precondition: caller must have REWARDS_OPERATOR_ROLE on the vault
    /// @dev Precondition: to must not be zero address
    function claimRewards(address to) external;

    /// @notice Gets the Compound v3 rewards contract address
    /// @return cometRewards The Compound v3 rewards contract address
    function getCometRewards() external view returns (address cometRewards);
}
