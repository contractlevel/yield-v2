// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {IShare} from "../../interfaces/token/IShare.sol";
import {ParentVaultMathLib} from "./ParentVaultMathLib.sol";

/// @title Yieldcoin v2 ParentVault fee logic library
/// @author @contractlevel
/// @notice Handles ParentVault fee accounting while ParentVault keeps lifecycle orchestration
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context
library ParentVaultFeesLib {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Basis points denominator (100% = 10_000 bps)
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    /// @dev Annual management fee rate (1%)
    uint256 internal constant MANAGEMENT_FEE_BPS = 100;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL
    /// @notice Emitted when management fees are collected
    /// @param rebalanceNonce The nonce of the rebalance that collected the fee
    /// @param feeShares The number of shares minted to the treasury
    event ManagementFeeCollected(uint256 indexed rebalanceNonce, uint256 indexed feeShares);

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates and collects management fees for time elapsed since the preceding rebalance completed
    /// @param $ ParentVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance collecting the fee
    /// @param lastRebalanceCompletedTimestamp The timestamp when the rebalance last completed
    /// @param share The Yieldcoin share token
    /// @dev Caps elapsed time at 365 days
    /// @dev Reverts if lastRebalanceCompletedTimestamp is in the future
    function _collectManagementFee(
        ParentVaultStore.ParentVaultStorage storage $,
        uint256 rebalanceNonce,
        uint256 lastRebalanceCompletedTimestamp,
        address share
    ) internal {
        uint256 elapsed = block.timestamp - lastRebalanceCompletedTimestamp;
        if (elapsed > 365 days) elapsed = 365 days;

        uint256 totalShares = $.s_totalShares;
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        uint256 feeShares = ParentVaultMathLib._mulDivUp(totalShares, MANAGEMENT_FEE_BPS * elapsed, denominator);
        if (feeShares != 0) {
            $.s_totalShares = totalShares + feeShares;
            IShare(share).mint($.s_treasury, feeShares);
            emit ManagementFeeCollected(rebalanceNonce, feeShares);
        }
    }
}
