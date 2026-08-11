// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Roles
/// @author @contractlevel
/// @notice Roles for the Yieldcoin v2 protocol
library Roles {
    /// @notice Role that administers local roles; on ParentVault, also authorizes the one-time initial adapter setup
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @notice Role authorized to upgrade vault proxy contracts
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Role authorized to pause Yieldcoin v2 contracts
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /// @notice Role authorized to unpause Yieldcoin v2 contracts
    bytes32 internal constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    /// @notice Role authorized to update vault, router, registry, and token configuration
    bytes32 internal constant CONFIG_OPERATOR_ROLE = keccak256("CONFIG_OPERATOR_ROLE");
    /// @notice Role authorizing WorkflowRouter to execute vault rebalance operations
    bytes32 internal constant REBALANCE_OPERATOR_ROLE = keccak256("REBALANCE_OPERATOR_ROLE");
    /// @notice Role authorizing WorkflowRouter to execute vault epoch operations
    bytes32 internal constant EPOCH_OPERATOR_ROLE = keccak256("EPOCH_OPERATOR_ROLE");
    /// @notice Role authorized to withdraw LINK from Yieldcoin v2 vaults
    bytes32 internal constant LINK_OPERATOR_ROLE = keccak256("LINK_OPERATOR_ROLE");
    /// @notice Role authorizing the Chainlink Keystone Forwarder to call WorkflowRouter.onReport
    bytes32 internal constant KEYSTONE_FORWARDER_ROLE = keccak256("KEYSTONE_FORWARDER_ROLE");
    /// @notice Role authorizing ParentVault to mint Yieldcoin shares
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role authorizing ParentVault to burn Yieldcoin shares
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /// @notice Role authorized to claim Compound v3 rewards through CompoundV3Adapter
    bytes32 internal constant REWARDS_OPERATOR_ROLE = keccak256("REWARDS_OPERATOR_ROLE");
    /// @notice Role authorized to force-cancel stuck deposits to unblock epoch settlement
    bytes32 internal constant CANCEL_DEPOSIT_OPERATOR_ROLE = keccak256("CANCEL_DEPOSIT_OPERATOR_ROLE");
}
