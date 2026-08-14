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
/// @notice Handles user-level ParentVault epoch operations while ParentVault keeps policy and lifecycle orchestration
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context
library ParentVaultUserEpochLib {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL
    /// @notice Emitted when a deposit is submitted
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset deposited
    event DepositSubmitted(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw intent is submitted
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares escrowed for burning when the withdraw is claimed
    event WithdrawSubmitted(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param depositor The address of the depositor
    /// @param shareMintAmount The amount of Yieldcoin shares minted
    event DepositClaimed(uint256 indexed epochNonce, address indexed depositor, uint256 indexed shareMintAmount);
    /// @notice Emitted when a withdraw is claimed
    /// @param epochNonce The epoch nonce of the claim
    /// @param withdrawer The address of the withdrawer
    /// @param amount The amount of underlying asset withdrawn
    event WithdrawClaimed(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed amount);
    /// @notice Emitted when a deposit is cancelled
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset refunded
    event DepositCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);
    /// @notice Emitted when a withdraw intent is cancelled
    /// @param epochNonce The epoch nonce of the withdraw intent
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares that were intended to burn to redeem the underlying asset
    event WithdrawCancelled(uint256 indexed epochNonce, address indexed withdrawer, uint256 indexed shareBurnAmount);
    /// @notice Emitted when a deposit is force-cancelled by the cancel deposit operator
    /// @param epochNonce The epoch nonce of the deposit
    /// @param depositor The address of the depositor
    /// @param amount The amount of underlying asset refunded
    event DepositForceCancelled(uint256 indexed epochNonce, address indexed depositor, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset into the vault
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The user depositing the underlying asset
    /// @param amount The amount of underlying asset to deposit
    /// @param minDepositAmount The minimum deposit amount
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Reverts if amount is less than minDepositAmount
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires user to have sufficient underlying-asset balance and allowance for amount
    function deposit(
        ParentVaultStore.ParentVaultStorage storage $,
        address asset,
        address user,
        uint256 amount,
        uint256 minDepositAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _deposit($, asset, user, user, amount, minDepositAmount);
    }

    /// @notice Deposits a payer's underlying asset for a beneficiary
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param payer The user supplying the underlying asset
    /// @param beneficiary The user that owns the resulting epoch deposit position
    /// @param amount The amount of underlying asset to deposit
    /// @param minDepositAmount The minimum deposit amount
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Reverts if amount is less than minDepositAmount
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires payer to have sufficient underlying-asset balance and allowance for amount
    function depositFor(
        ParentVaultStore.ParentVaultStorage storage $,
        address asset,
        address payer,
        address beneficiary,
        uint256 amount,
        uint256 minDepositAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _deposit($, asset, payer, beneficiary, amount, minDepositAmount);
    }

    /// @notice Deposits the underlying asset into the vault
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param payer The user supplying the underlying asset
    /// @param beneficiary The user that owns the resulting epoch deposit position
    /// @param amount The amount of underlying asset to deposit
    /// @param minDepositAmount The minimum deposit amount
    /// @return epochNonce The epoch nonce of the deposit
    /// @dev Reverts if amount is less than minDepositAmount
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires payer to have sufficient underlying-asset balance and allowance for amount
    function _deposit(
        ParentVaultStore.ParentVaultStorage storage $,
        address asset,
        address payer,
        address beneficiary,
        uint256 amount,
        uint256 minDepositAmount
    ) internal returns (uint256 epochNonce) {
        if (amount < minDepositAmount) revert IParentVault.ParentVault__AmountTooSmall(amount);
        epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        // This condition should never be hit under normal operations because the epoch nonce is incremented by openNextEpoch
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        $.s_deposits[beneficiary][epochNonce] += amount;
        s_epoch.totalDepositAmount += amount;

        IERC20(asset).safeTransferFrom(payer, address(this), amount);
        emit DepositSubmitted(epochNonce, beneficiary, amount);
    }

    /// @notice Submits a withdraw intent by escrowing shares in the current epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The user submitting the withdraw intent
    /// @param shareBurnAmount The amount of shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires user to have sufficient share balance and allowance for shareBurnAmount
    function withdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address user,
        uint256 shareBurnAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _withdraw($, share, user, user, shareBurnAmount);
    }

    /// @notice Submits a beneficiary-owned withdraw intent using a payer's shares
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param payer The user supplying the shares
    /// @param beneficiary The user that owns the resulting epoch withdraw position
    /// @param shareBurnAmount The amount of shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires payer to have sufficient share balance and allowance for shareBurnAmount
    function withdrawFor(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address payer,
        address beneficiary,
        uint256 shareBurnAmount
    ) public returns (uint256 epochNonce) {
        epochNonce = _withdraw($, share, payer, beneficiary, shareBurnAmount);
    }

    /// @notice Submits a withdraw intent by escrowing shares in the current epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param payer The user supplying the shares
    /// @param beneficiary The user that owns the resulting epoch withdraw position
    /// @param shareBurnAmount The amount of shares to escrow for burning when the withdraw is claimed
    /// @return epochNonce The epoch nonce of the withdraw
    /// @dev Reverts if shareBurnAmount is zero
    /// @dev Reverts if the current epoch is not open
    /// @dev Requires payer to have sufficient share balance and allowance for shareBurnAmount
    function _withdraw(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address payer,
        address beneficiary,
        uint256 shareBurnAmount
    ) internal returns (uint256 epochNonce) {
        if (shareBurnAmount == 0) revert IParentVault.ParentVault__NoZeroAmount();
        epochNonce = $.s_epochNonce;
        Types.Epoch storage s_epoch = $.s_epochs[epochNonce];
        // This condition should never be hit under normal operations because the epoch nonce is incremented by openNextEpoch
        if (s_epoch.status != Types.EpochStatus.OPEN) revert IParentVault.ParentVault__EpochNotOpen(epochNonce);

        $.s_withdraws[beneficiary][epochNonce] += shareBurnAmount;
        s_epoch.totalShareBurnAmount += shareBurnAmount;

        IERC20(share).safeTransferFrom(payer, address(this), shareBurnAmount);

        emit WithdrawSubmitted(epochNonce, beneficiary, shareBurnAmount);
    }

    /// @notice Claims the shares allocated to a user's deposit in a settled epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The depositor claiming shares
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no deposit in the epoch
    /// @dev Consumes the user's entire epoch deposit entry and updates the remaining deposit claim pools
    function claimShares(ParentVaultStore.ParentVaultStorage storage $, address share, address user, uint256 epochNonce)
        public
        returns (uint256 shareMintAmount)
    {
        shareMintAmount = _claimShares($, share, user, epochNonce);
    }

    /// @notice Claims the shares allocated to a user's deposit in a settled epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The depositor claiming shares
    /// @param epochNonce The epoch nonce of the deposit
    /// @return shareMintAmount The amount of Yieldcoin shares minted for the deposit
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no deposit in the epoch
    /// @dev Consumes the user's entire epoch deposit entry and updates the remaining deposit claim pools
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

    /// @notice Claims the underlying asset allocated to a user's withdraw intent in a settled epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param asset The underlying asset token
    /// @param user The withdrawer claiming the underlying asset
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return withdrawAmount The amount of underlying asset withdrawn
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no withdraw intent in the epoch
    /// @dev Consumes the user's entire epoch withdraw entry and updates the remaining withdraw claim pools
    function claimAsset(
        ParentVaultStore.ParentVaultStorage storage $,
        address share,
        address asset,
        address user,
        uint256 epochNonce
    ) public returns (uint256 withdrawAmount) {
        withdrawAmount = _claimAsset($, share, asset, user, epochNonce);
    }

    /// @notice Claims the underlying asset allocated to a user's withdraw intent in a settled epoch
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param asset The underlying asset token
    /// @param user The withdrawer claiming the underlying asset
    /// @param epochNonce The epoch nonce of the withdraw
    /// @return withdrawAmount The amount of underlying asset withdrawn
    /// @dev Reverts if the epoch is not claimable
    /// @dev Reverts if user has no withdraw intent in the epoch
    /// @dev Consumes the user's entire epoch withdraw entry and updates the remaining withdraw claim pools
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

    /// @notice Cancels and refunds a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor cancelling their deposit
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deletes the deposit entry, reduces the epoch deposit total, and refunds the underlying asset
    function cancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) public {
        _cancelDeposit($, asset, user);
    }

    /// @notice Cancels and refunds a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor cancelling their deposit
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deletes the deposit entry, reduces the epoch deposit total, and refunds the underlying asset
    function _cancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) internal {
        (uint256 epochNonce, uint256 depositAmount) = _cancelDepositCore($, asset, user);
        emit DepositCancelled(epochNonce, user, depositAmount);
    }

    /// @notice Force-cancels and refunds a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deletes the deposit entry, reduces the epoch deposit total, and refunds the underlying asset
    function forceCancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) public {
        _forceCancelDeposit($, asset, user);
    }

    /// @notice Force-cancels and refunds a user's deposit in the current open epoch
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being force-cancelled
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deletes the deposit entry, reduces the epoch deposit total, and refunds the underlying asset
    function _forceCancelDeposit(ParentVaultStore.ParentVaultStorage storage $, address asset, address user) internal {
        (uint256 epochNonce, uint256 depositAmount) = _cancelDepositCore($, asset, user);
        emit DepositForceCancelled(epochNonce, user, depositAmount);
    }

    /// @notice Cancels and refunds a user's deposit without selecting the event emitted by the caller
    /// @param $ ParentVault namespaced storage
    /// @param asset The underlying asset token
    /// @param user The depositor whose deposit is being cancelled
    /// @return epochNonce The epoch nonce the deposit was cancelled from
    /// @return depositAmount The amount of underlying asset refunded to the user
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no deposit in the current epoch
    /// @dev Deletes the deposit entry, reduces the epoch deposit total, and refunds the underlying asset
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

    /// @notice Cancels a user's withdraw intent and returns the escrowed shares
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The withdrawer cancelling their withdraw intent
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no withdraw intent in the current epoch
    /// @dev Deletes the withdraw entry, reduces the epoch withdraw total, and returns the escrowed shares
    function cancelWithdraw(ParentVaultStore.ParentVaultStorage storage $, address share, address user) public {
        _cancelWithdraw($, share, user);
    }

    /// @notice Cancels a user's withdraw intent and returns the escrowed shares
    /// @param $ ParentVault namespaced storage
    /// @param share The Yieldcoin share token
    /// @param user The withdrawer cancelling their withdraw intent
    /// @dev Reverts if the current epoch is not open
    /// @dev Reverts if user has no withdraw intent in the current epoch
    /// @dev Deletes the withdraw entry, reduces the epoch withdraw total, and returns the escrowed shares
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
