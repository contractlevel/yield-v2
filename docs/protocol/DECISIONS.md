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

See the ParentVault and ChildVault entries in
[ACCESS_CONTROL_MATRIX](../security/ACCESS_CONTROL_MATRIX.md#parentvault) and
[INVARIANTS - Recovery](../security/INVARIANTS.md#recovery).

## DD-003 - Vault Logic Is Split Into Libraries

Parent vault epoch, rebalance, fee, CCIP, and user-epoch logic is split into libraries to manage bytecode size and keep verification targets smaller.

The libraries contain accounting and validation logic. The vault contracts retain external orchestration, role checks, strategy calls, CCIP calls, and recovery entry points.

This split is an implementation boundary, not a trust boundary: linked libraries execute in the vault context.

## DD-004 - Pause Contains External Execution And Lifecycle Finalization

While a vault is paused, it does not execute recovery, child epoch withdrawals, child rebalances, inbound CCIP messages, or ParentVault epoch-deposit and rebalance completion. These paths either interact with external systems or make economically meaningful lifecycle transitions and must stop during incident containment.

`completeRebalance(expectedRebalanceNonce)` and `completeEpochDeposit(expectedEpochNonce, actualDepositAmount)` are submitted after CRE observes success on another chain. The corresponding destination success event supplies the completion nonce, and ParentVault rejects a stale or otherwise mismatched value. For epoch deposits, CRE also forwards the post-CCIP amount from `EpochDepositToStrategySuccess`; Parent uses it to reduce only that epoch's pending share allocation when delivery is short. ParentVault cannot independently prove the observed offchain success, however, and finalization changes authoritative accounting state. A ParentVault pause therefore blocks both functions even though neither calls an adapter or CCIP router. The CRE deposit-completion handler does not apply the global recovery guard because it cannot create recovery or start another external operation; ParentVault independently enforces its pause and lifecycle preconditions.

This containment boundary can leave an epoch or rebalance in an intermediate cross-chain state even after destination execution succeeded. Operators must inspect the parent, child, recovery, and CCIP message states before deliberately unpausing the affected vault and resuming or finalizing the operation. The break-glass procedure is documented in [OPERATIONS](../operator/OPERATIONS.md#paused-cross-chain-execution).

Stored recovery handles accepted operations that failed transiently after protocol state had already advanced. Exceptional failures such as a strategy exploit, permanent insolvency, or a protocol-specific migration require operators to pause the affected paths, inspect the exact cross-chain and recovery state, and deploy a purpose-built UUPS upgrade if the existing recovery flow is insufficient. The vaults intentionally expose no generic asset-drain or recapitalization function because moving funds outside normal accounting cannot generically reconcile shares, epochs, rebalances, recovery, and in-flight CCIP state.

## DD-005 - CRE Is The Automation And TVL Reporting Layer

Epoch close and rebalance execution are intentionally driven through Chainlink CRE and `WorkflowRouter`.

The contracts do not include autonomous timers or broad manual public execution paths for these operations. `WorkflowRouter` is the narrow on-chain ingress point: it validates workflow metadata, the signed destination, report freshness, and selector allowlists, then dispatches to the configured vault.

This keeps operational authority concentrated in the CRE/router path rather than duplicating privileged execution surfaces. CRE liveness remains an accepted operational dependency.

Some asynchronous rebalance paths complete through CRE calling `completeRebalance(expectedRebalanceNonce)` with the nonce from the successful deposit event on the receiving chain. Completion does not always depend on an inbound CCIP message to the parent chain; the parent records the pending strategy at initiation and finalizes when the workflow reports that the receiving side completed the deposit with a matching nonce.

See [THREAT_MODEL - CRE, TVL, and rebalance decision failure](../security/THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure) and [KI-007](../security/KNOWN_ISSUES.md#ki-007--epoch-close-depends-on-cre-workflow-execution).

## DD-006 - `closeEpoch` Trusts CRE-Supplied TVL

`ParentVault.closeEpoch(expectedEpochNonce, tvl)` verifies that `expectedEpochNonce` matches the current parent epoch, but it does not independently verify the supplied TVL against on-chain adapter state.

This is deliberate because the active strategy may be on a child chain. The same `closeEpoch` path must support local and remote strategies, so CRE reads the current nonce from ParentVault and TVL from the active strategy chain before submitting both values. On-chain validation against a local adapter would only cover one topology and would not solve the cross-chain TVL case.

Incorrect TVL can corrupt epoch pricing once users claim against the affected epoch. This is a trust-boundary decision, not a hidden invariant.

This trust decision concerns the accuracy of the value CRE reports. `WorkflowRouter` independently binds each signed report to its intended chain and router and rejects observations more than 30 minutes old; trusting CRE for TVL does not permit an otherwise accurate historical observation to settle an epoch indefinitely later.

See [INVARIANTS - External Assumptions](../security/INVARIANTS.md#external-assumptions) and [THREAT_MODEL - CRE, TVL, and rebalance decision failure](../security/THREAT_MODEL.md#33-cre-tvl-and-rebalance-decision-failure).

## DD-007 - Local Failures Revert, Remote Child Failures Store Recovery

Local parent-chain strategy failures revert atomically. Remote child-chain failures store typed recovery state where possible.

The parent can revert local adapter interactions and parent-originated CCIP sends in the same transaction because no cross-chain state has escaped. Child vault flows are asynchronous: once a message has arrived on a child chain or a child begins a remote operation, reverting the original parent transaction is no longer possible. In those cases, the child records the failed step for permissionless retry.

This means a local Aave or Compound adapter revert during `closeEpoch` reverts the epoch close. The epoch remains open and CRE can retry after the underlying failure clears. No separate parent-side recovery state is stored for that local synchronous failure.

The full path matrix is documented in [PATHS](./PATHS.md). Recovery invariants are documented in [INVARIANTS - Recovery](../security/INVARIANTS.md#recovery).

## DD-008 - Retry Is Event/Cron Driven, Not Timer Driven On-Chain

The system uses CRE cron triggers and log-triggered follow-up reports to progress epoch and rebalance workflows. Contracts do not run time-based autonomous retries.

This keeps contract logic deterministic and avoids adding a second execution authority. When an operation fails and stores recovery state, retries occur through explicit recovery calls or later workflow execution, depending on the path.

Log-triggered workflow submissions are expected only from standard protocol events emitted during normal state transitions, such as epoch execution and rebalance deposit success. The events do not themselves authorize arbitrary contract calls; `WorkflowRouter` still enforces workflow metadata, the signed destination, report freshness, selector allowlists, and vault roles before dispatch.

This design means liveness depends on CRE, CCIP, and operator monitoring. Accepted liveness dependencies are tracked in [KNOWN_ISSUES](../security/KNOWN_ISSUES.md).

## DD-009 - Yield Accounting Is Underlying-Asset-Only

Vault accounting is denominated in the configured underlying asset.

Share price, TVL, epoch settlement, withdraw claims, and fees are all expressed in the underlying asset. Strategy adapters report underlying TVL through `getTVL()`, and `claimAsset` pays only the underlying asset.

Secondary protocol rewards are outside this accounting model. Adapters may accrue rewards from protocol-native controllers, external distributors such as Merkl, partner programs, or similar incentive systems. These rewards are not included in TVL or user entitlements and may remain unclaimed, expire, or become unrecoverable.

For Compound V3, COMP rewards may accrue to the `CompoundV3Adapter`, and a vault `REWARDS_OPERATOR_ROLE` holder can call `claimRewards(to)` to claim supported rewards to a nonzero recipient. This is a best-effort, protocol-specific custody/recovery hook, not a user distribution mechanism or a guarantee that secondary rewards are supported consistently across adapters. `claimRewards` guards against sweeping the vault's underlying asset or the Comet market's own transferable base-asset balance disguised as a reward token, but this is a defensive precaution against a specific misconfiguration, not a completeness guarantee over reward handling generally - consistent with the rest of this decision, an edge case in reward-token identity that falls outside this guard is accepted, not chased.

The protocol does not decide whether claimed rewards are retained, sold, manually distributed, or routed into a future rewards distributor. Supporting secondary rewards consistently would require protocol-specific integrations, reward-token accounting, distribution policy, and operational controls. The current design deliberately avoids that complexity and keeps user-facing yield calculations underlying-only.

See [ACCESS_CONTROL_MATRIX - Protocol Adapters](../security/ACCESS_CONTROL_MATRIX.md#protocol-adapters). If product requirements change to include secondary reward tokens in user yield, this design decision and related accounting invariants should be revisited.

## DD-010 - Management Fee Accrual Is Gated On Rebalance Finalization

`ParentVaultFeesLib._collectManagementFee` is invoked only from rebalance finalization (`_finalizeRebalance`). `closeEpoch` never collects management fee.

This is deliberate: management fee is charged for the elapsed duration of a completed strategy allocation, not as a background per-epoch accrual, and elapsed time is capped at 365 days per collection regardless of how long the vault stayed on that strategy.

If the vault remains on a single optimal strategy for longer than a year without rebalancing, elapsed time beyond the most recent 365 days is not collected on the eventual next rebalance. That time is forfeited, not deferred - the fee is intentionally capped at one year's worth per collection.

See [INVARIANTS - FEE-002](../security/INVARIANTS.md#fee-accounting).

## DD-011 - Adapter Registry Changes Are Not Live Migrations

The vault reads and validates the AdapterRegistry when activating a strategy, then stores that adapter address. Later registry changes do not replace the active adapter or redirect existing vault operations.

This prevents a configuration update from silently migrating active funds. Replacing a faulty active adapter requires an explicit rebalance or a purpose-built vault upgrade; changing the registry entry alone is insufficient.

A pending destination strategy does not store an adapter address. The destination vault resolves the protocol ID from its local AdapterRegistry when execution arrives, so operators must preserve a valid vault-bound mapping until activation completes. If that mapping is missing or misconfigured when execution arrives, adapter resolution reverts the activation transaction outright rather than degrading into the same typed-recovery bookkeeping that covers a subsequent deposit failure — see [KI-022](../security/KNOWN_ISSUES.md#ki-022--adapter-resolution-failure-during-rebalance-activation-reverts-atomically-instead-of-degrading-into-typed-recovery-state).

See [INVARIANTS - Rebalance Lifecycle And TVL](../security/INVARIANTS.md#rebalance-lifecycle-and-tvl) and [INVARIANTS - Adapters](../security/INVARIANTS.md#adapters).

## DD-012 - `forceCancelDeposit` Is A Narrow Epoch-Liveness Tool

`forceCancelDeposit(user)` allows `CANCEL_DEPOSIT_OPERATOR_ROLE` to remove and refund a user's deposit from the current open epoch without the user's participation.

This authority exists because an individual deposit can produce a zero-share allocation at settlement and cause the entire epoch close to revert. The operator can remove that deposit so settlement can proceed for the epoch. The function is not intended as a routine user-support path.

No equivalent forced withdrawal-cancellation or forced claim functions are provided. Those positions do not create the same zero-share epoch-settlement failure, so they do not justify expanding operator authority over user positions.

See [ACCESS_CONTROL_MATRIX - ParentVault](../security/ACCESS_CONTROL_MATRIX.md#parentvault) and [CONFIG - Operational Functions](../operator/CONFIG.md#operational-functions).

## DD-013 - Trusted Configuration Setters Are Idempotent

Trusted configuration setters may accept and re-emit an unchanged value. This keeps configuration behavior consistent and operationally idempotent. Event consumers must not assume every setter event represents a value transition.

## DD-014 - ChildVault Rebalance Entry Points Trust CRE/CCIP-Supplied Target Strategy

`ChildVault.executeRebalance(rebalanceNonce, newStrategy)` does not independently verify `newStrategy` against `ParentVault.s_rebalance.pendingStrategy` before withdrawing from the old strategy and routing funds toward it. The same gap exists symmetrically on the receive side: `ChildVault._ccipReceive`'s `REBALANCE` branch activates whatever `protocolId` is decoded from the inbound CCIP payload, with no local check against an expected value.

This is deliberate, and structural, in both directions: `executeRebalance` is called directly by `WorkflowRouter` off a CRE report, and `_ccipReceive` is called by CCIP - both on a chain other than the one holding `s_rebalance.pendingStrategy`. Unlike `ParentVaultCcipLib._validateRebalance` - which checks a CCIP-delivered `protocolId` against Parent's own local storage as a defense-in-depth consistency check on top of CCIP's own sender authentication, because Parent is the chain that originated the rebalance decision and already persisted it before any message went out - `ChildVault` is never the originating chain for a rebalance. It has no on-chain copy of Parent's pending strategy to check against, at either its CRE-dispatched entry point or its CCIP-received one. Routing the target strategy through an additional authenticated CCIP round-trip to Child before acting would close this gap, but would also change the deliberately-direct (non-CCIP) design of the `Child→Parent`, `Child→same Child`, and `Child A→Child B` rebalance topologies documented in `PATHS.md`.

This is the same trust class as [DD-006](#dd-006---closeepoch-trusts-cre-supplied-tvl): the contracts intentionally do not duplicate CRE's job of deriving the correct value, because there is no cheap on-chain source of truth available at every topology these entry points must support. A CRE workflow bug or misconfiguration that submits the wrong target strategy - or a CCIP-delivered payload with the wrong `protocolId` - is not caught on-chain; it results in the vault's real position diverging from what `ParentVault.s_rebalance.activeStrategy` believes is active until reconciled operationally.

Because there is no contract-side backstop at either entry point, correctness depends entirely on the CRE `RebalanceExecutor` sub-workflow deriving the target strategy from a value it can trust - in practice, reading it directly from the `RebalanceInitiated(rebalanceNonce, protocolId, chainSelector)` event that triggered the workflow, rather than re-deriving or caching it from other state - and on CCIP's own sender authentication being the sole guarantee for the receive side. Get either wrong and there is no on-chain check that will catch it.

See [DD-005](#dd-005---cre-is-the-automation-and-tvl-reporting-layer), [DD-006](#dd-006---closeepoch-trusts-cre-supplied-tvl), and [KI-007](../security/KNOWN_ISSUES.md#ki-007--epoch-close-depends-on-cre-workflow-execution).

## DD-015 - YieldcoinShare's CCIP Admin Is Reserved For Future Cross-Chain Token Support

`YieldcoinShare` stores a CCIP token administrator and exposes `getCCIPAdmin()` and
`setCCIPAdmin(newAdmin)`. The current protocol does not register `YieldcoinShare` as a Chainlink
Cross-Chain Token, deploy a token pool for it, or transfer shares through CCIP. Vault CCIP flows
move the underlying asset and protocol messages; they do not move the share token. The stored value
is therefore unused by the current deployment's execution paths.

The field is retained to support CCIP's custom-admin registration path without introducing a new
storage-layout change solely for that purpose. In that path, the stored address calls
`RegistryModuleOwnerCustom.registerAdminViaGetCCIPAdmin(YieldcoinShare)`. The registry module reads
`getCCIPAdmin()`, requires the returned address to equal the caller, and proposes that address as the
token's administrator in `TokenAdminRegistry`. The proposed administrator must separately accept
the role before it can associate a token pool with the token.

`CONFIG_OPERATOR_ROLE` may update the identity returned by `getCCIPAdmin()`, but the identity itself
is otherwise data only within Yieldcoin v2: it is not consulted for token operations, grants no
`YieldcoinShare` role, cannot mint or burn shares, and cannot authorize a UUPS upgrade. It would
acquire CCIP configuration authority only after completing the external TokenAdminRegistry flow.

Cross-chain share support is not implied by this compatibility field. Enabling it would introduce a
new security and accounting boundary and requires a separate review of token-pool authority,
mint/burn permissions, rate limits, supported chains, and the relationship between cross-chain
token supply and `ParentVault`'s canonical share accounting.

See [YIELDCOIN_SHARE - CCIP Admin](./YIELDCOIN_SHARE.md#ccip-admin) and
[ACCESS_CONTROL_MATRIX - YieldcoinShare](../security/ACCESS_CONTROL_MATRIX.md#yieldcoinshare).

## DD-016 - `WEI_TOLERANCE` Is A Fixed, USDC-Scaled Rounding Tolerance

`ProtocolAdapter._revertIfIncompleteDeposit`/`_revertIfIncompleteWithdraw` permit up to `WEI_TOLERANCE`
(100 raw units) of shortfall between a requested and an actual protocol-side deposit/withdraw amount
before reverting, across all adapters (`AaveV3Adapter`, `AaveV4Adapter`, `CompoundV3Adapter`).

The constant is a fixed raw-unit count, not scaled to `i_assetPrecision`. This is deliberate for the
current USDC-only (6-decimal) deployment: 100 raw units is ~$0.0001, well below any meaningful
rounding concern for the supported lending markets' aToken/index/base-unit rounding behavior.

The constant is not asset-decimals-agnostic by design - it is sized for USDC specifically. Before
onboarding an underlying asset with materially fewer decimals than USDC, `WEI_TOLERANCE` (or its
usage in `ProtocolAdapter`) must be revisited so the tolerance stays a negligible fraction of a
typical deposit/withdraw rather than a fixed absolute amount that becomes economically meaningful at
lower precision.

See [ProtocolAdapter](../../evm/src/modules/ProtocolAdapter.sol).

## DD-017 - Aave Adapters Pin The Provider/Reserve Indirection, Not A Movable Pool Address

`AaveV3Adapter` stores `i_poolAddressesProvider` as immutable and calls `getPool()` fresh on every
deposit, withdraw, and TVL read, rather than caching the Pool address itself. This follows Aave's own
documented integration guidance: the `PoolAddressesProvider` is the stable, canonical entry point,
while the Pool proxy address it resolves to is the part Aave governance can change. Re-resolving
through the provider on every call is the intended way to stay correct across an Aave-side Pool
upgrade, not a coupling risk.

`AaveV4Adapter` stores `i_reserveId` as immutable, caching the positional index of the vault's
underlying asset in the Aave v4 Spoke's reserve list at construction time. This is deliberate: under
the current Aave v4 Spoke implementation, a reserveId is assigned once and is not reused, removed, or
remapped, so re-deriving the index on every call would only add an external call and gas cost for no
correctness benefit.

See [AaveV3Adapter](../../evm/src/modules/adapters/AaveV3Adapter.sol) and
[AaveV4Adapter](../../evm/src/modules/adapters/AaveV4Adapter.sol).

## DD-018 - Default Admin Role Transfer Delay Starts At Zero To Support Deploy-Script Bootstrapping

`ParentVault`, `ChildVault`, and `YieldcoinShare` initialize `AccessControlDefaultAdminRules` with
`INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 0`, unlike `AdapterRegistry` and `WorkflowRouter`, which
accept a deploy-time-configurable `initialDelay`.

This is deliberate. The deploy script needs the deployer EOA to briefly hold `DEFAULT_ADMIN_ROLE` so
it can grant and configure the other launch roles (pauser, unpauser, config operator, upgrader, and so
on) before handing administration off to the configured default admin. A nonzero initial delay would
force that handoff itself to wait out the delay before the intended admin could accept the role, adding
an idle window to every deployment for no security benefit - the deployer key is discarded immediately
after handoff completes, so there is no compromised-key window during the deploy script's own brief
tenure that a delay would meaningfully protect against.

The atomic-proxy-construction pattern documented in
[KI-019](../security/KNOWN_ISSUES.md#ki-019--initialize-functions-have-no-access-control) closes the
equivalent front-running concern for `initialize()` itself; this decision is the analogous reasoning one
level up, for the admin-transfer delay specifically.

The intended default admin is expected to call `changeDefaultAdminDelay` to raise the delay to an
operationally appropriate value (the team's current target is on the order of 3-7 days) as one of its
first actions after accepting the role, outside the deploy script. The contracts do not enforce this -
see
[KI-023](../security/KNOWN_ISSUES.md#ki-023--default-admin-role-transfer-delay-remains-zero-until-the-admin-raises-it-post-handoff)
for the residual risk while it remains unset.

See [ACCESS_CONTROL_MATRIX - Launch Configuration](../security/ACCESS_CONTROL_MATRIX.md#launch-configuration).
