// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 ChildVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for ChildVault mutable state.
abstract contract ChildVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.ChildVault
    struct ChildVaultStorage {
        /// @dev Recovery state for failed rebalance withdraw operations
        Types.RebalanceWithdrawRecovery s_rebalanceWithdrawRecovery;
        /// @dev Recovery state for failed epoch deposit operations
        Types.EpochRecovery s_epochDepositRecovery;
        /// @dev Recovery state for failed epoch withdraw operations
        Types.EpochRecovery s_epochWithdrawRecovery;
        /// @dev Recovery state for failed CCIP send operations
        Types.CcipSendRecovery s_ccipSendRecovery;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.ChildVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant CHILD_VAULT_STORAGE_LOCATION =
        0x78e4dbdeeaf798c2dd37013d97b7b9a2111b1f613652054109dec720ccf6f400;

    function _childVaultStorage() internal pure returns (ChildVaultStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := CHILD_VAULT_STORAGE_LOCATION
        }
    }
}
