# Epoch

Epochs batch user deposits and withdraw intents into discrete settlement periods.

Users submit deposits and withdraw intents to `ParentVault` during the current open epoch. Deposits escrow the underlying asset. Withdraw intents escrow Yieldcoin shares. No deposit shares are minted immediately when a user deposits.

At epoch close, Chainlink CRE reads TVL from the active strategy chain, then calls `ParentVault.closeEpoch(tvl)` through `WorkflowRouter`. The vault uses that CRE-supplied TVL to settle the epoch price, account for new deposit shares, account for shares submitted for withdrawal, and open the next epoch.

After settlement:

- depositors call `claimShares(epochNonce)` to mint their Yieldcoin shares;
- withdrawers call `claimAsset(epochNonce)` to burn escrowed shares and receive the underlying asset;
- users can cancel only current-epoch intents that have not yet settled or been claimed.

If the active strategy is local to the parent chain, settlement can complete synchronously. If the active strategy is on a child chain and the epoch has a net withdrawal, the epoch enters an executing state until the child chain withdrawal and CCIP return path complete.

For exact execution paths, see [`PATHS`](../protocol/PATHS.md). For epoch safety properties, see [`INVARIANTS`](../security/INVARIANTS.md#epoch-lifecycle).
