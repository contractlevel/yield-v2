# Architecture

## 1. System at a glance

Yieldcoin v2 is a multichain yield vault. Users interact only with `ParentVault` on the parent chain. Capital is deployed to lending protocols via adapters — locally, or on child chains via CCIP. A Chainlink CRE workflow drives epoch settlement and rebalancing. A share token enforces compliance via ACE, and `ParentVault` user entry points are ACE-gated too.

## 2. Components

- **ParentVault** — single user-facing entry point. Holds the underlying asset (USDC in the initial deployment) only transiently (between deposit and epoch close, or between epoch close and user claim/withdrawal); otherwise capital is deployed into strategies via adapters. Tracks epochs and share accounting. ACE-gated on user functions.
- **ChildVault** — one per remote chain. Receives funds from `ParentVault` via CCIP and routes to local adapters.
- **Strategy adapters** — thin wrappers over external lending protocols (e.g. Aave). One per protocol per chain.
- **YieldcoinShare** — ERC-3643 compliance token. Transfers and mints/burns are checked against ACE.
- **ACE (Automated Compliance Engine)** — external compliance contract. Gates share transfers and ParentVault user entry points.
- **Chainlink CRE workflow** — off-chain orchestrator. Triggers epoch close and rebalance actions on-chain.
- **CCIP** — cross-chain messaging and token transport between parent and child vaults.
- **DefiLlama relay** — off-chain process that fetches yield data from the DefiLlama API and feeds it to the CRE workflow; it does not touch on-chain state. The CRE workflow is what reaches contracts, via `WorkflowRouter`.

See `ACCESS_CONTROL_MATRIX.md` for the roles that gate each privileged entry point.

## 3. How they connect

```
        DefiLlama relay (off-chain yield data)
                          │
                          ▼
                ┌────────────────────────────────┐
                │     Chainlink CRE workflow     │
                │  (off-chain orchestrator)      │
                └──────────────┬───────────────┬────────────┘
                               │ triggers      │ triggers
                               ▼               ▼
                     ┌────────────────────┐   ┌────────────────────┐
                     │   WorkflowRouter   │   │   WorkflowRouter   │
                     │    (parent chain)  │   │    (child chain)   │
                     └──────────┬─────────┘   └──────────┬─────────┘
                                │  ▲                     │  ▲
                                ▼  │                     ▼  │
   User ──(ACE-gated)──▶  ParentVault ◀═CCIP═══════CCIP═▶ ChildVault ──▶ Remote adapter
                                │                                              │
                                ▼                                              ▼
                          Local adapter                                  Lending protocol
                                │
                                ▼
                          Lending protocol
```

- Users only touch `ParentVault`.
- `ParentVault` deploys capital either locally (adapter) or remotely (CCIP → `ChildVault` → adapter).
- The CRE workflow reaches `ParentVault` and `ChildVault` via each chain's `WorkflowRouter` to close epochs and rebalance, and both vaults can trigger CRE workflow runs back through those routers.
- `YieldcoinShare` transfers consult ACE on every move.

## 4. Lifecycle

1. **Deposit** — user calls `ParentVault.deposit`. ACE check runs. Funds are escrowed; no shares minted yet.
2. **Epoch close** — CRE triggers `closeEpoch`. The vault snapshots TVL, locks the settlement price-per-share, computes `newShares` for the batch, and updates per-epoch share accounting; shares are not minted at close. Depositors receive their pro-rata shares by calling `claimShares` after the epoch closes.
3. **Rebalance** — CRE issues rebalance instructions informed by DefiLlama data. Capital moves between adapters and across chains via CCIP.
4. **Withdraw** — user requests a withdrawal; on the next epoch settlement, shares are burned and the underlying asset is returned.

See `PATHS.md` for the full step-by-step paths, including failure and recovery modes (recovery on `ChildVault` is permissionless and uses stored state).

## 5. Further reading

- `PATHS.md` — every execution path in detail
- `INVARIANTS.md` — protocol-level safety properties
- `ACCESS_CONTROL_MATRIX.md` — roles and privileged functions
- `KNOWN_ISSUES.md` — accepted limitations and caveats
