// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../vaults/ParentVaultStore.sol";
import {IParentVault} from "../interfaces/IParentVault.sol";
import {ParentVaultFeesLib} from "./ParentVaultFeesLib.sol";
import {Types} from "./Types.sol";

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
        if ($.s_rebalance.state != Types.RebalanceState.NONE) {
            revert IParentVault.ParentVault__RebalanceInProgress();
        }

        if (
            $.s_rebalance.activeStrategy.protocolId == newStrategy.protocolId
                && $.s_rebalance.activeStrategy.chainSelector == newStrategy.chainSelector
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

        uint256 rebalanceNonce = $.s_rebalance.nonce;
        $.s_rebalance.state = Types.RebalanceState.REBALANCING;
        $.s_rebalance.pendingStrategy = newStrategy;
        $.s_rebalance.lastRebalanceInitiatedTimestamp = block.timestamp;
        emit RebalanceInitiated(rebalanceNonce, newStrategy.chainSelector, newStrategy.protocolId);

        result.rebalanceNonce = rebalanceNonce;
        if ($.s_rebalance.activeStrategy.chainSelector == thisChainSelector) {
            if (newStrategy.chainSelector == thisChainSelector) {
                result.action = ExternalAction.WITHDRAW_LOCAL_TO_LOCAL;
            } else {
                result.action = ExternalAction.WITHDRAW_LOCAL_TO_REMOTE;
            }
        }
    }

    /// @notice Finalizes an in-progress rebalance and collects management fees.
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    function finalizeRebalance(ParentVaultStore.ParentVaultStorage storage $, address share) public {
        if ($.s_rebalance.state != Types.RebalanceState.REBALANCING) {
            revert IParentVault.ParentVault__NoRebalanceInProgress();
        }

        uint256 rebalanceNonce = $.s_rebalance.nonce;
        uint256 lastRebalanceCompletedTimestamp = $.s_rebalance.lastRebalanceCompletedTimestamp;

        Types.Strategy memory newStrategy = $.s_rebalance.pendingStrategy;
        $.s_rebalance.activeStrategy = newStrategy;
        $.s_rebalance.state = Types.RebalanceState.NONE;
        $.s_rebalance.lastRebalanceCompletedTimestamp = block.timestamp;
        delete $.s_rebalance.pendingStrategy;

        emit RebalanceCompleted(rebalanceNonce, newStrategy.protocolId, newStrategy.chainSelector);
        ++$.s_rebalance.nonce;
        ParentVaultFeesLib.collectManagementFee($, rebalanceNonce, lastRebalanceCompletedTimestamp, share);
    }
}
