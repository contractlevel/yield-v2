// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {ParentVaultFeesLib} from "./ParentVaultFeesLib.sol";
import {Types} from "../Types.sol";

/// @title Yieldcoin v2 ParentVault rebalance logic library
/// @author @contractlevel
/// @notice Handles ParentVault rebalance validation and state transitions.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultRebalanceLib {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    enum ExternalAction {
        NONE,
        WITHDRAW_LOCAL_TO_LOCAL,
        WITHDRAW_LOCAL_TO_REMOTE
    }

    struct InitiateRebalanceResult {
        uint256 rebalanceNonce;
        ExternalAction action;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    event RebalanceInitiated(uint256 indexed rebalanceNonce, uint64 indexed chainSelector, bytes32 indexed protocolId);
    event RebalanceCompleted(
        uint256 indexed rebalanceNonce, bytes32 indexed newProtocolId, uint64 indexed newChainSelector
    );

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice Starts a rebalance and returns the external strategy/CCIP action ParentVault must execute.
    /// @param $ ParentVault namespaced storage
    /// @param newStrategy The new strategy to rebalance to
    /// @param thisChainSelector The chain selector for the ParentVault chain
    /// @param isSupportedChain Whether the target strategy chain is registered in BaseVault storage
    /// @return result The external action ParentVault should execute after state is updated
    function initiateRebalance(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.Strategy memory newStrategy,
        uint64 thisChainSelector,
        bool isSupportedChain
    ) public returns (InitiateRebalanceResult memory result) {
        result = _initiateRebalance($, newStrategy, thisChainSelector, isSupportedChain);
    }

    function _initiateRebalance(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.Strategy memory newStrategy,
        uint64 thisChainSelector,
        bool isSupportedChain
    ) internal returns (InitiateRebalanceResult memory result) {
        Types.Rebalance storage s_rebalance = $.s_rebalance;
        if (s_rebalance.state != Types.RebalanceState.NONE) {
            revert IParentVault.ParentVault__RebalanceInProgress();
        }

        Types.Strategy memory activeStrategy = s_rebalance.activeStrategy;
        if (
            activeStrategy.protocolId == newStrategy.protocolId
                && activeStrategy.chainSelector == newStrategy.chainSelector
        ) {
            revert IParentVault.ParentVault__SameStrategy();
        }

        if (!isSupportedChain) revert IParentVault.ParentVault__InvalidChainSelector(newStrategy.chainSelector);
        if (!$.s_supportedProtocol[newStrategy.protocolId]) {
            revert IParentVault.ParentVault__InvalidProtocolId(newStrategy.protocolId);
        }

        uint256 currentEpochNonce = $.s_epochNonce;
        if (currentEpochNonce == 1) revert IParentVault.ParentVault__NoCompletedEpoch();
        if (currentEpochNonce > 1 && $.s_epochs[currentEpochNonce - 1].status == Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochExecuting(currentEpochNonce - 1);
        }

        uint256 rebalanceNonce = s_rebalance.nonce;
        emit RebalanceInitiated(rebalanceNonce, newStrategy.chainSelector, newStrategy.protocolId);
        result.rebalanceNonce = rebalanceNonce;

        bool isLocalActive = activeStrategy.chainSelector == thisChainSelector;
        if (isLocalActive && newStrategy.chainSelector == thisChainSelector) {
            // Local-to-local: resolves synchronously within this same transaction, so state/
            // pendingStrategy are never persisted - _finalizeLocalToLocalRebalance is called
            // moments later in the same call, which would just overwrite them straight back.
            result.action = ExternalAction.WITHDRAW_LOCAL_TO_LOCAL;
            return result;
        }

        s_rebalance.state = Types.RebalanceState.REBALANCING;
        s_rebalance.pendingStrategy = newStrategy;
        if (isLocalActive) {
            result.action = ExternalAction.WITHDRAW_LOCAL_TO_REMOTE;
        }
    }

    /// @notice Finalizes an in-progress rebalance and collects management fees.
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param rebalanceNonce The current `s_rebalance.nonce`
    /// @param newStrategy The current `s_rebalance.pendingStrategy`
    /// @param isLocalToLocalRebalance See `_finalizeRebalance` below
    function finalizeRebalance(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        uint256 rebalanceNonce,
        Types.Strategy memory newStrategy,
        bool isLocalToLocalRebalance
    ) public {
        _finalizeRebalance($, share, rebalanceNonce, newStrategy, isLocalToLocalRebalance);
    }

    /// @param isLocalToLocalRebalance True when finalizing a rebalance that stayed on this chain and
    ///        resolved synchronously within the same initiateRebalance() call - state/pendingStrategy
    ///        were never written to storage (see _initiateRebalance), so there is nothing to validate
    ///        or clear here.
    function _finalizeRebalance(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        uint256 rebalanceNonce,
        Types.Strategy memory newStrategy,
        bool isLocalToLocalRebalance
    ) internal {
        Types.Rebalance storage s_rebalance = $.s_rebalance;
        if (!isLocalToLocalRebalance && s_rebalance.state != Types.RebalanceState.REBALANCING) {
            revert IParentVault.ParentVault__NoRebalanceInProgress();
        }

        uint256 lastRebalanceCompletedTimestamp = s_rebalance.lastRebalanceCompletedTimestamp;

        s_rebalance.activeStrategy = newStrategy;
        if (!isLocalToLocalRebalance) {
            s_rebalance.state = Types.RebalanceState.NONE;
            delete s_rebalance.pendingStrategy;
        }
        s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;

        emit RebalanceCompleted(rebalanceNonce, newStrategy.protocolId, newStrategy.chainSelector);
        s_rebalance.nonce = rebalanceNonce + 1;
        ParentVaultFeesLib._collectManagementFee($, rebalanceNonce, lastRebalanceCompletedTimestamp, share);
    }
}
