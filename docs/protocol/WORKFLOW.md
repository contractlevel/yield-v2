# CRE Workflow

The Chainlink CRE workflow is Yieldcoin v2's offchain orchestrator. It decides **when** to rebalance or close an epoch, reads the required state, and submits signed reports. The vault contracts remain authoritative: they validate every transition, perform all accounting, and move funds through adapters or CCIP.

The workflow has two flows:

- **Rebalance** — periodically compare approved lending pools and move the active strategy when the improvement is large enough.
- **Epoch settlement** — periodically close a batch of deposits and withdrawals using the active strategy's TVL.

`InitWorkflow` registers each trigger with one handler. Cron triggers start a flow; finalized EVM log triggers continue work that must happen asynchronously on another chain.

## Triggers and handlers

| Trigger                                       | Handler                               | Purpose                                                                                                                                   |
| --------------------------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Rebalance cron                                | `rebalance.OnCronTrigger`             | Select the best approved pool and, when policy permits, call `ParentVault.initiateRebalance`.                                             |
| `ParentVault.RebalanceInitiated`              | `rebalance.OnRebalanceInitiated`      | If the current strategy is remote, call `ChildVault.executeRebalance` on its chain to withdraw and route the capital to the new strategy. |
| `RebalanceDepositSuccess` on each child vault | `rebalance.OnRebalanceDepositSuccess` | Call `ParentVault.completeRebalance` after a child strategy receives and deposits the capital.                                            |
| Epoch cron                                    | `epoch.OnEpochCronTrigger`            | Read the active strategy's TVL and call `ParentVault.closeEpoch`.                                                                         |
| `ParentVault.EpochExecuting`                  | `epoch.OnEpochExecuting`              | For a remote net withdrawal, call `ChildVault.executeEpochWithdraw` on the active strategy chain.                                         |

All EVM log triggers wait for finalized logs. A separate `RebalanceDepositSuccess` handler is registered for every configured child chain, so the concrete handler count grows with the number of child vaults. CRE Workflows can [only be EVM Log-triggered by 5 contracts](https://docs.chain.link/cre/service-quotas#evm-log-trigger). This means Yieldcoin v2 can only support 5 networks. The commercial operator of the protocol should discuss limit increases with Chainlink Labs if required. See // @review insert reference to operator playbooks.

## Rebalance flow

```text
rebalance cron
  -> read ParentVault rebalance state
  -> fetch approved pools from the DefiLlama relay
  -> initiateRebalance(newStrategy) on ParentVault
  -> vaults and CCIP move the position
  -> RebalanceDepositSuccess on a child, when required
  -> completeRebalance() on ParentVault
```

The cron handler does nothing unless all workflow-level checks pass:

- no rebalance is already in progress;
- the one-hour cooldown has elapsed;
- the relay returns both an approved best pool and the current pool;
- the best pool differs from the active strategy; and
- its base APY is at least one percentage point higher.

The DefiLlama request runs on CRE nodes and uses identical-result consensus. The relay is authenticated with a CRE secret, and results are restricted to the pool IDs, chains, projects, and symbols in workflow configuration. These checks decide whether to propose a rebalance; `ParentVault` independently enforces the onchain transition rules.

Some rebalance routes complete synchronously in the initiating transaction or when ParentVault receives a CCIP message. The event handlers naturally no-op where no additional CRE write is needed. See [PATHS.md](PATHS.md#rebalance-flows) for every parent/child route.

## Epoch flow

```text
epoch cron
  -> read ParentVault epoch and rebalance state
  -> read TVL from the vault holding the active strategy
  -> closeEpoch(tvl) on ParentVault
  -> EpochExecuting, only for a remote net withdrawal
  -> executeEpochWithdraw(epochNonce, amount) on ChildVault
  -> CCIP returns the withdrawn asset to ParentVault
```

The cron handler closes an epoch only when:

- no rebalance is in progress;
- the current epoch is open;
- the epoch contains deposits or withdrawal requests; and
- it has been open for at least one hour.

TVL is read from `ParentVault` for a local strategy or from the active `ChildVault` for a remote strategy. CRE uses its consensus-derived time for the age check. After `closeEpoch`, the vault contracts determine whether settlement is local, requires a CCIP deposit, or emits `EpochExecuting` for a remote withdrawal. See [PATHS.md](PATHS.md#epoch-flows) for those settlement paths.

## How a CRE write reaches a vault

Every handler uses the same write path:

```text
handler
  -> ABI-encode the vault function call
  -> generate a signed CRE report
  -> submit it to the chain's WorkflowRouter
  -> Keystone Forwarder calls WorkflowRouter.onReport
  -> WorkflowRouter validates and forwards the calldata to its vault
```

`WorkflowRouter` contains no protocol business logic. It accepts reports only when:

- the caller has the Keystone Forwarder role;
- the router is not paused;
- the report's workflow ID, name, and owner match registered metadata; and
- the vault function selector is allowlisted for that workflow.

The router then calls its immutable vault with the report payload. The vault's role checks and state-machine guards are the final authorization layer. A reverted vault call reverts the router call, and the workflow treats an unsuccessful transaction or receiver execution as an error.

## Configuration

Runtime configuration supplies the two cron schedules, the EVM read block reference, the approved DefiLlama universe, and per-chain vault, router, selector, and gas settings. Exactly one configured chain must contain the `ParentVault`; every other entry represents a child chain.

The workflow is intentionally limited to orchestration. It does not hold funds, calculate vault accounting, bypass contract guards, or replace CCIP recovery. Detailed recovery and execution behavior lives in the vault contracts and is documented in [PATHS.md](PATHS.md).
