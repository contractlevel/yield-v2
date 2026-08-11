// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 ParentVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for ParentVault mutable state
abstract contract ParentVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.ParentVault
    /// @notice Namespaced storage for ParentVault mutable state: the active/pending rebalance, share
    /// accounting, epoch deposit and withdraw bookkeeping, the cross-chain protocol allow-list, and
    /// one-time initialization flags.
    /// @param s_rebalance Current rebalance nonce, state (NONE/REBALANCING), active and pending
    /// strategy, and the timestamp the last rebalance completed.
    /// @param s_totalShares Authoritative running total of Yieldcoin shares - NOT i_share.totalSupply().
    /// Includes already-circulating (minted, unburned) shares plus fee shares, and is updated for an
    /// epoch's pending deposit and withdraw deltas at closeEpoch time, before the corresponding mint/burn
    /// actually happens at claim time. Between closeEpoch and the last claimAsset call for an epoch,
    /// s_totalShares can already be decremented for pending burns while the corresponding share tokens
    /// have not yet been burned, so totalSupply() would read higher than the true count during that window.
    /// @param s_performanceFeeHighWaterMark Highest price-per-share ever recorded; performance fees
    /// are only charged on price-per-share growth above this mark.
    /// @param s_epochNonce Nonce of the currently open epoch. Starts at 1 in initialize(), so a
    /// previous epoch nonce of 0 means no prior epoch exists.
    /// @param s_epochs Per-epoch-nonce accounting: total deposit and withdraw amounts, price per share,
    /// remaining claimable amounts, open timestamp, and status.
    /// @param s_deposits Per-depositor, per-epoch underlying-asset amount deposited.
    /// @param s_withdraws Per-withdrawer, per-epoch share amount escrowed for burning.
    /// @param s_supportedProtocol Protocol IDs Yieldcoin v2 supports across all chains. This CAN include
    /// protocols not deployed on this specific chain - e.g. if Parent is on Arbitrum and AaveV4 only
    /// exists on Ethereum but is still a supported protocol, initiateRebalance must not gate this check
    /// on the local chain's AdapterRegistry.
    /// @param s_treasury Address that receives protocol fees; should be the protocol operator's multisig.
    /// @param s_initialActiveProtocolAdapterSet Whether the first active protocol adapter has been set.
    /// Guards the one-time initial adapter setup from being repeated.
    struct ParentVaultStorage {
        Types.Rebalance s_rebalance;
        uint256 s_totalShares;
        uint256 s_performanceFeeHighWaterMark;
        uint256 s_epochNonce;
        mapping(uint256 epochNonce => Types.Epoch) s_epochs;
        mapping(address depositor => mapping(uint256 epochId => uint256 assetAmount)) s_deposits;
        mapping(address withdrawer => mapping(uint256 epochId => uint256 shareBurnAmount)) s_withdraws;
        mapping(bytes32 protocolId => bool isSupported) s_supportedProtocol;
        address s_treasury;
        bool s_initialActiveProtocolAdapterSet;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.ParentVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant PARENT_VAULT_STORAGE_LOCATION =
        0x4d89b729d7d5f9a6740a79abcbedc524fd1c9bd2e1f192f6caeffd6a1cf4ea00;

    /// @notice Returns the ParentVault namespaced storage pointer
    /// @return $ The ParentVault namespaced storage pointer
    function _parentVaultStorage() internal pure returns (ParentVaultStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := PARENT_VAULT_STORAGE_LOCATION
        }
    }
}
