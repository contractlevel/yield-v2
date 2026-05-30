# Yieldcoin V2 Invariants

## Purpose

This document is the canonical invariant catalogue for the Yieldcoin v2 EVM contracts in `evm/src/`.

Each property defines behavior the system must preserve, the boundary where it must hold, and the intended verification method. Future tests should reference these IDs directly in test names, assertion labels, or failure messages.

<!-- Existing path documentation is useful background, but must not override the contracts when it is stale. -->

## Methodology

Invariants must hold at transaction boundaries after successful calls.

Failed transactions do not violate invariants. "No user can ever cause a revert" is a liveness or UX property, not a safety invariant for this document.

Mid-execution state is not asserted. Functions known to have transient inconsistency include `closeEpoch`, rebalance lifecycle flows, and inbound CCIP handlers.

Invariants are evaluated only between top-level handler calls, not between internal calls within a single transaction.

Invariants must hold under any sequence of valid external calls, including reordering and reentrancy attempts.

Use this fixed test type vocabulary:

| Type            | Meaning                                                                                                  |
| --------------- | -------------------------------------------------------------------------------------------------------- |
| `invariant`     | Holds globally and is asserted by Foundry's invariant runner between successful top-level handler calls. |
| `postcondition` | Holds immediately after a specific function returns and is asserted in that function's handler.          |
| `unit`          | Crafted deterministic unit test.                                                                         |
| `fv`            | Formal verification only.                                                                                |
| `manual`        | Auditor or operator review, not automated.                                                               |

Status values such as `implemented: Foundry + Medusa` mean the property is encoded in the current Chimera suite and has passed local Foundry and Medusa fuzz campaigns. This is fuzzing evidence, not a proof. `partial: Foundry + Medusa` means the implemented suite covers the core state transition or accounting effect, but one or more clauses of the catalogue statement remain represented indirectly, deferred to unit tests, or reserved for later formal verification. Properties that require exhaustive reasoning, arithmetic bounds, or larger state-space guarantees may additionally be verified with Certora later.

Use these ID prefixes:

| Prefix      | Category                                                           |
| ----------- | ------------------------------------------------------------------ |
| `ENV-*`     | External assumptions, not protocol invariants.                     |
| `SOLV-*`    | Solvency and asset backing.                                        |
| `CFG-*`     | Configuration safety.                                              |
| `AC-*`      | Access control.                                                    |
| `PAUSE-*`   | Pause and emergency behavior.                                      |
| `EPOCH-*`   | Epoch lifecycle, accounting, and solvency.                         |
| `SHARE-*`   | Share and fee accounting.                                          |
| `FEE-*`     | Fee-specific accounting.                                           |
| `REBAL-*`   | Rebalance lifecycle.                                               |
| `CCIP-*`    | CCIP behavior.                                                     |
| `REC-*`     | Recovery behavior.                                                 |
| `ROUTER-*`  | WorkflowRouter behavior.                                           |
| `ADAPTER-*` | Adapter registry and protocol adapter behavior.                    |
| `MIG-*`     | Reserved for future migration, upgrade, or state handoff behavior. |

## Solvency

Solvency properties are the headline safety properties. Other sections may reference them when a local invariant is a special case of asset backing.

| ID         | Statement                                                                                                                                                                                                                                                                                | Type             | Status    |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | --------- |
| `SOLV-001` | Parent withdraw solvency must be explicitly modeled: ParentVault USDC balance plus handler-tracked in-flight CCIP withdraw amounts must cover the sum of `remainingWithdrawClaimAmount` for all `CLAIMABLE` epochs. Current invariant coverage tracks settled claimable withdraw obligations; async in-flight CCIP withdraw modeling remains a future extension. | `invariant + fv` | partial: Foundry + Medusa |
| `SOLV-002` | Recovery actions must not bypass solvency: executing any recovery must preserve `SOLV-001` and `CCIP-005b`.                                                                                                                                                                              | `invariant`      | candidate |
| `SOLV-003` | ParentVault share escrow must be attributable to outstanding withdraw intents or claimable withdraw settlement; the vault may intentionally hold shares before `claimUsdc` burns them.                                                                                                   | `invariant`      | candidate |
| `SOLV-004` | Child outbound CCIP recovery is fully collateralized by local USDC while pending. See `CCIP-005b`.                                                                                                                                                                                       | `invariant`      | candidate |
| `SOLV-005` | Per-user redemption integrity: each actor's total economic entitlement across wallet shares, open deposits, claimable deposit shares, open withdraw intents, claimable withdraw USDC, and already claimed USDC must cover contributed principal net of management/performance fees and documented rounding or dust. | `invariant + integration` | implemented: Foundry + Medusa |

## External Assumptions

These are environmental assumptions. They should be verified through deployment checks, integration tests, fork tests, monitoring, or manual review, not treated as pure contract invariants.

| ID        | Statement                                                                                                                                                                                                                                                      | Type     | Status     |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------- |
| `ENV-001` | CRE-reported TVL is trusted. Incorrect TVL can corrupt epoch accounting once claims begin. Off-chain mitigation: the CRE workflow should verify no active recovery state before submitting TVL. TODO: link the CRE workflow recovery-state checker when added. | `manual` | documented |
| `ENV-002` | CCIP router delivery, token transfer semantics, and message authenticity guarantees are trusted. Contract recovery covers stored retry state, not global CCIP liveness.                                                                                        | `manual` | documented |
| `ENV-003` | ACE policy wiring correctly enforces runtime permissions for policy-protected functions.                                                                                                                                                                       | `manual` | documented |
| `ENV-004` | Registered protocol adapters faithfully implement deposit, withdraw, and TVL semantics for their underlying protocols.                                                                                                                                         | `manual` | documented |

## Intentional Deviations

These refine the invariant statements. They are not invariant violations.

| ID        | Deviation                                                                                                                                                                                                                                                                         |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DEV-001` | Performance fee collection is skipped when the fee would consume all TVL. In that degenerate case, the high-water mark is intentionally not updated.                                                                                                                              |
|           |
| `DEV-002` | `YieldcoinShare.totalSupply()` may temporarily differ from `ParentVault.s_totalShares` because claim minting and burning are lazy.                                                                                                                                                |
| `DEV-003` | During cross-chain `REBALANCING`, when funds are in transit on CCIP, `s_activeProtocolAdapter == address(0)` is permitted.                                                                                                                                                        |
| `DEV-004` | `s_treasury == address(0)` is operationally invalid but currently possible because the setter does not enforce a zero-address check. This can break or misdirect fee minting. Recommendation: add an on-chain zero-check, or until then add deployment and monitoring assertions. |
| `DEV-005` | Emergency drain is a break-glass action. If `EMERGENCY_DRAINER_ROLE` drains the vault, `remainingWithdrawClaimAmount` and recovery slots are not automatically reconciled.                                                                                                        |
| `DEV-006` | Dust withdraw claims may round down to zero USDC. The withdraw intent is still consumed and the escrowed shares are burned, but no zero-value USDC transfer is required.                                                                                                           |

## Out-of-Scope Failures

| Failure                                          | Handling                       |
| ------------------------------------------------ | ------------------------------ |
| Bad CRE TVL input                                | See `ENV-001`.                 |
| CCIP delivery failure or message loss            | See `ENV-002`.                 |
| Misconfigured ACE policy stacks                  | See `ENV-003`.                 |
| Malicious or incorrect protocol adapters         | See `ENV-004`.                 |
| Treasury set to zero                             | See `CFG-001` and `DEV-005`.   |
| Emergency drainer role held by an unsafe account | See `PAUSE-005` and `DEV-005`. |

## Non-Invariants

These properties may look attractive to test, but are not intended to hold.

- `s_totalShares` is not monotonic. It can decrease when withdraw shares are accounted and increase through deposits or fees.
- `pricePerShare` is not monotonic. The high-water mark is the monotonic fee reference except in documented fee-skip cases.
- Token `totalSupply()` is not always equal to `ParentVault.s_totalShares` because claim minting and burning are lazy.
- TVL is not always observable on one chain during cross-chain rebalance or bridge-in-flight states.
- User-facing functions are not expected to be revert-free. Expected reverts are not invariant failures.

## Configuration Safety

These are desired configuration properties. Address zero-checks are not currently enforced consistently in code and should be added or covered by deployment and monitoring assertions.

| ID        | Statement                                                                                                                                                                                                                                 | Type     | Status       |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| `CFG-001` | Treasury zero-address is operationally invalid. `s_treasury` should never be `address(0)` after deployment or after `setTreasury`.                                                                                                        | `manual` | not enforced |
| `CFG-002` | Critical address configuration should reject `address(0)`, including treasury, crosschain vault addresses, token addresses, share token, router, adapter registry, adapters, policy engine, and WorkflowRouter vault/forwarder addresses. | `unit`   | not enforced |
| `CFG-003` | Until zero-address checks are added, deployment scripts and monitoring must assert that critical configured addresses are non-zero.                                                                                                       | `manual` | candidate    |

## Access Control

| ID       | Statement                                                                                               | Type            | Status    |
| -------- | ------------------------------------------------------------------------------------------------------- | --------------- | --------- |
| `AC-001` | `DEFAULT_ADMIN_ROLE` administers roles and is not an operational authority.                             | `manual + unit` | candidate |
| `AC-002` | Config setters require `CONFIG_OPERATOR_ROLE`.                                                          | `unit`          | candidate |
| `AC-003` | Epoch and rebalance execution require the WorkflowRouter-held operator roles.                           | `unit`          | candidate |
| `AC-004` | Parent user functions and share token privileged functions rely on ACE policy checks where implemented. | `manual + unit` | candidate |

## Pause And Emergency Behavior

| ID          | Statement                                                                                                                                                                   | Type                     | Status    |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | --------- |
| `PAUSE-001` | Vault `pause` requires `PAUSER_ROLE` and records `s_pausedAt`.                                                                                                              | `unit`                   | candidate |
| `PAUSE-002` | Vault `unpause` requires `UNPAUSER_ROLE` and clears `s_pausedAt`.                                                                                                           | `unit`                   | candidate |
| `PAUSE-003` | WorkflowRouter `pause` and `unpause` require their respective roles.                                                                                                        | `unit`                   | candidate |
| `PAUSE-004` | `emergencyDrain` requires `EMERGENCY_DRAINER_ROLE` and can execute only after the emergency drain delay has elapsed.                                                        | `unit`                   | candidate |
| `PAUSE-005` | Emergency drain is allowed to break normal accounting expectations; after drain, recovery slots and withdraw claim amounts are not automatically reconciled. See `DEV-005`. | `postcondition + manual` | candidate |

## Epoch Lifecycle

| ID          | Statement                                                                                                    | Type            | Status    |
| ----------- | ------------------------------------------------------------------------------------------------------------ | --------------- | --------- |
| `EPOCH-001` | Exactly one current epoch is `OPEN` at transaction boundaries.                                               | `invariant`     | implemented: Foundry + Medusa |
| `EPOCH-002` | Epoch transitions are limited to `OPEN -> CLAIMABLE` or `OPEN -> EXECUTING -> CLAIMABLE`.                    | `invariant`     | candidate |
| `EPOCH-003` | `closeEpoch` cannot run while rebalance is active or the previous epoch is still `EXECUTING`.                | `unit`          | candidate |
| `EPOCH-004` | Closing an epoch always opens the next epoch.                                                                | `postcondition` | implemented: Foundry + Medusa |
| `EPOCH-005` | Deposits, withdraw intents, and cancels only affect the current open epoch.                                  | `invariant`     | implemented: Foundry + Medusa |
| `EPOCH-006` | Cancel refunds the exact escrowed asset and cannot succeed after the user entry has been claimed or deleted. | `postcondition` | partial: Foundry + Medusa |

## Epoch Accounting And Solvency

| ID          | Statement                                                                                                                                                                                                                           | Type                      | Status    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | --------- |
| `EPOCH-007` | Deposit-side remaining counters are monotonically non-increasing after epoch close: `remainingDepositClaimAmount` and `remainingShareMintAmount` never increase.                                                                    | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-008` | Deposit-side remaining counters cannot underflow and must stay bounded by their settlement totals.                                                                                                                                  | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-009` | Deposit-side remaining counters reach zero together: `remainingDepositClaimAmount == 0` if and only if `remainingShareMintAmount == 0`.                                                                                             | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-010` | Withdraw-side remaining counters are monotonically non-increasing after epoch close: `remainingShareBurnAmount` and `remainingWithdrawClaimAmount` never increase.                                                                  | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-011` | Withdraw-side remaining counters cannot underflow and must stay bounded by their settlement totals.                                                                                                                                 | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-012` | Once all withdraw shares for a claimable epoch have been processed, no withdraw claim amount may remain: `remainingShareBurnAmount == 0` implies `remainingWithdrawClaimAmount == 0`. `remainingWithdrawClaimAmount` may reach zero first when dust claims round down; see `DEV-006`. | `invariant`               | implemented: Foundry + Medusa |
| `EPOCH-013` | A user claim or cancel deletes the user's epoch entry and cannot be replayed.                                                                                                                                                       | `postcondition`           | partial: Foundry + Medusa |
| `EPOCH-014` | Local net withdrawals finalize synchronously; remote net withdrawals become claimable only after authenticated CCIP receipt.                                                                                                        | `unit + integration`      | candidate |
| `EPOCH-015` | Parent withdraw solvency is tracked as `SOLV-001`; epoch handlers should update any model state needed to assert it.                                                                                                                | `invariant + fv`          | candidate |

## Share And Fee Accounting

| ID          | Statement                                                                                                                              | Type                 | Status    |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | --------- |
| `SHARE-001` | `ParentVault.s_totalShares` is authoritative, not token `totalSupply()`.                                                               | `manual + invariant` | candidate |
| `SHARE-002` | At epoch close, tracked shares change by new deposit shares minus submitted burn shares, plus any fee shares minted before settlement. | `postcondition`      | candidate |
| `SHARE-003` | Performance fee shares mint only when gross price exceeds the high-water mark and the fee does not consume all TVL.                    | `unit`               | candidate |
| `SHARE-004` | Management fee shares mint only on rebalance finalization.                                                                             | `postcondition`      | candidate |
| `SHARE-005` | All fee shares mint to treasury.                                                                                                       | `invariant`          | candidate |

## Fees

| ID        | Statement                                                                                                                                                           | Type        | Status    |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | --------- |
| `FEE-001` | Performance fee is collected only when gross price per share is greater than the high-water mark. This is also covered by `SHARE-003`.                              | `unit`      | candidate |
| `FEE-002` | Fee shares mint to treasury, not to caller or vault. This property depends on `CFG-001` because a zero treasury is operationally invalid.                           | `unit`      | candidate |
| `FEE-003` | The performance fee high-water mark is monotonically non-decreasing, except that it remains unchanged when fee collection is intentionally skipped under `DEV-001`. | `invariant` | candidate |

## Rebalance Lifecycle

| ID          | Statement                                                                                                                                                                                                              | Type            | Status    |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------- |
| `REBAL-001` | Rebalance state is only `NONE` or `REBALANCING`.                                                                                                                                                                       | `invariant`     | implemented: Foundry + Medusa |
| `REBAL-002` | A new rebalance cannot start while another is active.                                                                                                                                                                  | `unit`          | candidate |
| `REBAL-003` | Rebalance cannot target the current active strategy.                                                                                                                                                                   | `unit`          | candidate |
| `REBAL-004` | `pendingStrategy` is set only while rebalancing and cleared on finalization.                                                                                                                                           | `invariant`     | implemented: Foundry + Medusa |
| `REBAL-005` | Finalization requires the current nonce and increments nonce exactly once.                                                                                                                                             | `postcondition` | implemented: Foundry + Medusa |
| `REBAL-006` | Active strategy changes to pending strategy only on successful finalization, and the active chain's vault adapter matches the active strategy's registered adapter.                                                     | `invariant`     | implemented: Foundry + Medusa |
| `REBAL-007` | During cross-chain `REBALANCING`, `s_activeProtocolAdapter == address(0)` is permitted; `_getTVL()` must still return a sane value through active adapter TVL or `s_rebalanceDepositRecovery.amount` where applicable. | `invariant`     | candidate |
| `REBAL-008` | At transaction boundaries, `s_rebalance.state` cannot be `REBALANCING` when `s_epochNonce > 1` and `s_epochs[s_epochNonce - 1].status == EXECUTING`.                                                                   | `invariant`     | implemented: Foundry + Medusa |

## CCIP

| ID          | Statement                                                                                                                                                                                             | Type            | Status    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------- |
| `CCIP-001`  | Incoming CCIP sender must match the configured crosschain vault for the source selector.                                                                                                              | `unit`          | candidate |
| `CCIP-002`  | Incoming CCIP must deliver exactly one token amount, and the token must be configured USDC.                                                                                                           | `unit`          | candidate |
| `CCIP-003`  | Zero-amount CCIP receives revert.                                                                                                                                                                     | `unit`          | candidate |
| `CCIP-004`  | Parent accepts only `EPOCH_NET_WITHDRAW` and `REBALANCE`; Child accepts only `EPOCH_NET_DEPOSIT` and `REBALANCE`.                                                                                     | `unit`          | candidate |
| `CCIP-005a` | After a failed Child outbound send, `s_ccipSendRecovery.amount > 0`.                                                                                                                                  | `postcondition` | candidate |
| `CCIP-005b` | While `s_ccipSendRecovery.amount != 0`, `USDC.balanceOf(ChildVault) >= s_ccipSendRecovery.amount`. See `SOLV-004`.                                                                                    | `invariant`     | candidate |
| `CCIP-006`  | Recovery slot mutual exclusion: at most one of `s_rebalanceDepositRecovery` and `s_ccipSendRecovery` is non-empty at a transaction boundary. This is the CCIP-specific recovery mutex; see `REC-007`. | `invariant`     | candidate |

## Recovery

| ID         | Statement                                                                                                                                                                                                                                      | Type             | Status    |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | --------- |
| `REC-001`  | Recovery functions consume stored state; caller cannot choose amount, destination, recipient, strategy, or tx data.                                                                                                                            | `invariant`      | candidate |
| `REC-002`  | Recovery sentinel fields are bidirectional: each recovery slot is pending if and only if its sentinel is non-zero; zero `amount` or zero strategy selector means no pending recovery for that slot.                                            | `invariant`      | candidate |
| `REC-003`  | Successful recovery clears state; failed retry preserves state through EVM atomicity.                                                                                                                                                          | `postcondition`  | candidate |
| `REC-004`  | Child epoch deposit and epoch withdraw recovery states are mutually exclusive.                                                                                                                                                                 | `invariant`      | candidate |
| `REC-005a` | Rebalance deposit recovery is singleton per vault.                                                                                                                                                                                             | `invariant`      | candidate |
| `REC-005b` | While `s_rebalanceDepositRecovery.amount != 0`, vault USDC balance plus recoverable or adapter-held funds must be sufficient to complete or retry the stored deposit, with the exact balance formulation confirmed during test implementation. | `invariant + fv` | candidate |
| `REC-006`  | Child CCIP send recovery is singleton and blocks new failed-send storage until cleared.                                                                                                                                                        | `invariant`      | candidate |
| `REC-007`  | Recovery slot mutex: at most one of `s_rebalanceDepositRecovery` and `s_ccipSendRecovery` is non-empty at a transaction boundary. See `CCIP-006`.                                                                                              | `invariant`      | candidate |
| `REC-008`  | Recovery does not bypass solvency: executing recovery consumes stored state and must preserve `SOLV-001` and `CCIP-005b`.                                                                                                                      | `invariant`      | candidate |
| `REC-009`  | There can only be one recovery mode stored at a time.                                                                                                                                                                                          | `invariant`      | candidate |

## WorkflowRouter

| ID           | Statement                                                                     | Type     | Status    |
| ------------ | ----------------------------------------------------------------------------- | -------- | --------- |
| `ROUTER-001` | Only `KEYSTONE_FORWARDER_ROLE` can call `onReport`.                           | `unit`   | candidate |
| `ROUTER-002` | Router must be unpaused for `onReport`.                                       | `unit`   | candidate |
| `ROUTER-003` | Workflow ID, name, and owner must match configured metadata.                  | `unit`   | candidate |
| `ROUTER-004` | Report selector must be allowlisted for that workflow ID.                     | `unit`   | candidate |
| `ROUTER-005` | Router dispatches only to its immutable vault and contains no business logic. | `manual` | candidate |

## Adapters

| ID            | Statement                                                                               | Type        | Status    |
| ------------- | --------------------------------------------------------------------------------------- | ----------- | --------- |
| `ADAPTER-001` | Only config role can mutate protocol adapter registry mappings.                         | `unit`      | candidate |
| `ADAPTER-002` | Vault cannot set or use an unregistered adapter.                                        | `unit`      | candidate |
| `ADAPTER-003` | Protocol adapters only accept deposit and withdraw calls from their configured vault.   | `unit`      | candidate |
| `ADAPTER-004` | Non-active strategy chains report zero TVL except documented recovery-state accounting. | `invariant` | candidate |

## Migration And Upgrade Placeholder

`MIG-*` is reserved for future adapter migration, upgrade, or state handoff invariants.

No `MIG-*` invariants are required until upgrade or migration behavior is added.

## Test Plan

Prioritize invariant and handler work in this order:

1. Epoch accounting counters and solvency.
2. Rebalance state, nonce, and pending strategy lifecycle.
3. Recovery singleton, exclusivity, and recovery-balance coverage.
4. CCIP failed-send recovery and authenticated receive behavior.
5. WorkflowRouter metadata and selector authorization.

Use deterministic unit or integration tests for exact revert branches. Use invariant handlers for stateful sequences over successful deposits, withdraws, cancels, closes, claims, rebalances, CCIP receives, and recoveries.

Treat `ENV-*` entries as assumptions verified through deployment checks, integration or fork tests, monitoring, or manual review.

## Implementation Notes

This document does not require Solidity API, interface, storage, or type changes.

`CCIP-006` and `REC-005b` must be verified during test implementation. If either property is false or too broad, update this document with the actual permitted overlap or balance model instead of forcing the invariant.
