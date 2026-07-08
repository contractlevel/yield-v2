# Design Decisions

## Purpose

This document records intentional Yieldcoin v2 design decisions for auditors and reviewers. It explains why the contracts choose certain accounting, automation, recovery, and adapter boundaries.

This is not the canonical source for execution paths, invariants, roles, or accepted residual risks. Those are maintained in:

- [ARCHITECTURE](./ARCHITECTURE.md) for system components and relationships.
- [PATHS](./PATHS.md) for epoch and rebalance flows.
- [INVARIANTS](./INVARIANTS.md) for safety properties and verification status.
- [ACCESS_CONTROL_MATRIX](./ACCESS_CONTROL_MATRIX.md) for privileged roles and authorities.
- [THREAT_MODEL](./THREAT_MODEL.md) for trust boundaries and threat surfaces.
- [KNOWN_ISSUES](./KNOWN_ISSUES.md) for accepted limitations and caveats.

## DD-001 - Event Shapes Favor Certora Verification

Events are kept simple and, where practical, use no more than three indexed parameters.

This convention makes emitted events and their params easier to formally verify with Certora. It also keeps event assertions consistent across modules and libraries that emit through `delegatecall`.

The convention is not a protocol safety property. If a future event needs a different shape for operational clarity, the event should be designed for that use case and tests/specs should be updated accordingly.

## DD-002 - Recovery Execution Is Permissionless And State-Bound

Recovery functions are designed as public retries of already-authorized failed operations. A recovery caller cannot choose arbitrary funds, destinations, strategies, recipients, or transaction data; those values come from stored recovery state or existing vault state.

This avoids a separate recovery operator role while still allowing anyone to advance the system when the original failure condition clears. Authorization happens when the failed operation stores recovery state; execution consumes that state.

See [ACCESS_CONTROL_MATRIX - Vault Recovery](./ACCESS_CONTROL_MATRIX.md#vault-recovery) and [INVARIANTS - Recovery](./INVARIANTS.md#recovery).

## DD-003 - Vault Logic Is Split Into Libraries

Parent vault epoch, rebalance, fee, CCIP, and user-epoch logic is split into libraries to manage bytecode size and keep verification targets smaller.

The libraries contain accounting and validation logic. The vault contracts retain external orchestration, role checks, policy checks, strategy calls, CCIP calls, and recovery entry points.

This split is an implementation boundary, not a trust boundary: linked libraries execute in the vault context.

## DD-004 - In-Progress Rebalance Completion Can Run While Paused

`completeRebalance` and rebalance-deposit recovery intentionally omit `whenNotPaused`.

A pause should stop new user activity and new privileged operations where appropriate, but it should not necessarily freeze an already-started rebalance in an intermediate state. Allowing completion while paused can restore a coherent active strategy and clear recovery state.

Emergency behavior and pause-related residual risks are tracked in [INVARIANTS - Pause And Emergency Behavior](./INVARIANTS.md#pause-and-emergency-behavior) and [KNOWN_ISSUES](./KNOWN_ISSUES.md).

## DD-005 - CRE Is The Automation And TVL Reporting Layer

Epoch close and rebalance execution are intentionally driven through Chainlink CRE and `WorkflowRouter`.

The contracts do not include autonomous timers or broad manual public execution paths for these operations. `WorkflowRouter` is the narrow on-chain ingress point: it validates workflow metadata and selector allowlists, then dispatches to the configured vault.

This keeps operational authority concentrated in the CRE/router path rather than duplicating privileged execution surfaces. CRE liveness remains an accepted operational dependency.

See [THREAT_MODEL - CRE, TVL, and rebalance decision failure](./THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure) and [KI-007](./KNOWN_ISSUES.md#ki-007--epoch-close-depends-on-cre-workflow-execution).

## DD-006 - `closeEpoch` Trusts CRE-Supplied TVL

`ParentVault.closeEpoch(tvl)` does not independently verify the supplied TVL against on-chain adapter state.

This is deliberate because the active strategy may be on a child chain. The same `closeEpoch` path must support local and remote strategies, so TVL is provided by CRE after reading the active strategy chain. On-chain validation against a local adapter would only cover one topology and would not solve the cross-chain case.

Incorrect TVL can corrupt epoch pricing once users claim against the affected epoch. This is a trust-boundary decision, not a hidden invariant.

See [INVARIANTS - External Assumptions](./INVARIANTS.md#external-assumptions) and [THREAT_MODEL - CRE, TVL, and rebalance decision failure](./THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure).

## DD-007 - Local Failures Revert, Remote Child Failures Store Recovery

Local parent-chain strategy failures revert atomically. Remote child-chain failures store typed recovery state where possible.

The parent can revert local adapter interactions and parent-originated CCIP sends in the same transaction because no cross-chain state has escaped. Child vault flows are asynchronous: once a message has arrived on a child chain or a child begins a remote operation, reverting the original parent transaction is no longer possible. In those cases, the child records the failed step for permissionless retry.

The full path matrix is documented in [PATHS](./PATHS.md). Recovery invariants are documented in [INVARIANTS - Recovery](./INVARIANTS.md#recovery).

## DD-008 - Retry Is Event/Cron Driven, Not Timer Driven On-Chain

The system uses CRE cron triggers and log-triggered follow-up reports to progress epoch and rebalance workflows. Contracts do not run time-based autonomous retries.

This keeps contract logic deterministic and avoids adding a second execution authority. When an operation fails and stores recovery state, retries occur through explicit recovery calls or later workflow execution, depending on the path.

This design means liveness depends on CRE, CCIP, and operator monitoring. Accepted liveness dependencies are tracked in [KNOWN_ISSUES](./KNOWN_ISSUES.md).

## DD-009 - Yield Accounting Is Underlying-Asset-Only

Vault accounting is denominated in the configured underlying asset.

Share price, TVL, epoch settlement, withdraw claims, fees, donations, and emergency drain behavior are all expressed in the underlying asset. Strategy adapters report underlying TVL through `getTVL()`, and `claimAsset` pays only the underlying asset.

Secondary protocol rewards are outside this accounting model. For Compound V3, COMP rewards may accrue to the `CompoundV3Adapter`, and a vault `REWARDS_OPERATOR_ROLE` holder can call `claimRewards(to)` to claim those rewards to a nonzero recipient. That hook is an operator custody/recovery mechanism, not a user distribution mechanism.

The protocol does not currently decide whether claimed COMP is retained, sold, manually distributed, or routed into a future rewards distributor. Handling that on-chain would require additional reward-token accounting, distribution policy, and operational controls. The current design avoids that complexity and keeps user-facing yield calculations underlying-only.

See [ACCESS_CONTROL_MATRIX - Protocol rewards claiming](./ACCESS_CONTROL_MATRIX.md#authority-matrix). If product requirements change to include secondary reward tokens in user yield, this design decision and related accounting invariants should be revisited.
