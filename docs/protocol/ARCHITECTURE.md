# Architecture

## 1. System at a glance

Yieldcoin v2 is a multichain yield vault. Users interact with `ParentVault` on the parent chain.
Capital is deployed to lending protocols through adapters, either locally or on child chains through
CCIP. A Chainlink CRE workflow drives epoch settlement and rebalancing through `WorkflowRouter`.
`YieldcoinShare` represents each user's settled share of the vault.

## 2. Components

- **ParentVault** — single user-facing entry point. Holds the underlying asset (USDC in the initial deployment) only transiently (between deposit and epoch close, or between epoch close and user claim/withdrawal); otherwise capital is deployed into strategies via adapters. Tracks epochs, rebalances and share accounting.
- **ChildVault** — one per remote chain. Receives funds from `ParentVault` via CCIP and routes to local adapters.
- **Strategy adapters** — thin wrappers over external lending protocols (e.g. Aave). One per protocol per chain.
- **AdapterRegistry** — maps registered local protocol IDs to their deployed strategy adapters.
- **YieldcoinShare** — upgradeable, pausable ERC20 share token. Only ParentVault mints and burns.
- **WorkflowRouter** — validates CRE workflow identity and allowlisted selectors, then forwards reports to its immutable vault.
- **Chainlink CRE workflow** — off-chain orchestrator. Triggers epoch close and rebalance actions on-chain.
- **CCIP** — cross-chain messaging and token transport between parent and child vaults.
- **DefiLlama relay** — off-chain process that fetches yield data from the DefiLlama API and feeds it to the CRE workflow; it does not touch on-chain state. The CRE workflow is what reaches contracts, via `WorkflowRouter`.

See [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) for the roles that gate each privileged entry point.

## 3. How they connect

```
        DefiLlama relay (off-chain yield data)             cron schedule
                          │                                      │
                          ▼                                      ▼ triggers
                ┌──────────────────────────────────────────────────────────────┐
                │     Chainlink CRE workflow                                   │
                │  (off-chain orchestrator)                                    │
                └─┬───────────────────────────────────────────────────────┬────┘
                  │ calls          ▲ triggers              ▲              │ calls
                  ▼                │                       │              ▼
                 ┌───────────────┐ │                       │   ┌───────────────┐
                 │WorkflowRouter │ │                       │   │WorkflowRouter │
                 │(parent chain) │ │               triggers│   │(child chain)  │
                 └─────────┬─────┘ │                       │   └───┬───────────┘
                           │       │                       │       │
                           ▼       │                       │       ▼
   User ───────────────▶  ParentVault ◀═CCIP═══════CCIP═▶ ChildVault ──▶ Remote adapter
                                │                                              │
                                ▼                                              ▼
                          Local adapter                                  Lending protocol
                                │
                                ▼
                          Lending protocol
```

- Users submit vault entry and exit operations only to `ParentVault`; they may also transfer or approve `YieldcoinShare` directly.
- `ParentVault` deploys capital either locally (adapter) or remotely (CCIP → `ChildVault` → adapter).
- The CRE workflow reaches `ParentVault` and `ChildVault` via each chain's `WorkflowRouter` to close epochs and rebalance, and both vaults can trigger CRE workflow runs via log trigger.
- `YieldcoinShare` uses standard ERC20 transfers. Pausing the token disables transfers, minting, and burning while leaving approvals available.

## 4. Lifecycle

1. **Deposit** — user calls `ParentVault.deposit`. Funds are escrowed for the current epoch; no shares are minted yet.
2. **Epoch close** — CRE triggers `closeEpoch`. The vault snapshots TVL, locks the settlement price-per-share, computes `newShares` for the batch, and updates per-epoch share accounting; shares are not minted at close. Depositors receive their pro-rata shares by calling `claimShares` after the epoch closes.
3. **Rebalance** — CRE issues rebalance instructions informed by DefiLlama data. Capital moves between adapters and across chains via CCIP.
4. **Withdraw** — user requests a withdrawal. On the next epoch settlement, the withdrawal becomes claimable and its underlying amount is reserved; shares are burned and the underlying asset is transferred only when the user later calls `claimAsset`.

See [`PATHS`](PATHS.md) for the full step-by-step paths, including failure and recovery modes (recovery is permissionless and uses stored state).

## 5. Further reading

- [`PATHS`](PATHS.md) — every execution path in detail
- [`INVARIANTS`](../security/INVARIANTS.md) — protocol-level safety properties
- [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) — roles and privileged functions
- [`KNOWN_ISSUES`](../security/KNOWN_ISSUES.md) — accepted limitations and caveats
