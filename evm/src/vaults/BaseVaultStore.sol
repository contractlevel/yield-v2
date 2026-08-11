// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 BaseVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for BaseVault mutable state
abstract contract BaseVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.BaseVault
    /// @notice Namespaced storage shared by ParentVault and ChildVault for the state common to both:
    /// CCIP gas/routing config, the locally active strategy adapter, and the singleton recovery
    /// discriminator plus rebalance-deposit recovery data.
    /// @param s_defaultCcipGasLimit Fallback CCIP gas limit used for a destination chain when no
    /// per-chain override is set in s_ccipGasLimits.
    /// @param s_ccipGasLimits Per-chain-selector CCIP gas limit override. A value of 0 means "unset",
    /// in which case s_defaultCcipGasLimit is used instead.
    /// @param s_crosschainVaults Maps a remote chain selector to the Yieldcoin vault address on that chain.
    /// Doubles as the trusted CCIP sender allow-list: only messages from the registered vault address
    /// on a given chain selector are accepted.
    /// @param s_activeProtocolAdapter Protocol adapter currently holding deposited funds on this chain.
    /// address(0) means this chain is not the active strategy chain.
    /// @param s_recoveryMode Discriminator for which recovery struct (if any) currently holds pending
    /// recovery data. The singleton invariant (at most one recovery pending at a time) is enforced by
    /// `_requireNoRecovery`, which every recovery-creating call path checks before writing this field -
    /// not by storage itself.
    /// @param s_rebalanceDepositRecovery Recovery data for a rebalance deposit that failed after funds
    /// left the source chain. Populated on Parent (same-chain rebalance) or Child (cross-chain rebalance).
    struct BaseVaultStorage {
        uint256 s_defaultCcipGasLimit;
        mapping(uint64 chainSelector => uint256 gasLimit) s_ccipGasLimits;
        mapping(uint64 chainSelector => address vault) s_crosschainVaults;
        //slither-disable-next-line uninitialized-state
        address s_activeProtocolAdapter;
        Types.RecoveryMode s_recoveryMode;
        Types.RebalanceDepositRecovery s_rebalanceDepositRecovery;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.BaseVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant BASE_VAULT_STORAGE_LOCATION =
        0x99afdd01627a14a05f9b616b4e511b7ffe10b226156d7b6f476c4380e58f9d00;

    /// @notice Returns the BaseVault namespaced storage pointer
    /// @return $ The BaseVault namespaced storage pointer
    function _baseVaultStorage() internal pure returns (BaseVaultStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := BASE_VAULT_STORAGE_LOCATION
        }
    }
}
