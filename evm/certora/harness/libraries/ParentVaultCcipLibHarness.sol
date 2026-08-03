// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultCcipLib} from "../../../src/libraries/vaults/ParentVaultCcipLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

contract ParentVaultCcipLibHarness is ParentVaultStore, HelperHarness {
    function receiveCcip(Types.CcipTx ccipTxType, bytes calldata data, uint256 receivedAmount)
        external
        returns (uint256 rebalanceNonce, bytes32 protocolId)
    {
        (rebalanceNonce, protocolId) =
            ParentVaultCcipLib._receiveCcip(_parentVaultStorage(), ccipTxType, data, receivedAmount);
    }

    function getEpochNonce() external view returns (uint256 epochNonce) {
        epochNonce = _parentVaultStorage().s_epochNonce;
    }

    function getEpochTotalDepositAmount(uint256 epochNonce) external view returns (uint256 totalDepositAmount) {
        totalDepositAmount = _parentVaultStorage().s_epochs[epochNonce].totalDepositAmount;
    }

    function getEpochTotalWithdrawClaimAmount(uint256 epochNonce)
        external
        view
        returns (uint256 totalWithdrawClaimAmount)
    {
        totalWithdrawClaimAmount = _parentVaultStorage().s_epochs[epochNonce].totalWithdrawClaimAmount;
    }

    function getEpochRemainingWithdrawClaimAmount(uint256 epochNonce)
        external
        view
        returns (uint256 remainingWithdrawClaimAmount)
    {
        remainingWithdrawClaimAmount = _parentVaultStorage().s_epochs[epochNonce].remainingWithdrawClaimAmount;
    }

    function getEpochStatus(uint256 epochNonce) external view returns (Types.EpochStatus status) {
        status = _parentVaultStorage().s_epochs[epochNonce].status;
    }

    function getRebalanceNonce() external view returns (uint256 nonce) {
        nonce = _parentVaultStorage().s_rebalance.nonce;
    }

    function getRebalanceState() external view returns (Types.RebalanceState state) {
        state = _parentVaultStorage().s_rebalance.state;
    }

    function getPendingStrategyProtocolId() external view returns (bytes32 protocolId) {
        protocolId = _parentVaultStorage().s_rebalance.pendingStrategy.protocolId;
    }
}
