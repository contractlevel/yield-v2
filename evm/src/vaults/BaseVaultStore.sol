// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 BaseVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for BaseVault mutable state.
abstract contract BaseVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.BaseVault
    struct BaseVaultStorage {
        /// @dev Default CCIP gas limit
        uint256 s_defaultCcipGasLimit;
        /// @dev Mapping of chain selectors to CCIP gas limits
        mapping(uint64 chainSelector => uint256 gasLimit) s_ccipGasLimits;
        /// @dev Mapping of chain selectors to crosschain vault addresses - also trusted CCIP senders allow list
        /// @notice The Parent chain should include itself as a trusted CCIP sender and set its own vault address because it is checked in initiateRebalance
        mapping(uint64 chainSelector => address vault) s_crosschainVaults;
        /// @dev Active strategy protocol adapter for this chain. If this is address(0), this chain is NOT the active strategy chain
        //slither-disable-next-line uninitialized-state
        address s_activeProtocolAdapter;
        /// @dev Timestamp when the vault was paused. Deleted when the vault is unpaused.
        /// @notice This is used for emergency recovery modes.
        uint96 s_pausedAt;
        /// @dev Address that receives the underlying asset during emergency drain.
        address s_emergencyReceiver;
        /// @dev Active recovery discriminator. Enforces the singleton invariant at the store layer.
        Types.RecoveryMode s_recoveryMode;
        /// @dev Recovery state for failed rebalance deposit operations. This can exist on Parent or Child.
        Types.RebalanceDepositRecovery s_rebalanceDepositRecovery;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.BaseVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant BASE_VAULT_STORAGE_LOCATION =
        0x99afdd01627a14a05f9b616b4e511b7ffe10b226156d7b6f476c4380e58f9d00;

    function _baseVaultStorage() internal pure returns (BaseVaultStorage storage $) {
        assembly {
            $.slot := BASE_VAULT_STORAGE_LOCATION
        }
    }
}
