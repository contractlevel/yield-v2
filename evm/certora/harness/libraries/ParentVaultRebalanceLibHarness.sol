// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultRebalanceLib} from "../../../src/libraries/ParentVaultRebalanceLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ParentVaultRebalanceLibHarness is ParentVaultStore, HelperHarness {
    address internal immutable i_share;

    constructor(address share) {
        i_share = share;
    }

    function initiateRebalance(
        bytes32 protocolId,
        uint64 chainSelector,
        uint64 thisChainSelector,
        bool isSupportedChain
    ) external returns (uint256 rebalanceNonce, uint8 action) {
        Types.Strategy memory newStrategy = Types.Strategy({protocolId: protocolId, chainSelector: chainSelector});
        ParentVaultRebalanceLib.InitiateRebalanceResult memory result =
            ParentVaultRebalanceLib._initiateRebalance(
                _parentVaultStorage(), newStrategy, thisChainSelector, isSupportedChain
            );
        rebalanceNonce = result.rebalanceNonce;
        action = uint8(result.action);
    }

    function finalizeRebalance() external {
        ParentVaultRebalanceLib._finalizeRebalance(_parentVaultStorage(), i_share);
    }

    function getRebalanceNonce() external view returns (uint256 nonce) {
        nonce = _parentVaultStorage().s_rebalance.nonce;
    }

    function getRebalanceState() external view returns (Types.RebalanceState state) {
        state = _parentVaultStorage().s_rebalance.state;
    }

    function getActiveStrategyProtocolId() external view returns (bytes32 protocolId) {
        protocolId = _parentVaultStorage().s_rebalance.activeStrategy.protocolId;
    }

    function getActiveStrategyChainSelector() external view returns (uint64 chainSelector) {
        chainSelector = _parentVaultStorage().s_rebalance.activeStrategy.chainSelector;
    }

    function getPendingStrategyProtocolId() external view returns (bytes32 protocolId) {
        protocolId = _parentVaultStorage().s_rebalance.pendingStrategy.protocolId;
    }

    function getPendingStrategyChainSelector() external view returns (uint64 chainSelector) {
        chainSelector = _parentVaultStorage().s_rebalance.pendingStrategy.chainSelector;
    }

    function getLastRebalanceCompletedTimestamp() external view returns (uint256 timestamp) {
        timestamp = _parentVaultStorage().s_rebalance.lastRebalanceCompletedTimestamp;
    }

    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    function getPreviousEpochStatus() external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[_parentVaultStorage().s_epochNonce - 1].status;
    }

    function getSupportedProtocol(bytes32 protocolId) external view returns (bool isSupported) {
        isSupported = _parentVaultStorage().s_supportedProtocol[protocolId];
    }

    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = _parentVaultStorage().s_totalShares;
    }

    function getTreasury() external view returns (address treasury) {
        treasury = _parentVaultStorage().s_treasury;
    }
}
