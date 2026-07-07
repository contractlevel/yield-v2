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

Status values such as `implemented: Foundry + Medusa + Recon-fuzzer` mean the property is encoded in the current Chimera suite and has passed local Foundry and Medusa fuzz campaigns and Recon-fuzzer runs. This is fuzzing evidence, not a proof. `partial: Foundry + Medusa + Recon-fuzzer` means the implemented suite covers the core state transition or accounting effect, but one or more clauses of the catalogue statement remain represented indirectly, deferred to unit tests, or reserved for later formal verification. Properties that require exhaustive reasoning, arithmetic bounds, or larger state-space guarantees may additionally be verified with Certora later.

`implemented: Certora` means one or more dedicated Certora rules/invariants named with the property ID (e.g. `EPOCH_003_closeEpoch_RevertWhen_RebalanceInProgress`) verify the property — grep the specs for the ID to find them. `implemented: Certora (per-function rules)` means the property is covered collectively by per-function unit rules that each serve their own function's verification (e.g. every setter's `*_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE` rule); no single rule carries the property ID because no single rule is dedicated to it.

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
| `DONATE-*`  | Role-gated donation behavior.                                      |
| `MIG-*`     | Reserved for future migration, upgrade, or state handoff behavior. |

## Solvency

Solvency properties are the headline safety properties. Other sections may reference them when a local invariant is a special case of asset backing.

| ID         | Statement                                                                                                                                                                                                                                                                                                                                                        | Type                      | Status                                       |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | -------------------------------------------- |
| `SOLV-001` | Parent withdraw solvency must be explicitly modeled: ParentVault USDC balance plus handler-tracked in-flight CCIP withdraw amounts must cover the sum of `remainingWithdrawClaimAmount` for all `CLAIMABLE` epochs. Current invariant coverage tracks settled claimable withdraw obligations; async in-flight CCIP withdraw modeling remains a future extension. | `invariant + fv`          | partial: Foundry + Medusa + Recon-fuzzer     |
| `SOLV-002` | Recovery actions must not bypass solvency: executing any recovery must preserve `SOLV-001` and `CCIP-005b`.                                                                                                                                                                                                                                                      | `invariant`               | partial: Foundry + Medusa + Recon-fuzzer     |
| `SOLV-003` | ParentVault share escrow must be attributable to outstanding withdraw intents or claimable withdraw settlement; the vault may intentionally hold shares before `claimAsset` burns them.                                                                                                                                                                          | `invariant`               | candidate                                    |
| `SOLV-004` | Child outbound CCIP recovery is fully collateralized by local underlying asset while pending. See `CCIP-005b`.                                                                                                                                                                                                                                                   | `invariant`               | implemented: Foundry + Medusa + Recon-fuzzer |
| `SOLV-005` | Per-user redemption integrity: each actor's total economic entitlement across wallet shares, open deposits, claimable deposit shares, open withdraw intents, claimable withdraw asset, and already claimed USDC must cover contributed principal net of management/performance fees and documented rounding or dust.                                             | `invariant + integration` | implemented: Foundry + Medusa + Recon-fuzzer |

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

| ID        | Deviation                                                                                                                                                                  |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DEV-001` | Performance fee collection is skipped when the fee would consume all TVL. In that degenerate case, the high-water mark is intentionally not updated.                       |
|           |
| `DEV-002` | `YieldcoinShare.totalSupply()` may temporarily differ from `ParentVault.s_totalShares` because claim minting and burning are lazy.                                         |
| `DEV-003` | During cross-chain `REBALANCING`, when funds are in transit on CCIP, `s_activeProtocolAdapter == address(0)` is permitted.                                                 |
| `DEV-004` | RESOLVED: `s_treasury != address(0)` is a hard invariant. Enforced at construction and on every call to `setTreasury`.                                                     |
| `DEV-005` | Emergency drain is a break-glass action. If `EMERGENCY_DRAINER_ROLE` drains the vault, `remainingWithdrawClaimAmount` and recovery slots are not automatically reconciled. |
| `DEV-006` | Dust withdraw claims may round down to zero USDC. The withdraw intent is still consumed and the escrowed shares are burned, but no zero-value asset transfer is required.  |

## Out-of-Scope Failures

| Failure                                          | Handling                       |
| ------------------------------------------------ | ------------------------------ |
| Bad CRE TVL input                                | See `ENV-001`.                 |
| CCIP delivery failure or message loss            | See `ENV-002`.                 |
| Misconfigured ACE policy stacks                  | See `ENV-003`.                 |
| Malicious or incorrect protocol adapters         | See `ENV-004`.                 |
| Emergency drainer role held by an unsafe account | See `PAUSE-005` and `DEV-005`. |

## Non-Invariants

These properties may look attractive to test, but are not intended to hold.

- `s_totalShares` is not monotonic. It can decrease when withdraw shares are accounted and increase through deposits or fees.
- `pricePerShare` is not monotonic. The high-water mark is the monotonic fee reference except in documented fee-skip cases.
- Token `totalSupply()` is not always equal to `ParentVault.s_totalShares` because claim minting and burning are lazy.
- TVL is not always observable on one chain during cross-chain rebalance or bridge-in-flight states.
- User-facing functions are not expected to be revert-free. Expected reverts are not invariant failures.

## Configuration Safety

These are desired configuration properties.

| ID        | Statement                                                                                                                                                                                                                                                                                                                                                                                          | Type   | Status                                |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------- |
| `CFG-001` | Critical address configuration should reject `address(0)`, including treasury, crosschain vault addresses, token addresses, share token, router, adapter registry, adapters, policy engine, and WorkflowRouter vault/forwarder addresses. Crosschain vaults and adapters intentionally accept `address(0)` at their setters as an unregister sentinel; zero is rejected at every use site instead. | `unit` | partial: Certora (per-function rules) |

## Access Control

| ID       | Statement                                                                                               | Type            | Status                                        |
| -------- | ------------------------------------------------------------------------------------------------------- | --------------- | --------------------------------------------- |
| `AC-001` | `DEFAULT_ADMIN_ROLE` administers roles and is not an operational authority.                             | `manual + unit` | candidate                                     |
| `AC-002` | Config setters require `CONFIG_OPERATOR_ROLE`.                                                          | `unit`          | implemented: Certora (per-function rules)     |
| `AC-003` | Epoch and rebalance execution require the WorkflowRouter-held operator roles.                           | `unit`          | implemented: Certora (per-function rules)     |
| `AC-004` | Parent user functions and share token privileged functions rely on ACE policy checks where implemented. | `manual + unit` | candidate                                     |
| `AC-005` | Vault donations require `DONATE_OPERATOR_ROLE`, which is distinct from `CONFIG_OPERATOR_ROLE`.          | `unit`          | implemented: Certora (via `DONATE_005_` rule) |

## Pause And Emergency Behavior

| ID          | Statement                                                                                                                                                                   | Type                     | Status                                    |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | ----------------------------------------- |
| `PAUSE-001` | Vault `pause` requires `PAUSER_ROLE` and records `s_pausedAt`.                                                                                                              | `unit`                   | implemented: Certora                      |
| `PAUSE-002` | Vault `unpause` requires `UNPAUSER_ROLE` and clears `s_pausedAt`.                                                                                                           | `unit`                   | implemented: Certora                      |
| `PAUSE-003` | WorkflowRouter `pause` and `unpause` require their respective roles.                                                                                                        | `unit`                   | implemented: Certora                      |
| `PAUSE-004` | `emergencyDrain` requires `EMERGENCY_DRAINER_ROLE` and can execute only after the emergency drain delay has elapsed.                                                        | `unit`                   | implemented: Certora                      |
| `PAUSE-005` | Emergency drain is allowed to break normal accounting expectations; after drain, recovery slots and withdraw claim amounts are not automatically reconciled. See `DEV-005`. | `postcondition + manual` | implemented: Certora (per-function rules) |

## Epoch Lifecycle

| ID          | Statement                                                                                                    | Type            | Status                                                                              |
| ----------- | ------------------------------------------------------------------------------------------------------------ | --------------- | ----------------------------------------------------------------------------------- |
| `EPOCH-001` | Exactly one current epoch is `OPEN` at transaction boundaries.                                               | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-002` | Epoch transitions are limited to `OPEN -> CLAIMABLE` or `OPEN -> EXECUTING -> CLAIMABLE`.                    | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-003` | `closeEpoch` cannot run while rebalance is active or the previous epoch is still `EXECUTING`.                | `unit`          | implemented: Certora                                                                |
| `EPOCH-004` | Closing an epoch always opens the next epoch.                                                                | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules)         |
| `EPOCH-005` | Deposits, withdraw intents, and cancels only affect the current open epoch.                                  | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                        |
| `EPOCH-006` | Cancel refunds the exact escrowed asset and cannot succeed after the user entry has been claimed or deleted. | `postcondition` | implemented: Certora (per-function rules); partial: Foundry + Medusa + Recon-fuzzer |

## Epoch Accounting And Solvency

| ID          | Statement                                                                                                                                                                                                                                                                             | Type                 | Status                                                                              |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ----------------------------------------------------------------------------------- |
| `EPOCH-007` | Deposit-side remaining counters are monotonically non-increasing after epoch close: `remainingDepositClaimAmount` and `remainingShareMintAmount` never increase.                                                                                                                      | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-008` | Deposit-side remaining counters cannot underflow and must stay bounded by their settlement totals.                                                                                                                                                                                    | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-009` | Deposit-side remaining counters reach zero together: `remainingDepositClaimAmount == 0` if and only if `remainingShareMintAmount == 0`.                                                                                                                                               | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-010` | Withdraw-side remaining counters are monotonically non-increasing after epoch close: `remainingShareBurnAmount` and `remainingWithdrawClaimAmount` never increase.                                                                                                                    | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer                                        |
| `EPOCH-011` | Withdraw-side remaining counters cannot underflow and must stay bounded by their settlement totals.                                                                                                                                                                                   | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer + Certora                              |
| `EPOCH-012` | Once all withdraw shares for a claimable epoch have been processed, no withdraw claim amount may remain: `remainingShareBurnAmount == 0` implies `remainingWithdrawClaimAmount == 0`. `remainingWithdrawClaimAmount` may reach zero first when dust claims round down; see `DEV-006`. | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer                                        |
| `EPOCH-013` | A user claim or cancel deletes the user's epoch entry and cannot be replayed.                                                                                                                                                                                                         | `postcondition`      | implemented: Certora (per-function rules); partial: Foundry + Medusa + Recon-fuzzer |
| `EPOCH-014` | Local net withdrawals finalize synchronously; remote net withdrawals enter `EXECUTING` at parent epoch close and become claimable only after authenticated CCIP receipt or successful stored-send recovery.                                                                           | `unit + integration` | implemented: Foundry + Certora (per-function rules)                                 |
| `EPOCH-015` | Parent withdraw solvency is tracked as `SOLV-001`; epoch handlers should update any model state needed to assert it.                                                                                                                                                                  | `invariant + fv`     | candidate                                                                           |

## Share And Fee Accounting

| ID          | Statement                                                                                                                              | Type                 | Status                                       |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | -------------------------------------------- |
| `SHARE-001` | `ParentVault.s_totalShares` is authoritative, not token `totalSupply()`.                                                               | `manual + invariant` | implemented: Foundry + Medusa + Recon-fuzzer |
| `SHARE-002` | At epoch close, tracked shares change by new deposit shares minus submitted burn shares, plus any fee shares minted before settlement. | `postcondition`      | implemented: Foundry + Medusa + Recon-fuzzer |
| `SHARE-003` | Performance fee shares mint only when gross price exceeds the high-water mark and the fee does not consume all TVL.                    | `unit`               | implemented: Certora                         |
| `SHARE-004` | Management fee shares mint only on rebalance finalization.                                                                             | `postcondition`      | candidate                                    |
| `SHARE-005` | All fee shares mint to treasury.                                                                                                       | `invariant`          | implemented: Foundry + Medusa + Recon-fuzzer |

## Fees

| ID        | Statement                                                                                                                                                           | Type        | Status                                       |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | -------------------------------------------- |
| `FEE-001` | Performance fee is collected only when gross price per share is greater than the high-water mark. This is also covered by `SHARE-003`.                              | `unit`      | candidate                                    |
| `FEE-002` | Fee shares mint to treasury, not to caller or vault. This property depends on `CFG-001` because a zero treasury is operationally invalid.                           | `unit`      | candidate                                    |
| `FEE-003` | The performance fee high-water mark is monotonically non-decreasing, except that it remains unchanged when fee collection is intentionally skipped under `DEV-001`. | `invariant` | implemented: Foundry + Medusa + Recon-fuzzer |

## Donations

| ID           | Statement                                                                         | Type            | Status                                                                      |
| ------------ | --------------------------------------------------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| `DONATE-001` | A successful donation increases active strategy TVL by the donated amount.        | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules) |
| `DONATE-002` | A successful donation does not mint shares or change `ParentVault.s_totalShares`. | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `DONATE-003` | A successful donation does not change the current epoch.                          | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `DONATE-004` | Donation can only succeed on the vault that owns the active strategy.             | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules) |
| `DONATE-005` | Donation requires `DONATE_OPERATOR_ROLE`.                                         | `unit`          | implemented: Certora                                                        |

## Rebalance Lifecycle

| ID          | Statement                                                                                                                                                                                                              | Type            | Status                                                                      |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| `REBAL-001` | Rebalance state is only `NONE` or `REBALANCING`.                                                                                                                                                                       | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REBAL-002` | A new rebalance cannot start while another is active.                                                                                                                                                                  | `unit`          | implemented: Certora                                                        |
| `REBAL-003` | Rebalance cannot target the current active strategy.                                                                                                                                                                   | `unit`          | implemented: Certora                                                        |
| `REBAL-004` | `pendingStrategy` is set only while rebalancing and cleared on finalization.                                                                                                                                           | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REBAL-005` | Finalization requires the current nonce and increments nonce exactly once.                                                                                                                                             | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules) |
| `REBAL-006` | Active strategy changes to pending strategy only on successful finalization, and the active chain's vault adapter matches the active strategy's registered adapter.                                                    | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REBAL-007` | During cross-chain `REBALANCING`, `s_activeProtocolAdapter == address(0)` is permitted; `_getTVL()` must still return a sane value through active adapter TVL or `s_rebalanceDepositRecovery.amount` where applicable. | `invariant`     | partial: Certora (per-function rules)                                       |
| `REBAL-008` | At transaction boundaries, `s_rebalance.state` cannot be `REBALANCING` when `s_epochNonce > 1` and `s_epochs[s_epochNonce - 1].status == EXECUTING`.                                                                   | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |

## CCIP

| ID          | Statement                                                                                                                                                                                             | Type            | Status                                                                      |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| `CCIP-001`  | Incoming CCIP sender must match the configured crosschain vault for the source selector.                                                                                                              | `unit`          | implemented: Certora                                                        |
| `CCIP-002`  | Incoming CCIP must deliver exactly one token amount, and the token must be the configured underlying asset.                                                                                           | `unit`          | implemented: Certora                                                        |
| `CCIP-003`  | Zero-amount CCIP receives revert.                                                                                                                                                                     | `unit`          | implemented: Certora                                                        |
| `CCIP-004`  | Parent accepts only `EPOCH_NET_WITHDRAW` and `REBALANCE`; Child accepts only `EPOCH_NET_DEPOSIT` and `REBALANCE`.                                                                                     | `unit`          | implemented: Certora                                                        |
| `CCIP-005a` | After a failed Child outbound send, `s_ccipSendRecovery` exactly records the intended tx type, destination chain, amount, tx data, and a nonzero creation timestamp.                                  | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules) |
| `CCIP-005b` | While `s_ccipSendRecovery.amount != 0`, `asset.balanceOf(ChildVault) >= s_ccipSendRecovery.amount`. See `SOLV-004`.                                                                                   | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `CCIP-005c` | A successful `recoverFailedCcipSend` replays the stored send and completes the intended parent-side state transition for the stored message.                                                          | `postcondition` | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `CCIP-006`  | Recovery slot mutual exclusion: at most one of `s_rebalanceDepositRecovery` and `s_ccipSendRecovery` is non-empty at a transaction boundary. This is the CCIP-specific recovery mutex; see `REC-007`. | `invariant`     | implemented: Foundry + Medusa + Recon-fuzzer                                |

## Recovery

| ID         | Statement                                                                                                                                                                                                                                       | Type             | Status                                                                      |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | --------------------------------------------------------------------------- |
| `REC-001`  | Recovery functions consume stored state; caller cannot choose amount, destination, recipient, strategy, or tx data.                                                                                                                             | `invariant`      | implemented: Certora (per-function rules)                                   |
| `REC-002`  | Recovery sentinel fields are bidirectional: each recovery slot is pending if and only if its sentinel is non-zero; zero `amount` or zero strategy selector means no pending recovery for that slot.                                             | `invariant`      | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REC-003`  | Successful recovery clears state.                                                                                                                                                                                                               | `postcondition`  | implemented: Foundry + Medusa + Recon-fuzzer + Certora (per-function rules) |
| `REC-004`  | Child epoch deposit and epoch withdraw recovery states are mutually exclusive.                                                                                                                                                                  | `invariant`      | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REC-005a` | Rebalance deposit recovery is singleton per vault.                                                                                                                                                                                              | `invariant`      | implemented: Certora                                                        |
| `REC-005b` | While `s_rebalanceDepositRecovery.amount != 0`, vault asset balance plus recoverable or adapter-held funds must be sufficient to complete or retry the stored deposit, with the exact balance formulation confirmed during test implementation. | `invariant + fv` | candidate                                                                   |
| `REC-006`  | Child CCIP send recovery is singleton and blocks new failed-send storage until cleared.                                                                                                                                                         | `invariant`      | implemented: Certora                                                        |
| `REC-007`  | Recovery slot mutex: at most one of `s_rebalanceDepositRecovery` and `s_ccipSendRecovery` is non-empty at a transaction boundary. See `CCIP-006`.                                                                                               | `invariant`      | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REC-008`  | Recovery does not bypass solvency: executing recovery consumes stored state and must preserve `SOLV-001` and `CCIP-005b`.                                                                                                                       | `invariant`      | partial: Foundry + Medusa + Recon-fuzzer                                    |
| `REC-009`  | There can only be one recovery mode stored at a time.                                                                                                                                                                                           | `invariant`      | implemented: Foundry + Medusa + Recon-fuzzer                                |
| `REC-010`  | Failed recovery retry preserves stored recovery state through EVM atomicity.                                                                                                                                                                    | `postcondition`  | implemented: Certora (per-function rules)                                   |

## WorkflowRouter

| ID           | Statement                                                                     | Type     | Status               |
| ------------ | ----------------------------------------------------------------------------- | -------- | -------------------- |
| `ROUTER-001` | Only `KEYSTONE_FORWARDER_ROLE` can call `onReport`.                           | `unit`   | implemented: Certora |
| `ROUTER-002` | Router must be unpaused for `onReport`.                                       | `unit`   | implemented: Certora |
| `ROUTER-003` | Workflow ID, name, and owner must match configured metadata.                  | `unit`   | implemented: Certora |
| `ROUTER-004` | Report selector must be allowlisted for that workflow ID.                     | `unit`   | implemented: Certora |
| `ROUTER-005` | Router dispatches only to its immutable vault and contains no business logic. | `manual` | candidate            |

## Adapters

| ID            | Statement                                                                               | Type        | Status                                       |
| ------------- | --------------------------------------------------------------------------------------- | ----------- | -------------------------------------------- |
| `ADAPTER-001` | Only config role can mutate protocol adapter registry mappings.                         | `unit`      | implemented: Certora                         |
| `ADAPTER-002` | Vault cannot set or use an unregistered adapter.                                        | `unit`      | implemented: Certora                         |
| `ADAPTER-003` | Protocol adapters only accept deposit and withdraw calls from their configured vault.   | `unit`      | implemented: Certora                         |
| `ADAPTER-004` | Non-active strategy chains report zero TVL except documented recovery-state accounting. | `invariant` | implemented: Foundry + Medusa + Recon-fuzzer |

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

`REC-005b` must be verified during test implementation. If the property is false or too broad, update this document with the actual balance model instead of forcing the invariant.
