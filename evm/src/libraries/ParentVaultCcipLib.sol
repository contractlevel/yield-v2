// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../vaults/ParentVaultStore.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IParentVault} from "../interfaces/IParentVault.sol";
import {Types} from "./Types.sol";

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
    event EpochWithdrawAmountShort(uint256 indexed epochNonce, uint256 indexed expectedAmount, uint256 indexed actualAmount);

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
        Types.Epoch storage epoch = $.s_epochs[epochNonce];

        uint256 expectedWithdraw = epoch.totalWithdrawClaimAmount - epoch.totalDepositAmount;
        epoch.totalWithdrawClaimAmount = epoch.totalDepositAmount + receivedAmount;
        epoch.remainingWithdrawClaimAmount = epoch.totalWithdrawClaimAmount;
        if (receivedAmount < expectedWithdraw) {
            emit EpochWithdrawAmountShort(epochNonce, expectedWithdraw, receivedAmount);
        }

        _finalizeEpoch($, epochNonce);
    }

    function _validateRebalance(ParentVaultStore.ParentVaultStorage storage $, bytes memory data)
        internal
        view
        returns (uint256 rebalanceNonce, bytes32 protocolId)
    {
        Types.Rebalance memory rebalance = $.s_rebalance;
        if (rebalance.state != Types.RebalanceState.REBALANCING) {
            revert IParentVault.ParentVault__NoRebalanceInProgress();
        }

        (rebalanceNonce, protocolId) = abi.decode(data, (uint256, bytes32));
        if (rebalance.nonce != rebalanceNonce) revert IParentVault.ParentVault__InvalidRebalanceNonce(rebalanceNonce);
        if (rebalance.pendingStrategy.protocolId != protocolId) {
            revert IParentVault.ParentVault__InvalidPendingProtocolId(protocolId);
        }
    }

    function _finalizeEpoch(ParentVaultStore.ParentVaultStorage storage $, uint256 epochNonce) internal {
        Types.Epoch storage epoch = $.s_epochs[epochNonce];
        if (epoch.status != Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochNotExecuting(epochNonce);
        }

        epoch.status = Types.EpochStatus.CLAIMABLE;
        emit EpochClaimable(epochNonce);
    }
}
