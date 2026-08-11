// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IBaseVault} from "../../interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {Types} from "../Types.sol";
import {ParentVaultEpochLib} from "./ParentVaultEpochLib.sol";

/// @title Yieldcoin v2 ParentVault CCIP receive logic library
/// @author @contractlevel
/// @notice Handles ParentVault-specific CCIP message decoding, validation, and epoch settlement
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context
library ParentVaultCcipLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL
    /// @notice Emitted when a CCIP withdrawal message delivers less underlying asset than expected
    /// @param epochNonce The nonce of the epoch with the short withdrawal
    /// @param expectedAmount The amount of underlying asset expected from the remote strategy
    /// @param actualAmount The amount of underlying asset delivered by the CCIP message
    event EpochWithdrawAmountShort(
        uint256 indexed epochNonce, uint256 indexed expectedAmount, uint256 indexed actualAmount
    );

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Handles ParentVault-specific CCIP message data after BaseVault validates the sender and delivered token
    /// @param $ ParentVault namespaced storage
    /// @param ccipTxType The decoded CCIP transaction type
    /// @param data The decoded CCIP payload data
    /// @param receivedAmount The amount of underlying asset delivered by CCIP
    /// @return rebalanceNonce Nonzero rebalance nonce when ParentVault must handle a rebalance callback
    /// @return protocolId Pending strategy protocol ID for the rebalance callback
    /// @dev Reverts if ccipTxType is not EPOCH_NET_WITHDRAW or REBALANCE
    /// @dev Reverts if data is malformed or fails the selected transaction type's validation
    function receiveCcip(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.CcipTx ccipTxType,
        bytes memory data,
        uint256 receivedAmount
    ) public returns (uint256 rebalanceNonce, bytes32 protocolId) {
        (rebalanceNonce, protocolId) = _receiveCcip($, ccipTxType, data, receivedAmount);
    }

    /// @notice Handles ParentVault-specific CCIP message data after BaseVault validates the sender and delivered token
    /// @param $ ParentVault namespaced storage
    /// @param ccipTxType The decoded CCIP transaction type
    /// @param data The decoded CCIP payload data
    /// @param receivedAmount The amount of underlying asset delivered by CCIP
    /// @return rebalanceNonce Nonzero rebalance nonce when ParentVault must handle a rebalance callback
    /// @return protocolId Pending strategy protocol ID for the rebalance callback
    /// @dev Reverts if ccipTxType is not EPOCH_NET_WITHDRAW or REBALANCE
    /// @dev Reverts if data is malformed or fails the selected transaction type's validation
    function _receiveCcip(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.CcipTx ccipTxType,
        bytes memory data,
        uint256 receivedAmount
    ) internal returns (uint256 rebalanceNonce, bytes32 protocolId) {
        if (ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW) {
            _handleEpochNetWithdraw($, data, receivedAmount);
        } else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (rebalanceNonce, protocolId) = _validateRebalance($, data);
        } else {
            revert IBaseVault.BaseVault__InvalidTxType(ccipTxType);
        }
    }

    /// @notice Settles the withdrawal side of an epoch after CCIP delivers the remote strategy's withdrawal output
    /// @param $ ParentVault namespaced storage
    /// @param data The decoded CCIP payload data, ABI-encoded as the settled epoch's nonce
    /// @param receivedAmount The amount of underlying asset delivered for the remote withdrawal
    /// @dev Reverts if data is not an ABI-encoded uint256 epoch nonce
    /// @dev Reverts if the decoded epoch nonce does not identify the most recently closed epoch
    /// @dev Assumes the identified epoch is a remote net withdrawal; this helper validates the nonce and EXECUTING
    ///      status but does not independently validate the net-flow direction
    function _handleEpochNetWithdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        bytes memory data,
        uint256 receivedAmount
    ) internal {
        uint256 epochNonce = abi.decode(data, (uint256));
        if (epochNonce != $.s_epochNonce - 1) revert IParentVault.ParentVault__InvalidEpochNonce(epochNonce);
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];

        uint256 totalDepositAmount = s_epoch.totalDepositAmount;
        uint256 expectedWithdraw = s_epoch.totalWithdrawClaimAmount - totalDepositAmount;
        uint256 totalWithdrawClaimAmount = totalDepositAmount + receivedAmount;
        // Intentional overwrite. The amount could be higher than expected.
        s_epoch.totalWithdrawClaimAmount = totalWithdrawClaimAmount;
        s_epoch.remainingWithdrawClaimAmount = totalWithdrawClaimAmount;
        if (receivedAmount < expectedWithdraw) {
            // Should not happen because the adapter reverts if the withdraw amount is short
            emit EpochWithdrawAmountShort(epochNonce, expectedWithdraw, receivedAmount);
        }

        ParentVaultEpochLib._finalizeEpoch(s_epoch, epochNonce);
    }

    /// @notice Validates a rebalance callback payload against the vault's stored pending rebalance
    /// @param $ ParentVault namespaced storage
    /// @param data The decoded CCIP payload data, ABI-encoded as (rebalanceNonce, protocolId)
    /// @return rebalanceNonce The decoded rebalance nonce, validated against `s_rebalance.nonce`
    /// @return protocolId The decoded pending strategy protocol ID, validated against `s_rebalance.pendingStrategy.protocolId`
    /// @dev Reverts if no rebalance is in progress
    /// @dev Reverts if data is not an ABI-encoded (uint256, bytes32) tuple
    /// @dev Reverts if the decoded rebalanceNonce does not match s_rebalance.nonce
    /// @dev Reverts if the decoded protocolId does not match s_rebalance.pendingStrategy.protocolId
    function _validateRebalance(ParentVaultStore.ParentVaultStorage storage $, bytes memory data)
        internal
        view
        returns (uint256 rebalanceNonce, bytes32 protocolId)
    {
        Types.Rebalance storage s_rebalance = $.s_rebalance;
        if (s_rebalance.state != Types.RebalanceState.REBALANCING) {
            revert IParentVault.ParentVault__NoRebalanceInProgress();
        }

        (rebalanceNonce, protocolId) = abi.decode(data, (uint256, bytes32));
        if (s_rebalance.nonce != rebalanceNonce) {
            revert IParentVault.ParentVault__InvalidRebalanceNonce(rebalanceNonce);
        }
        if (s_rebalance.pendingStrategy.protocolId != protocolId) {
            revert IParentVault.ParentVault__InvalidPendingProtocolId(protocolId);
        }
    }
}
