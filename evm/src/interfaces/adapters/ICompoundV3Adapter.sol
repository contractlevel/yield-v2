// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "./IProtocolAdapter.sol";

/// @title Yieldcoin v2 Compound v3 Adapter Interface
/// @author @contractlevel
/// @notice Interface for Compound v3-specific adapter behavior
interface ICompoundV3Adapter is IProtocolAdapter {
    /// @dev Thrown when the caller does not have REWARDS_OPERATOR_ROLE on the vault
    error CompoundV3Adapter__CallerNotRewardsOperator();
    /// @dev Thrown when the configured reward token equals the vault's underlying asset or the Comet market itself
    error CompoundV3Adapter__InvalidRewardToken();

    /// @notice Emitted when rewards are claimed
    /// @param to The address that received the claimed rewards
    event RewardsClaimed(address indexed to);

    /// @notice Claims accrued rewards and sends any reward tokens already held by the adapter to the recipient
    /// @param to The address to receive the claimed rewards
    /// @dev Reverts if the caller does not have REWARDS_OPERATOR_ROLE on the vault
    /// @dev Reverts if to is the zero address
    /// @dev Reverts if the configured reward token equals the vault's underlying asset or the Comet market itself
    function claimRewards(address to) external;

    /// @notice Returns the Compound v3 rewards contract address
    /// @return cometRewards The Compound v3 rewards contract address
    function getCometRewards() external view returns (address cometRewards);
}
