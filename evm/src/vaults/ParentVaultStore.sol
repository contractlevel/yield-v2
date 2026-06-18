// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 ParentVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for ParentVault mutable state.
abstract contract ParentVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.ParentVault
    struct ParentVaultStorage {
        /// @dev Current rebalance state.
        Types.Rebalance s_rebalance;
        /// @dev Total number of Yieldcoin shares minted and available to claim
        /// @notice One subtlety: between closeEpoch and the last claimAsset call for an epoch, s_totalShares could be decremented but the actual Yieldcoin share tokens haven't been burned yet.
        /// The i_share.totalSupply() will be higher than s_totalShares during this window. Therefore we never use i_share.totalSupply() as an authoritative share count — always use s_totalShares.
        uint256 s_totalShares;
        /// @dev Highest price per share ever recorded for performance fee purposes
        uint256 s_performanceFeeHighWaterMark;
        /// @dev Current epoch nonce
        uint256 s_epochNonce;
        /// @dev Epochs
        mapping(uint256 epochNonce => Types.Epoch) s_epochs;
        /// @dev Mapping of depositors to their deposits for each epoch
        mapping(address depositor => mapping(uint256 epochId => uint256 assetAmount)) s_deposits;
        /// @dev Mapping of withdrawers to their withdraw intents for each epoch
        mapping(address withdrawer => mapping(uint256 epochId => uint256 shareBurnAmount)) s_withdraws;
        /// @dev Mapping of protocolIds supported by Yieldcoin v2 across chains
        /// @notice This CAN include protocols that are NOT supported on this chain. Ie if Parent is on Arb, and AaveV4 is only on Ethereum, but we support it, we don't want a check in initiateRebalance to be based on the local AdapterRegistry
        mapping(bytes32 protocolId => bool isSupported) s_supportedProtocol;
        /// @dev Treasury address for collecting fees. This should be the protocol operator's multisig.
        address s_treasury;
        /// @dev Whether the initial active protocol adapter has been set
        bool s_initialActiveProtocolAdapterSet;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.ParentVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant PARENT_VAULT_STORAGE_LOCATION =
        0x4d89b729d7d5f9a6740a79abcbedc524fd1c9bd2e1f192f6caeffd6a1cf4ea00;

    function _parentVaultStorage() internal pure returns (ParentVaultStorage storage $) {
        assembly {
            $.slot := PARENT_VAULT_STORAGE_LOCATION
        }
    }
}
