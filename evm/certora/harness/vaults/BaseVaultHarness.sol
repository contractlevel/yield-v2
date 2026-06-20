// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {HelperHarness} from "../HelperHarness.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {Types} from "../../../src/libraries/Types.sol";

/// @notice Shared Certora harness helpers for BaseVault-derived vaults
abstract contract BaseVaultHarness is BaseVault, HelperHarness {
    /*//////////////////////////////////////////////////////////////
                         VALIDATION WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function revertIfZeroAddress(address value) external pure {
        _revertIfZeroAddress(value);
    }

    function revertIfZeroAmount(uint256 value) external pure {
        _revertIfZeroAmount(value);
    }

    function revertIfZeroChainSelector(uint64 value) external pure {
        _revertIfZeroChainSelector(value);
    }

    /*//////////////////////////////////////////////////////////////
                      BASEVAULT INTERNAL WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function setActiveAdapter(bytes32 protocolId) external returns (address) {
        return _setActiveAdapter(protocolId);
    }

    function clearActiveAdapter() external {
        _clearActiveAdapter();
    }

    function storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) external {
        _storeRebalanceDepositRecovery(rebalanceNonce, amount);
    }

    function clearRebalanceDepositRecovery() external {
        _clearRebalanceDepositRecovery();
    }

    function executeCcipSend(
        uint256 bridgeAmount,
        uint64 destSelector,
        Types.CcipTx ccipTxType,
        bytes calldata txData
    ) external {
        _executeCcipSend(bridgeAmount, destSelector, ccipTxType, txData);
    }

    function executeDeposit(uint256 amount, bool revertOnFailure) external returns (bool success) {
        success = _executeDeposit(amount, revertOnFailure);
    }

    function executeWithdraw(uint256 amount, bool revertOnFailure) external returns (bool success, uint256 amountOut) {
        (success, amountOut) = _executeWithdraw(amount, revertOnFailure);
    }

    function exposedOnlyAllowedSender(address sender, uint64 srcChainSelector) external view {
        _onlyAllowedSender(sender, srcChainSelector);
    }
 

    /*//////////////////////////////////////////////////////////////
                      RECOVERY FIELD GETTERS
    //////////////////////////////////////////////////////////////*/

    function getRecoveryRebalanceNonce() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.rebalanceNonce;
    }

    function getRecoveryAmount() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.amount;
    }

    function getRecoveryCreatedAt() external view returns (uint256) {
        return _baseVaultStorage().s_rebalanceDepositRecovery.createdAt;
    }
}
