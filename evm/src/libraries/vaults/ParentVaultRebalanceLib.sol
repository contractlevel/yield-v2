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
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Minimum time that must elapse since the last rebalance completed before another can be initiated
    uint256 internal constant MIN_REBALANCE_PERIOD = 1 hours;

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice The action ParentVault must take after initiateRebalance updates state
    enum ExternalAction {
        NONE, // 0: the previously active strategy is not on this chain, nothing to withdraw here
        WITHDRAW_LOCAL_TO_LOCAL, // 1: withdraw from the local active strategy and deposit into the local new strategy
        WITHDRAW_LOCAL_TO_REMOTE // 2: withdraw from the local active strategy and CCIP-send to the new strategy's chain
    }

    /// @notice The external action ParentVault should execute after initiateRebalance state is updated
    /// @param rebalanceNonce The nonce of the rebalance that was just initiated
    /// @param action The action ParentVault must take
    struct InitiateRebalanceResult {
        uint256 rebalanceNonce;
        ExternalAction action;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    /// @notice Emitted when a rebalance is initiated
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param protocolId The target strategy protocol ID
    /// @param chainSelector The target strategy chain selector
    event RebalanceInitiated(uint256 indexed rebalanceNonce, bytes32 indexed protocolId, uint64 indexed chainSelector);
    /// @notice Emitted when a rebalance is completed
    /// @param rebalanceNonce The nonce of the completed rebalance
    /// @param newProtocolId The protocol ID for the new strategy
    /// @param newChainSelector The chain selector for the new strategy
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
    /// @param isSupportedChain Whether the target strategy chain is local or registered in BaseVault storage
    /// @return result The external action ParentVault should execute after state is updated
    function initiateRebalance(
        ParentVaultStore.ParentVaultStorage storage $,
        Types.Strategy memory newStrategy,
        uint64 thisChainSelector,
        bool isSupportedChain
    ) public returns (InitiateRebalanceResult memory result) {
        result = _initiateRebalance($, newStrategy, thisChainSelector, isSupportedChain);
    }

    /// @notice Starts a rebalance and returns the external strategy/CCIP action ParentVault must execute.
    /// @param $ ParentVault namespaced storage
    /// @param newStrategy The new strategy to rebalance to
    /// @param thisChainSelector The chain selector for the ParentVault chain
    /// @param isSupportedChain Whether the target strategy chain is local or registered in BaseVault storage
    /// @return result The external action ParentVault should execute after state is updated
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
        if (block.timestamp < s_rebalance.lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD) {
            revert IParentVault.ParentVault__RebalanceTooSoon(s_rebalance.nonce);
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
        if ($.s_epochs[currentEpochNonce - 1].status == Types.EpochStatus.EXECUTING) {
            revert IParentVault.ParentVault__EpochExecuting(currentEpochNonce - 1);
        }

        uint256 rebalanceNonce = s_rebalance.nonce;
        emit RebalanceInitiated(rebalanceNonce, newStrategy.protocolId, newStrategy.chainSelector);
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

    /// @notice Finalizes an in-progress rebalance and collects management fees.
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param rebalanceNonce The current `s_rebalance.nonce`
    /// @param newStrategy The current `s_rebalance.pendingStrategy`
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
