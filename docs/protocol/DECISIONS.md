# Design Decisions

## Purpose

This document records intentional Yieldcoin v2 design decisions for auditors and reviewers. It explains why the contracts choose certain accounting, automation, recovery, and adapter boundaries.

This is not the canonical source for execution paths, invariants, roles, or accepted residual risks. Those are maintained in:

- [ARCHITECTURE](./ARCHITECTURE.md) for system components and relationships.
- [PATHS](./PATHS.md) for epoch and rebalance flows.
- [INVARIANTS](../security/INVARIANTS.md) for safety properties and verification status.
- [ACCESS_CONTROL_MATRIX](../security/ACCESS_CONTROL_MATRIX.md) for privileged roles and authorities.
- [THREAT_MODEL](../security/THREAT_MODEL.md) for trust boundaries and threat surfaces.
- [KNOWN_ISSUES](../security/KNOWN_ISSUES.md) for accepted limitations and caveats.

## DD-001 - Event Shapes Favor Certora Verification

Events are kept simple and, where practical, use no more than three indexed parameters.

This convention makes emitted events and their params easier to formally verify with Certora. It also keeps event assertions consistent across modules and libraries that emit through `delegatecall`.

The convention is not a protocol safety property. If a future event needs a different shape for operational clarity, the event should be designed for that use case and tests/specs should be updated accordingly.

## DD-002 - Recovery Execution Is Permissionless And State-Bound

Recovery functions are designed as public retries of already-authorized failed operations. A recovery caller cannot choose arbitrary funds, destinations, strategies, recipients, or transaction data; those values come from stored recovery state or existing vault state.

This avoids a separate recovery operator role while still allowing anyone to advance the system when the original failure condition clears. Authorization happens when the failed operation stores recovery state; execution consumes that state.

See [ACCESS_CONTROL_MATRIX - Vault Recovery](../security/ACCESS_CONTROL_MATRIX.md#vault-recovery) and [INVARIANTS - Recovery](../security/INVARIANTS.md#recovery).

## DD-003 - Vault Logic Is Split Into Libraries

Parent vault epoch, rebalance, fee, CCIP, and user-epoch logic is split into libraries to manage bytecode size and keep verification targets smaller.

The libraries contain accounting and validation logic. The vault contracts retain external orchestration, role checks, policy checks, strategy calls, CCIP calls, and recovery entry points.

This split is an implementation boundary, not a trust boundary: linked libraries execute in the vault context.

## DD-004 - Pause Contains External Execution

While a vault is paused, it does not execute recovery, child epoch withdrawals, child rebalances, or inbound CCIP messages. These paths call strategy adapters, send CCIP messages, or process cross-chain state and must stop during incident containment.

`completeRebalance` and `completeEpochDeposit` intentionally remain callable while paused because they perform only local finalization and do not call an adapter or CCIP router. For the same reason, the CRE deposit-completion handler does not apply the global recovery guard: it acknowledges an already-successful remote deposit and cannot create recovery or start another external operation.

This containment boundary can leave an epoch or rebalance in an intermediate cross-chain state. Operators must inspect the parent, child, recovery, and CCIP message states before resuming the affected operation. The break-glass procedure is documented in [OPERATIONS](../operator/OPERATIONS.md#paused-cross-chain-execution).

Stored recovery handles accepted operations that failed transiently after protocol state had already advanced. Exceptional failures such as a strategy exploit, permanent insolvency, or a protocol-specific migration require operators to pause the affected paths, inspect the exact cross-chain and recovery state, and deploy a purpose-built UUPS upgrade if the existing recovery flow is insufficient. The vaults intentionally expose no generic asset-drain or recapitalization function because moving funds outside normal accounting cannot generically reconcile shares, epochs, rebalances, recovery, and in-flight CCIP state.

## DD-005 - CRE Is The Automation And TVL Reporting Layer

Epoch close and rebalance execution are intentionally driven through Chainlink CRE and `WorkflowRouter`.

The contracts do not include autonomous timers or broad manual public execution paths for these operations. `WorkflowRouter` is the narrow on-chain ingress point: it validates workflow metadata and selector allowlists, then dispatches to the configured vault.

This keeps operational authority concentrated in the CRE/router path rather than duplicating privileged execution surfaces. CRE liveness remains an accepted operational dependency.

Some asynchronous rebalance paths complete through CRE calling `completeRebalance()` after observing a successful deposit event on the receiving chain. Completion does not always depend on an inbound CCIP message to the parent chain; the parent records the pending strategy at initiation and finalizes when the workflow reports that the receiving side completed the deposit.

See [THREAT_MODEL - CRE, TVL, and rebalance decision failure](../security/THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure) and [KI-007](../security/KNOWN_ISSUES.md#ki-007--epoch-close-depends-on-cre-workflow-execution).

## DD-006 - `closeEpoch` Trusts CRE-Supplied TVL

`ParentVault.closeEpoch(tvl)` does not independently verify the supplied TVL against on-chain adapter state.

This is deliberate because the active strategy may be on a child chain. The same `closeEpoch` path must support local and remote strategies, so TVL is provided by CRE after reading the active strategy chain. On-chain validation against a local adapter would only cover one topology and would not solve the cross-chain case.

Incorrect TVL can corrupt epoch pricing once users claim against the affected epoch. This is a trust-boundary decision, not a hidden invariant.

See [INVARIANTS - External Assumptions](../security/INVARIANTS.md#external-assumptions) and [THREAT_MODEL - CRE, TVL, and rebalance decision failure](../security/THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure).

## DD-007 - Local Failures Revert, Remote Child Failures Store Recovery

Local parent-chain strategy failures revert atomically. Remote child-chain failures store typed recovery state where possible.

The parent can revert local adapter interactions and parent-originated CCIP sends in the same transaction because no cross-chain state has escaped. Child vault flows are asynchronous: once a message has arrived on a child chain or a child begins a remote operation, reverting the original parent transaction is no longer possible. In those cases, the child records the failed step for permissionless retry.

This means a local Aave or Compound adapter revert during `closeEpoch` reverts the epoch close. The epoch remains open and CRE can retry after the underlying failure clears. No separate parent-side recovery state is stored for that local synchronous failure.

The full path matrix is documented in [PATHS](./PATHS.md). Recovery invariants are documented in [INVARIANTS - Recovery](../security/INVARIANTS.md#recovery).

## DD-008 - Retry Is Event/Cron Driven, Not Timer Driven On-Chain

The system uses CRE cron triggers and log-triggered follow-up reports to progress epoch and rebalance workflows. Contracts do not run time-based autonomous retries.

This keeps contract logic deterministic and avoids adding a second execution authority. When an operation fails and stores recovery state, retries occur through explicit recovery calls or later workflow execution, depending on the path.

Log-triggered workflow submissions are expected only from standard protocol events emitted during normal state transitions, such as epoch execution and rebalance deposit success. The events do not themselves authorize arbitrary contract calls; `WorkflowRouter` still enforces workflow metadata, selector allowlists, and vault roles before dispatch.

This design means liveness depends on CRE, CCIP, and operator monitoring. Accepted liveness dependencies are tracked in [KNOWN_ISSUES](../security/KNOWN_ISSUES.md).

## DD-009 - Yield Accounting Is Underlying-Asset-Only

Vault accounting is denominated in the configured underlying asset.

Share price, TVL, epoch settlement, withdraw claims, and fees are all expressed in the underlying asset. Strategy adapters report underlying TVL through `getTVL()`, and `claimAsset` pays only the underlying asset.

Secondary protocol rewards are outside this accounting model. For Compound V3, COMP rewards may accrue to the `CompoundV3Adapter`, and a vault `REWARDS_OPERATOR_ROLE` holder can call `claimRewards(to)` to claim those rewards to a nonzero recipient. That hook is an operator custody/recovery mechanism, not a user distribution mechanism.

The protocol does not currently decide whether claimed COMP is retained, sold, manually distributed, or routed into a future rewards distributor. Handling that on-chain would require additional reward-token accounting, distribution policy, and operational controls. The current design avoids that complexity and keeps user-facing yield calculations underlying-only.

See [ACCESS_CONTROL_MATRIX - Protocol rewards claiming](../security/ACCESS_CONTROL_MATRIX.md#authority-matrix). If product requirements change to include secondary reward tokens in user yield, this design decision and related accounting invariants should be revisited.

## DD-010 - Management Fee Accrual Is Gated On Rebalance Finalization

`ParentVaultFeesLib._collectManagementFee` is invoked only from rebalance finalization (`_finalizeRebalance`). `closeEpoch` never collects management fee.

This is deliberate: management fee is charged for the elapsed duration of a completed strategy allocation, not as a background per-epoch accrual, and elapsed time is capped at 365 days per collection regardless of how long the vault stayed on that strategy.

If the vault remains on a single optimal strategy for longer than a year without rebalancing, elapsed time beyond the most recent 365 days is not collected on the eventual next rebalance. That time is forfeited, not deferred - the fee is intentionally capped at one year's worth per collection.

See [INVARIANTS - FEE-004](../security/INVARIANTS.md#fee-accounting).

## DD-011 - Adapter Registry Changes Are Not Live Migrations

The vault reads and validates the AdapterRegistry when activating a strategy, then stores that adapter address. Later registry changes do not replace the active adapter or redirect existing vault operations.

This prevents a configuration update from silently migrating active funds. Replacing a faulty active adapter requires an explicit rebalance or a purpose-built vault upgrade; changing the registry entry alone is insufficient.

A pending destination strategy does not store an adapter address. The destination vault resolves the protocol ID from its local AdapterRegistry when execution arrives, so operators must preserve a valid vault-bound mapping until activation completes.

See [INVARIANTS - Rebalance Lifecycle And TVL](../security/INVARIANTS.md#rebalance-lifecycle-and-tvl) and [INVARIANTS - Adapters](../security/INVARIANTS.md#adapters).

## DD-012 - `forceCancelDeposit` Is A Narrow Epoch-Liveness Tool

`forceCancelDeposit(user)` allows `CANCEL_DEPOSIT_OPERATOR_ROLE` to remove and refund a user's deposit from the current open epoch without the user's participation or an ACE policy check.

This authority exists because an individual deposit can produce a zero-share allocation at settlement and cause the entire epoch close to revert. The operator can remove that deposit so settlement can proceed for the epoch. The function is not intended as a routine user-support path or a general compliance override.

No equivalent forced withdrawal-cancellation or forced claim functions are provided. Those positions do not create the same zero-share epoch-settlement failure, so they do not justify expanding operator authority over user positions.

See [ACCESS_CONTROL_MATRIX - Authority Matrix](../security/ACCESS_CONTROL_MATRIX.md#authority-matrix) and [CONFIG - Operational Functions](../operator/CONFIG.md#operational-functions).

## DD-013 - Compliance Freezes Block Vault User Actions Until Unfrozen

All direct `ParentVault` user functions enforce the configured ACE compliance policy. A frozen user cannot deposit, withdraw, claim shares or assets, or cancel an open deposit or withdrawal until an authorized compliance operator unfreezes the account.

This is the intended effect of a compliance freeze. Open intents and settled claims remain recorded for the user; freezing does not delete, reassign, or settle them through an alternate privileged vault path. Once the account is unfrozen and satisfies the remaining configured policies, the user can resume the normal cancel or claim flow.

`forceCancelDeposit(user)` does not change this policy. Its separate, narrow epoch-liveness purpose is documented in [DD-012](#dd-012---forcecanceldeposit-is-a-narrow-epoch-liveness-tool).

See [COMPLIANCE - ParentVault User Functions](../operator/COMPLIANCE.md#parentvault-user-functions).

## DD-014 - Trusted Configuration Setters Are Idempotent

Trusted configuration setters may accept and re-emit an unchanged value. This keeps configuration behavior consistent and operationally idempotent. Event consumers must not assume every setter event represents a value transition.

## DD-015 - YieldcoinShare Policy Engine Replacement Uses ACE Authorization

`YieldcoinShare.attachPolicyEngine` is intentionally authorized by the currently attached ACE policy engine. During normal operation, `POLICY_ENGINE_MANAGER_ROLE` can replace the engine without a contract upgrade.

If the current engine cannot authorize its replacement, recovery requires an owner-authorized UUPS upgrade. The independent upgrader is the break-glass authority for this failure mode.
