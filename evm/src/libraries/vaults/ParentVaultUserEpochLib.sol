// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../../vaults/ParentVaultStore.sol";
import {IParentVault} from "../../interfaces/vaults/IParentVault.sol";
import {IShare} from "../../interfaces/token/IShare.sol";
import {ParentVaultMathLib} from "./ParentVaultMathLib.sol";
import {Types} from "../Types.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 ParentVault user epoch logic library
/// @author @contractlevel
/// @notice Handles user-level ParentVault epoch operations while ParentVault keeps policy and lifecycle orchestration.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultUserEpochLib {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    /// @notice Emitted when a deposit is made
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset deposited
    event DepositSubmitted(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw is made
    /// @param epochNonce The epoch nonce of the withdraw
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares burned
    event WithdrawSubmitted(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param depositor The address of the depositor
    /// @param shareMintAmount The amount of Yieldcoin shares minted
    event DepositClaimed(uint256 indexed epochNonce, address indexed depositor, uint256 indexed shareMintAmount);
    /// @notice Emitted when a withdraw is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param withdrawer The address of the withdrawer
    /// @param amount The amount of asset withdrawn
    event WithdrawClaimed(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when a deposit is cancelled
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset that was cancelled
    event DepositCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw is cancelled
    /// @param epochNonce The epoch nonce of the withdraw
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares that were intended to burn to redeem the underlying asset
    event WithdrawCancelled(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is force-cancelled by the cancel deposit operator
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of asset that was cancelled
    event DepositForceCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the vault
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The user depositing asset
    /// @param amount The amount of asset to deposit
    /// @param minDepositAmount The minimum deposit amount
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Precondition: amount must meet the minimum deposit amount requirement
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their amount
    function deposit(
        ParentVaultStore.ParentVaultStorage storage $,
        address asset,
        address user,
        uint256 amount,
        uint256 minDepositAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _deposit($, asset, user, amount, minDepositAmount);
    }

    /// @notice Deposits the underlying asset into the vault
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The user depositing asset
    /// @param amount The amount of asset to deposit
    /// @param minDepositAmount The minimum deposit amount
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Precondition: amount must meet the minimum deposit amount requirement
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their amount
    function _deposit(
        ParentVaultStore.ParentVaultStorage storage $,
        address asset,
        address user,
        uint256 amount,
        uint256 minDepositAmount
    ) internal returns (uint256 epochNonce) {
        if (amount < minDepositAmount) revert IParentVault.ParentVault__AmountTooSmall(amount);
        epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        /// @dev This condition should never be hit under normal operations as the epoch nonce is incremented on openNextEpoch
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        $.s_deposits[user][epochNonce] += amount;
        s_epoch.totalDepositAmount += amount;

        IERC20(asset).safeTransferFrom(user, address(this), amount);
        emit DepositSubmitted(epochNonce, user, amount);
    }

    /// @notice Submit USDC withdraw intent
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The user submitting the withdraw intent
    /// @param shareBurnAmount The amount of shares to burn for the withdraw
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Precondition: shareBurnAmount must not be zero
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their shareBurnAmount
    function withdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address user,
        uint256 shareBurnAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _withdraw($, share, user, shareBurnAmount);
    }

    /// @notice Submit USDC withdraw intent
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The user submitting the withdraw intent
    /// @param shareBurnAmount The amount of shares to burn for the withdraw
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Precondition: shareBurnAmount must not be zero
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: user must approve address(this) to transfer their shareBurnAmount
    function _withdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address user,
        uint256 shareBurnAmount
    ) internal returns (uint256 epochNonce) {
        if (shareBurnAmount == 0) revert IParentVault.ParentVault__NoZeroAmount();
        epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        /// @dev This condition should never be hit under normal operations as the epoch nonce is incremented on openNextEpoch
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        $.s_withdraws[user][epochNonce] += shareBurnAmount;
        s_epoch.totalShareBurnAmount += shareBurnAmount;

        IERC20(share).safeTransferFrom(user, address(this), shareBurnAmount);

        emit WithdrawSubmitted(epochNonce, user, shareBurnAmount);
    }

    /// @notice Claim Yieldcoin shares after a deposit
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The depositor claiming shares
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Finalizes an individual deposit
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function claimShares(ParentVaultStore.ParentVaultStorage storage $, address share, address user, uint256 epochNonce)
        public
        returns (uint256 shareMintAmount)
    {
        shareMintAmount = _claimShares($, share, user, epochNonce);
    }

    /// @notice Claim Yieldcoin shares after a deposit
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The depositor claiming shares
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Finalizes an individual deposit
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function _claimShares(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address user,
        uint256 epochNonce
    ) internal returns (uint256 shareMintAmount) {
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.CLAIMABLE) {
            revert IParentVault.ParentVault__EpochNotClaimable(epochNonce);
        }

        uint256 depositAmount = $.s_deposits[user][epochNonce];
        if (depositAmount == 0) revert IParentVault.ParentVault__NoDeposit(user, epochNonce);

        uint256 remainingDepositClaimAmount = s_epoch.remainingDepositClaimAmount;
        uint256 remainingShareMintAmount = s_epoch.remainingShareMintAmount;
        if (depositAmount != remainingDepositClaimAmount) {
            shareMintAmount =
                ParentVaultMathLib._mulDivDown(depositAmount, remainingShareMintAmount, remainingDepositClaimAmount);
        } else {
            shareMintAmount = remainingShareMintAmount;
        }

        s_epoch.remainingDepositClaimAmount = remainingDepositClaimAmount - depositAmount;
        s_epoch.remainingShareMintAmount -= shareMintAmount;

        delete $.s_deposits[user][epochNonce];
        IShare(share).mint(user, shareMintAmount);

        emit DepositClaimed(epochNonce, user, shareMintAmount);
    }

    /// @notice Claim underlying asset after a withdraw
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param asset The underlying asset token
    /// @param user The withdrawer claiming asset
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return withdrawAmount The amount of asset withdrawn
    /// @dev Finalizes an individual withdraw
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function claimAsset(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address asset,
        address user,
        uint256 epochNonce
    ) public returns (uint256 withdrawAmount) {
        withdrawAmount = _claimAsset($, share, asset, user, epochNonce);
    }

    /// @notice Claim underlying asset after a withdraw
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param asset The underlying asset token
    /// @param user The withdrawer claiming asset
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return withdrawAmount The amount of asset withdrawn
    /// @dev Finalizes an individual withdraw
    /// @dev Precondition: the epoch nonce must be claimable
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function _claimAsset(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address asset,
        address user,
        uint256 epochNonce
    ) internal returns (uint256 withdrawAmount) {
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.CLAIMABLE) {
            revert IParentVault.ParentVault__EpochNotClaimable(epochNonce);
        }

        uint256 shareBurnAmount = $.s_withdraws[user][epochNonce];
        if (shareBurnAmount == 0) revert IParentVault.ParentVault__NoWithdraw(user, epochNonce);

        uint256 remainingShareBurnAmount = s_epoch.remainingShareBurnAmount;
        uint256 remainingWithdrawClaimAmount = s_epoch.remainingWithdrawClaimAmount;
        if (shareBurnAmount != remainingShareBurnAmount) {
            withdrawAmount =
                ParentVaultMathLib._mulDivDown(shareBurnAmount, remainingWithdrawClaimAmount, remainingShareBurnAmount);
        } else {
            withdrawAmount = remainingWithdrawClaimAmount;
        }

        s_epoch.remainingShareBurnAmount = remainingShareBurnAmount - shareBurnAmount;
        s_epoch.remainingWithdrawClaimAmount = remainingWithdrawClaimAmount - withdrawAmount;

        delete $.s_withdraws[user][epochNonce];

        IShare(share).burn(address(this), shareBurnAmount);

        emit WithdrawClaimed(epochNonce, user, withdrawAmount);
        if (withdrawAmount != 0) IERC20(asset).safeTransfer(user, withdrawAmount);
    }

    /// @notice Cancels a deposit
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor cancelling their deposit
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function cancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) public {
        _cancelDeposit($, asset, user);
    }

    /// @notice Cancels a deposit
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor cancelling their deposit
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function _cancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) internal {
        (uint256 epochNonce, uint256 depositAmount) = _cancelDepositCore($, asset, user);
        emit DepositCancelled(epochNonce, user, depositAmount);
    }

    /// @notice Force-cancels a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function forceCancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) public {
        _forceCancelDeposit($, asset, user);
    }

    /// @notice Force-cancels a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev This deletes the entire deposit entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function _forceCancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) internal {
        (uint256 epochNonce, uint256 depositAmount) = _cancelDepositCore($, asset, user);
        emit DepositForceCancelled(epochNonce, user, depositAmount);
    }

    /// @notice Shared state-mutation core for cancelling a deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being cancelled
    /// @return epochNonce The epoch nonce the deposit was cancelled from
    /// @return depositAmount The amount of asset refunded to the user
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a deposit for the epoch nonce
    function _cancelDepositCore(ParentVaultStore.ParentVaultStorage storage $, address asset, address user)
        private
        returns (uint256 epochNonce, uint256 depositAmount)
    {
        epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        depositAmount = $.s_deposits[user][epochNonce];
        if (depositAmount == 0) revert IParentVault.ParentVault__NoDeposit(user, epochNonce);
        delete $.s_deposits[user][epochNonce];
        s_epoch.totalDepositAmount -= depositAmount;

        IERC20(asset).safeTransfer(user, depositAmount);
    }

    /// @notice Cancels a withdraw
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The withdrawer cancelling their withdraw intent
    /// @dev This deletes the entire withdraw entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function cancelWithdraw(ParentVaultStore.ParentVaultStorage storage $, address share, address user) public {
        _cancelWithdraw($, share, user);
    }

    /// @notice Cancels a withdraw
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The withdrawer cancelling their withdraw intent
    /// @dev This deletes the entire withdraw entry for the user and epoch nonce
    /// @dev Precondition: the current epoch must be open
    /// @dev Precondition: the user must have a withdraw intent for the epoch nonce
    function _cancelWithdraw(ParentVaultStore.ParentVaultStorage storage $, address share, address user) internal {
        uint256 epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        uint256 shareBurnAmount = $.s_withdraws[user][epochNonce];
        if (shareBurnAmount == 0) revert IParentVault.ParentVault__NoWithdraw(user, epochNonce);
        delete $.s_withdraws[user][epochNonce];

        s_epoch.totalShareBurnAmount -= shareBurnAmount;

        IERC20(share).safeTransfer(user, shareBurnAmount);

        emit WithdrawCancelled(epochNonce, user, shareBurnAmount);
    }
}
