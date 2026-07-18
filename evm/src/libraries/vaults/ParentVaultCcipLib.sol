// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IBaseVault} from "../../interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {Types} from "../Types.sol";

/// @title Yieldcoin v2 ParentVault CCIP receive logic library
/// @author @contractlevel
/// @notice Handles ParentVault-specific CCIP message decoding, validation, and epoch settlement.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultCcipLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    /// @notice Emitted when an epoch is claimable
    /// @param epochNonce The nonce of the claimable epoch
    event EpochClaimable(uint256 indexed epochNonce);
    /// @notice Emitted when a CCIP withdraw message delivers less asset than expected
    /// @param epochNonce The nonce of the epoch with the short withdrawal
    /// @param expectedAmount The amount of asset expected from the remote strategy
    /// @param actualAmount The amount of asset delivered by the CCIP message
    event EpochWithdrawAmountShort(
        uint256 indexed epochNonce, uint256 indexed expectedAmount, uint256 indexed actualAmount
    );

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Handles ParentVault-specific CCIP message data after BaseVault validates sender and delivered token.
    /// @param $ ParentVault namespaced storage
    /// @param ccipTxType The decoded CCIP transaction type
    /// @param data The decoded CCIP payload data
    /// @param receivedAmount The amount of asset delivered by CCIP
    /// @return rebalanceNonce Nonzero rebalance nonce when ParentVault must handle a rebalance callback
    /// @return protocolId Pending strategy protocol ID for the rebalance callback
    function receiveCcip(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.CcipTx ccipTxType,
        bytes memory data,
        uint256 receivedAmount
    ) public returns (uint256 rebalanceNonce, bytes32 protocolId) {
        (rebalanceNonce, protocolId) = _receiveCcip($, ccipTxType, data, receivedAmount);
    }

    /// @notice Handles ParentVault-specific CCIP message data after BaseVault validates sender and delivered token.
    /// @param $ ParentVault namespaced storage
    /// @param ccipTxType The decoded CCIP transaction type
    /// @param data The decoded CCIP payload data
    /// @param receivedAmount The amount of asset delivered by CCIP
    /// @return rebalanceNonce Nonzero rebalance nonce when ParentVault must handle a rebalance callback
    /// @return protocolId Pending strategy protocol ID for the rebalance callback
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

    /// @notice Settles the withdraw side of an epoch after CCIP delivers the remote strategy's withdraw output.
    /// @param $ ParentVault namespaced storage
    /// @param data The decoded CCIP payload data, ABI-encoded as the settled epoch's nonce
    /// @param receivedAmount The amount of asset delivered by CCIP for the remote withdraw
    /// @dev Precondition: the decoded epoch nonce must equal `s_epochNonce - 1` (the most recently closed epoch)
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
        /// @dev Intentional overwrite. The amount could be higher than expected.
        s_epoch.totalWithdrawClaimAmount = totalWithdrawClaimAmount;
        s_epoch.remainingWithdrawClaimAmount = totalWithdrawClaimAmount;
        if (receivedAmount < expectedWithdraw) {
            /// @dev Shouldn't happen because we revert at the adapter level if shortfall withdraw amount
            emit EpochWithdrawAmountShort(epochNonce, expectedWithdraw, receivedAmount);
        }

        _finalizeEpoch(s_epoch, epochNonce);
    }

    /// @notice Validates a rebalance callback CCIP payload against the vault's stored pending rebalance.
    /// @param $ ParentVault namespaced storage
    /// @param data The decoded CCIP payload data, ABI-encoded as (rebalanceNonce, protocolId)
    /// @return rebalanceNonce The decoded rebalance nonce, validated against `s_rebalance.nonce`
    /// @return protocolId The decoded pending strategy protocol ID, validated against `s_rebalance.pendingStrategy.protocolId`
    /// @dev Precondition: a rebalance must be in progress (`s_rebalance.state == REBALANCING`)
    /// @dev Precondition: the decoded rebalanceNonce must match `s_rebalance.nonce`
    /// @dev Precondition: the decoded protocolId must match `s_rebalance.pendingStrategy.protocolId`
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

    /// @notice Marks a settled epoch as claimable.
    /// @param s_epoch The epoch's storage struct
    /// @param epochNonce The nonce of the epoch being finalized
    /// @dev Precondition: the epoch's status must be EXECUTING
    function _finalizeEpoch(Types.Epoch storage s_epoch, uint256 epochNonce) internal {
        if (s_epoch.status != Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochNotExecuting(epochNonce);
        }

        s_epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }
}
