# Epoch

Epochs batch user deposits and withdraw intents into discrete settlement periods.

Users submit deposits and withdraw intents to [`ParentVault`](../../evm/src/vaults/ParentVault.sol) during the current open epoch. Deposits escrow the underlying asset. Withdraw intents escrow Yieldcoin shares. No deposit shares are minted immediately when a user deposits.

At epoch close, the CRE [workflow](../../cre/workflow/) reads the current epoch nonce from ParentVault and TVL from the active strategy chain, then calls `ParentVault.closeEpoch(expectedEpochNonce, tvl)` through [`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol). ParentVault rejects the report if `expectedEpochNonce` no longer matches its current epoch. For a matching nonce, the vault uses the CRE-supplied TVL to calculate deposit-share allocations and withdrawal-asset entitlements directly, then opens the next epoch.

After settlement:

- depositors call `claimShares(epochNonce)` to mint their Yieldcoin shares;
- withdrawers call `claimAsset(epochNonce)` to burn escrowed shares and receive the underlying asset;
- users can cancel only current-epoch intents that have not yet settled.

If the active strategy is local to the parent chain, settlement can complete synchronously. If the active strategy is on a child chain, a nonzero net flow enters an executing state. A remote net deposit remains executing until the ChildVault strategy deposit succeeds and CRE calls `completeEpochDeposit(expectedEpochNonce, actualDepositAmount)` with the epoch nonce and amount emitted by `EpochDepositToStrategySuccess`; a remote net withdrawal remains executing until the child withdrawal and CCIP return to ParentVault complete.

## Epoch Status

An epoch moves through up to three statuses after it opens:

- `OPEN` — the epoch accepts deposits and withdraw intents.
- `EXECUTING` — settlement has calculated the epoch allocations, but a remote strategy operation is not yet confirmed on ParentVault. A remote net deposit waits for successful ChildVault deposit acknowledgement; a remote net withdrawal waits for the child withdrawal and CCIP return path.
- `CLAIMABLE` — settlement is finalized. Depositors and withdrawers can claim.

`NONE` is the zero value for a nonce that has never been opened, not a state an opened epoch passes through.

## Reading Epoch State

Epoch state is read from `ParentVault.getEpoch(epochNonce)`.

The returned `Epoch` value includes:

- `totalDepositAmount` / `totalShareBurnAmount` — the epoch's total inflow and outflow, fixed at settlement.
- `totalWithdrawClaimAmount` — the total underlying asset available for withdraw claims. For a remote net withdrawal, the value recorded at epoch close is provisional and is replaced with the actual amount returned through CCIP before the epoch becomes `CLAIMABLE`.
- `remainingDepositClaimAmount` / `remainingShareMintAmount` — the unclaimed portion of deposit-side settlement; both reach zero once every depositor has claimed.
- `remainingShareBurnAmount` / `remainingWithdrawClaimAmount` — the unclaimed portion of withdraw-side settlement; both reach zero once every withdrawer has claimed.
- `openedAtTimestamp` — when the epoch opened; used to enforce the minimum epoch period before it can close.
- `status` — `NONE` (`0`), `OPEN` (`1`), `EXECUTING` (`2`), or `CLAIMABLE` (`3`).

The claimant who exhausts a side's remaining pool last receives that side's rounding remainder, bounded to at most N − 1 smallest output units, where N is the number of claimants on that side.

## Further Reading

For exact execution paths, see [`PATHS`](../protocol/PATHS.md). For epoch safety properties, see [`INVARIANTS`](../security/INVARIANTS.md#epoch-lifecycle).
