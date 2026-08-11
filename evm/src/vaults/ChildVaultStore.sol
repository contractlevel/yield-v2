// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 ChildVault namespaced storage
/// @author @contractlevel
/// @notice ERC-7201 storage for ChildVault mutable state
abstract contract ChildVaultStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.ChildVault
    /// @notice Namespaced storage for ChildVault mutable state: action replay protection and recovery
    /// data for the four ChildVault-specific operations that can fail and need to be retried. Only
    /// one recovery struct (as selected by BaseVaultStorage.s_recoveryMode) is ever populated at a time.
    /// @param s_lastHandledEpochNonce Highest epoch nonce accepted by this child vault.
    /// @param s_lastHandledRebalanceNonce Highest rebalance nonce accepted by this child vault.
    /// @param s_rebalanceWithdrawRecovery Recovery data for a failed rebalance withdraw from the
    /// active protocol adapter - the rebalance nonce and the target strategy to continue the
    /// rebalance into once the withdraw is retried and succeeds.
    /// @param s_epochDepositRecovery Recovery data for a failed deposit into the active strategy adapter,
    /// after Parent CCIP-sends epoch net-deposit funds to this chain - the epoch nonce and asset amount
    /// to retry depositing.
    /// @param s_epochWithdrawRecovery Recovery data for a failed withdrawal from the active strategy
    /// adapter when executeEpochWithdraw is called for a net-withdraw epoch - the epoch nonce and asset
    /// amount to retry withdrawing. A successful retry proceeds to CCIP-send the withdrawn amount back
    /// to Parent; a failure of that send is tracked separately by s_ccipSendRecovery.
    /// @param s_ccipSendRecovery Recovery data for a failed outbound CCIP send (epoch net-withdraw
    /// or rebalance) - the CCIP tx type to replay, amount, destination chain
    /// selector, epoch/rebalance nonce, and (for rebalance sends) the target protocol ID.
    struct ChildVaultStorage {
        uint256 s_lastHandledEpochNonce;
        uint256 s_lastHandledRebalanceNonce;
        Types.RebalanceWithdrawRecovery s_rebalanceWithdrawRecovery;
        Types.EpochRecovery s_epochDepositRecovery;
        Types.EpochRecovery s_epochWithdrawRecovery;
        Types.CcipSendRecovery s_ccipSendRecovery;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.ChildVault")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant CHILD_VAULT_STORAGE_LOCATION =
        0x78e4dbdeeaf798c2dd37013d97b7b9a2111b1f613652054109dec720ccf6f400;

    /// @notice Returns the ChildVault namespaced storage pointer
    /// @return $ The ChildVault namespaced storage pointer
    function _childVaultStorage() internal pure returns (ChildVaultStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := CHILD_VAULT_STORAGE_LOCATION
        }
    }
}
