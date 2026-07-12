# Rebalance

Rebalancing moves the protocol's active capital from one strategy to another.

The active strategy is where capital in the system is positioned. A rebalance selects a different supported strategy as the pending strategy, withdraws from the old strategy, deposits into the new strategy, then finalizes by making the pending strategy active.

The Chainlink [CRE Workflow](../../cre/workflow) drives rebalance decisions and execution through [`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol). The contracts do not choose strategies autonomously.

On each rebalance run, the workflow:

1. Reads the current rebalance state from [`ParentVault`](../../evm/src/vaults/ParentVault.sol).
2. Skips if a rebalance is already active or the cooldown has not elapsed.
3. Fetches approved yield pool data through the [DefiLlama relay](../../services/defillama-relay/).
4. Selects the best approved pool and compares it with the current active strategy pool.
5. Skips if the active strategy is already optimal or the APY improvement is below the rebalance threshold.
6. Calls `ParentVault.initiateRebalance(newStrategy)` through the parent chain `WorkflowRouter`.

`ParentVault` validates that the requested strategy is supported and registered. It then stores the requested strategy as the pending strategy and starts the rebalance.

Some rebalances are synchronous, such as parent-chain strategy to parent-chain strategy. Cross-chain rebalances are asynchronous and involve `ChildVault` on the relevant strategy chain. If the old active strategy is on a child chain, `ParentVault` emits `RebalanceInitiated`; a CRE log trigger then calls `ChildVault.executeRebalance(...)` on that child chain.

Child vaults handle remote strategy withdraws and deposits. CCIP is used when funds must move between chains. Message-only coordination is handled by emitted events and CRE log-triggered writes to the relevant chain.

When the new strategy deposit succeeds, a `RebalanceDepositSuccess` event is emitted. CRE observes that event and calls `ParentVault.completeRebalance(...)`, unless the path finalizes directly through the parent chain CCIP receive flow. Finalization makes the pending strategy active.

During an in-progress cross-chain rebalance, the protocol may temporarily have a pending strategy and no local active adapter.

Users do not initiate rebalances. The main user-facing effect is that epoch close cannot run while a rebalance is active.

## Reading Rebalance State

Rebalance state is read from `ParentVault.getRebalance()`.

The returned `Rebalance` value includes:

- `nonce` — the rebalance ID. It increments as rebalances are initiated.
- `state` — `NONE` (`0`) when no rebalance is active, or `REBALANCING` (`1`) while a rebalance is in progress.
- `activeStrategy` — the strategy where capital is currently allocated.
- `pendingStrategy` — the strategy where capital is being moved during an active rebalance.
- `lastRebalanceCompletedTimestamp` — when the last rebalance completed; used for fee collection.

Each strategy is a `protocolId` and a `chainSelector`.

## Further Reading

For exact rebalance paths, see [`PATHS`](../protocol/PATHS.md). For rebalance invariants, see [`INVARIANTS`](../security/INVARIANTS.md#rebalance-lifecycle). For rebalance design rationale, see [`DECISIONS`](../protocol/DECISIONS.md).
