# User Guide

Yieldcoin v2 users interact with `ParentVault` on the parent chain.

ParentVault user functions do not require a role. Calls remain subject to the vault's pause state,
epoch state, amount checks, balances, and allowances.

## Deposit

Minimum deposit: one whole unit of the underlying asset, exposed by `getMinDepositAmount()`. In contract terms this is `10 ** asset.decimals()`.

Deposit flow:

1. Approve `ParentVault` to transfer the underlying asset amount.
2. Call `deposit(amount)`.
3. Store the returned `epochNonce`.
4. Wait for that epoch to close.
5. Call `claimShares(epochNonce)` to receive the allocated Yieldcoin shares.

The deposit is recorded in the current open epoch and the underlying asset is escrowed by the vault. Shares are not minted at deposit time.

Do not transfer tokens directly to a vault address; only use the documented protocol functions. Vaults do not provide a recovery path for unsolicited token transfers.

Useful reads:

- `getDepositAmount(user, epochNonce)` returns the user's submitted deposit amount for that epoch.
- `getEpoch(epochNonce)` returns the epoch data, including its current status.

## Withdraw

Withdraw flow:

1. Approve `ParentVault` to transfer the Yieldcoin share amount.
2. Call `withdraw(shareAmount)`.
3. Store the returned `epochNonce`.
4. Wait for that epoch to become claimable.
5. Call `claimAsset(epochNonce)` to receive the settled underlying asset amount.

The withdraw intent is recorded in the current open epoch and the shares are escrowed by the vault. The user does not receive the underlying asset at withdraw time. Escrowed shares are burned during `claimAsset`.

Useful reads:

- `getWithdrawShareBurnAmount(user, epochNonce)` returns the user's submitted share burn amount for that epoch.
- `getEpoch(epochNonce)` returns the epoch data, including its current status.

## Cancel

Cancel flow:

1. Call `cancelDeposit()` to refund the user's current open epoch deposit.
2. Call `cancelWithdraw()` to return the user's current open epoch withdraw shares.

Cancels only apply to current-epoch intents before they settle. Claims and cancels cannot be replayed after the user's epoch entry has been consumed.

## Share Transfers

YieldcoinShare uses standard ERC20 transfers and approvals. When the token is paused, transfers
revert while approvals remain available.

## Delays And Availability

Epoch settlement and rebalancing are driven by Chainlink CRE. Cross-chain flows depend on CCIP. Some intents can only become claimable after child-chain execution and crosschain settlement is complete.

For detailed protocol behavior, see [`concepts/EPOCH`](./concepts/EPOCH.md), [`concepts/REBALANCE`](./concepts/REBALANCE.md), and [`protocol/PATHS`](./protocol/PATHS.md).
