# Epoch

Epochs batch user deposits and withdraw intents into discrete settlement periods.

Users submit deposits and withdraw intents to [`ParentVault`](../../evm/src/vaults/ParentVault.sol) during the current open epoch. Deposits escrow the underlying asset. Withdraw intents escrow Yieldcoin shares. No deposit shares are minted immediately when a user deposits.

At epoch close, the CRE [workflow](../../cre/workflow/) reads TVL from the active strategy chain, then calls `ParentVault.closeEpoch(tvl)` through [`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol). The vault uses that CRE-supplied TVL to settle the epoch price, account for new deposit shares, account for shares submitted for withdrawal, and open the next epoch.

After settlement:

- depositors call `claimShares(epochNonce)` to mint their Yieldcoin shares;
- withdrawers call `claimAsset(epochNonce)` to burn escrowed shares and receive the underlying asset;
- users can cancel only current-epoch intents that have not yet settled.

If the active strategy is local to the parent chain, settlement can complete synchronously. If the active strategy is on a child chain and the epoch has a net withdrawal, the epoch enters an executing state until the child chain withdrawal and CCIP return path complete.

For exact execution paths, see [`PATHS`](../protocol/PATHS.md). For epoch safety properties, see [`INVARIANTS`](../security/INVARIANTS.md#epoch-lifecycle).

// @review discuss epoch status and struct

<!--
/// @notice Status of an epoch
    /// @param NONE The epoch has not been opened
    /// @param OPEN The epoch is open for deposits and withdraws
    /// @param EXECUTING The epoch is executing
    /// @param CLAIMABLE The epoch is claimable
    enum EpochStatus {
        NONE, // 0
        OPEN, // 1
        EXECUTING, // 2
        CLAIMABLE // 3
    }

    /// @notice Data for an epoch
    /// @param totalDepositAmount The total amount of asset deposited during the epoch
    /// @param totalShareBurnAmount The total amount of shares submitted to be burned during the epoch
    /// @param totalWithdrawClaimAmount The total amount of asset available for withdraw claims during the epoch
    /// @param pricePerShare The price per share of the epoch
    /// @param remainingDepositClaimAmount The unclaimed asset deposit amount used for shrinking-pool share claims
    /// @param remainingShareMintAmount The unclaimed shares to mint for deposit claims
    /// @param remainingShareBurnAmount The unclaimed shares submitted for withdraw claims
    /// @param remainingWithdrawClaimAmount The unclaimed asset available for withdraw claims
    /// @param openedAtTimestamp The timestamp when the epoch was opened
    /// @param status The status of the epoch
    /// @dev Remaining counter pairs are mutable claim-settlement state. Existing totals remain historical settlement state.
    ///      The claimant who exhausts a side's input pool receives that side's rounding remainder, bounded per side per epoch
    ///      by at most N - 1 smallest output units where N is the number of claimants on that side.
    ///      Deposit-side counters should reach zero together. Withdraw-side counters should reach zero together.
    struct Epoch {
        uint256 totalDepositAmount;
        uint256 totalShareBurnAmount;
        uint256 totalWithdrawClaimAmount;
        uint256 pricePerShare;
        uint256 remainingDepositClaimAmount;
        uint256 remainingShareMintAmount;
        uint256 remainingShareBurnAmount;
        uint256 remainingWithdrawClaimAmount;
        uint256 openedAtTimestamp;
        EpochStatus status;
    }
 -->
