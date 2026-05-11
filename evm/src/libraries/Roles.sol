// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @author @contractlevel
/// @notice Roles for the Yieldcoin v2 protocol
library Roles {
    /// @notice Default admin role grants and revokes other roles
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @notice Upgrader role can upgrade proxy contracts
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Pauser role for pausing the Yieldcoin v2 infrastructure
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /// @notice Unpauser role for unpausing the Yieldcoin v2 infrastructure
    bytes32 internal constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    /// @notice Config operator role for setting configuration state such as the allowed crosschain vaults for sending and receiving CCIP messages
    bytes32 internal constant CONFIG_OPERATOR_ROLE = keccak256("CONFIG_OPERATOR_ROLE");
    /// @notice Rebalance operator role for rebalancing the Yieldcoin v2 protocol. Granted to WorkflowRouter.
    bytes32 internal constant REBALANCE_OPERATOR_ROLE = keccak256("REBALANCE_OPERATOR_ROLE");
    /// @notice Epoch operator role for managing epochs in the Yieldcoin v2 protocol. Granted to WorkflowRouter.
    bytes32 internal constant EPOCH_OPERATOR_ROLE = keccak256("EPOCH_OPERATOR_ROLE");
    /// @notice Link operator role for withdrawing LINK from the Yieldcoin v2 vaults
    bytes32 internal constant LINK_OPERATOR_ROLE = keccak256("LINK_OPERATOR_ROLE");
    /// @notice Compliance operator role for compliance actions: forced transfers, freeze/unfreeze, pause/unpause through ACE RBAC
    bytes32 internal constant COMPLIANCE_OPERATOR_ROLE = keccak256("COMPLIANCE_OPERATOR_ROLE");
    /// @notice Emergency drainer roles for withdrawing all USDC from the Yieldcoin v2 vaults
    bytes32 internal constant EMERGENCY_DRAINER_ROLE = keccak256("EMERGENCY_DRAINER_ROLE");
    /// @notice ChainlinkCRE Keystone Forwarder calls WorkflowRouter::onReport
    bytes32 internal constant KEYSTONE_FORWARDER_ROLE = keccak256("KEYSTONE_FORWARDER_ROLE");
    /// @notice Policy engine manager role for replacing attached policy engines
    bytes32 internal constant POLICY_ENGINE_MANAGER_ROLE = keccak256("POLICY_ENGINE_MANAGER_ROLE");
    /// @notice Minter role for minting Yieldcoin shares. Granted to ParentVault through ACE RoleBasedAccessControlPolicy.
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Burner role for burning Yieldcoin shares. Granted to ParentVault through ACE RoleBasedAccessControlPolicy.
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
}
