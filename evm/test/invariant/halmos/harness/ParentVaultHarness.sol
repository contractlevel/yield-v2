// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {ParentVaultUserEpochLib} from "../../../../src/libraries/ParentVaultUserEpochLib.sol";

/// @dev Halmos test harness for ParentVault.
///      Exposes direct SSTORE setters for the epoch counters and per-user records
///      that claimShares / claimAsset read. Using inheritance to access internal
///      mappings avoids stdstore, which relies on vm.record() — a cheatcode
///      unsupported by Halmos.
contract ParentVaultHarness is ParentVault {
    constructor(
        BaseVault.ConstructorParams memory params,
        address treasury,
        address share,
        address policyEngineManager,
        address policyEngine
    ) ParentVault(params, share) {}

    function setEpochStatus(uint256 nonce, Types.EpochStatus status) external {
        _parentVaultStorage().s_epochs[nonce].status = status;
    }

    function setRemainingDepositClaimAmount(uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_epochs[nonce].remainingDepositClaimAmount = amount;
    }

    function setRemainingShareMintAmount(uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_epochs[nonce].remainingShareMintAmount = amount;
    }

    function setRemainingShareBurnAmount(uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_epochs[nonce].remainingShareBurnAmount = amount;
    }

    function setRemainingWithdrawClaimAmount(uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_epochs[nonce].remainingWithdrawClaimAmount = amount;
    }

    function setDeposit(address user, uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_deposits[user][nonce] = amount;
    }

    function setWithdraw(address user, uint256 nonce, uint256 amount) external {
        _parentVaultStorage().s_withdraws[user][nonce] = amount;
    }

    function proportionalAmount(uint256 userAmount, uint256 remainingNumerator, uint256 remainingDenominator)
        external
        pure
        returns (uint256)
    {
        return ParentVaultUserEpochLib.proportionalAmount(userAmount, remainingNumerator, remainingDenominator);
    }
}
