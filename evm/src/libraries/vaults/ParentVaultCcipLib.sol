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
    event EpochClaimable(uint256 indexed epochNonce);
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

    function _finalizeEpoch(Types.Epoch storage s_epoch, uint256 epochNonce) internal {
        if (s_epoch.status != Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochNotExecuting(epochNonce);
        }

        s_epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }
}
