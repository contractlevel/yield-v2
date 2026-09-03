# Known Issues

This document records security-relevant issues that are known to the protocol team and have been explicitly accepted, deferred, or judged to be outside the trust boundary of the system. Each entry describes the issue, why it is not being mitigated in code (or is only partially mitigated), and the operational or design assumptions that bound its impact.

Entries here are intentionally **not assigned a severity rating** — they are accepted properties of the system, not open findings.

IDs are stable. Once assigned, a KI-XXX identifier is never reused or renumbered, even after the underlying issue is resolved. Resolved issues remain in this document with their status updated.

Several entries below trace to a deliberate architectural choice rather than a residual risk that stands alone — where that's the case, the entry cross-references the relevant decision in [`DECISIONS.md`](../protocol/DECISIONS.md), which is the canonical source for _why_ the system is built that way, not just that the resulting risk is accepted.

---

## KI-001 — Centralized trust in privileged operator/admin roles

**Status:** Accepted.

**Last reviewed:** 2026-06-02

**Component:** Access control across vaults, router, registry, and token.

**Applies to:** ParentVault, ChildVault, WorkflowRouter, AdapterRegistry, and YieldcoinShare.

### Summary

Yieldcoin v2 relies on multiple privileged roles for protocol operation. Human-held privileged roles include:

- **`DEFAULT_ADMIN_ROLE`** for local role administration (grant/revoke and admin-transfer acceptance via `AccessControlDefaultAdminRules`).
- **`CONFIG_OPERATOR_ROLE`** for protocol configuration (vault/router/registry settings, adapter registration, treasury, workflow metadata/selectors, and token CCIP admin wiring).
- **`PAUSER_ROLE` / `UNPAUSER_ROLE`** for pause controls across vaults, WorkflowRouter, and YieldcoinShare.
- **`LINK_OPERATOR_ROLE`** for LINK withdrawal from vaults.
- **`REWARDS_OPERATOR_ROLE`** for claiming supported protocol rewards through adapters.
- **`CANCEL_DEPOSIT_OPERATOR_ROLE`** for force-cancelling a stuck current-epoch deposit.
- **`UPGRADER_ROLE`** for authorizing UUPS implementation upgrades.

The system also includes contract-held or infrastructure roles: `KEYSTONE_FORWARDER_ROLE` for CRE report ingress, `EPOCH_OPERATOR_ROLE` and `REBALANCE_OPERATOR_ROLE` held by WorkflowRouter, and token `MINTER_ROLE`/`BURNER_ROLE` held by ParentVault.

### Threat model

A compromised or malicious signer controlling a privileged role can take adverse actions within that role's authorized scope, including misconfiguration, service interruption, pausing, temporary break-glass role grants, reward or LINK withdrawal, forced deposit cancellation, or upgrades.

### Mitigations

- Split privileged responsibilities across distinct role addresses so no single key controls multiple critical functions.
- Hold each human-operated privileged role behind a multisig.
- Use Cyfrin-qualified signers for privileged multisigs.

### Residual risk

This design still depends on trusted operator signers acting correctly. The risk is accepted as an operational trust assumption and reviewed alongside role assignments and signer hygiene.

---

## KI-002 — Underlying asset issuer can blacklist or pause the protocol

**Status:** Accepted — inherent to the choice of underlying asset.

**Last reviewed:** 2026-06-01

**Component:** Protocol vaults (any vault whose underlying is an issuer-controlled token).

**Applies to:** Yieldcoin v2 USDC vault (first deployment) and any future vault whose underlying token grants its issuer blacklist, freeze, or pause authority.

### Summary

Yieldcoin v2 vaults hold and transact in an underlying ERC-20 asset chosen at deployment time. For the first vault, that asset is **USDC**, issued by Circle. USDC's contract includes administrative controls that allow the issuer to:

- **Blacklist** specific addresses, preventing them from sending or receiving USDC.
- **Pause** all USDC transfers globally.

These controls are properties of the underlying token contract, not of the Yieldcoin v2 protocol. If Circle (or the issuer of any future underlying) exercises them against a Yieldcoin v2 contract address, against strategy contracts, or against the token globally, the protocol's ability to move funds is impaired regardless of how the protocol itself is written.

### Impact if exercised

- **Vault address blacklisted:** the vault cannot send or receive USDC. Deposits and withdrawals revert. Funds already held by the vault are frozen until the blacklist is lifted.
- **Strategy / adapter address blacklisted:** rebalances into or out of that strategy revert; funds parked in that strategy are stuck there until lifted.
- **Global pause:** all USDC transfers revert protocol-wide until unpaused.

In all cases the failure mode is **availability / liveness**, not loss of accounting integrity. Share accounting, rate calculations, and on-chain state remain correct; users cannot exit until the underlying becomes transferable again.

### Why this is accepted, not mitigated

This risk is intrinsic to using an issuer-controlled stablecoin as the underlying asset. It cannot be mitigated inside the protocol's own contracts:

- The protocol does not control the USDC contract and cannot override blacklist or pause decisions.
- Wrapping or substituting the underlying at runtime would itself require moving funds through USDC, which is exactly what the blacklist/pause prevents.
- Using a non-issuer-controlled asset would change the product (Yieldcoin v2 is intentionally a yield-bearing wrapper over a major stablecoin).

The protocol team accepts issuer risk as the cost of denominating vaults in widely-used regulated stablecoins. Vault selection and underlying-asset choice are commercial operator / product decisions, not security bugs.

### Operational assumptions

- Issuer action against a legitimate protocol address is treated as an external incident, handled through off-chain communication with the issuer, not through on-chain mitigations.
- Users are informed (via product documentation and disclosures) that withdrawals depend on the continued transferability of the underlying asset.
- Future vaults using underlyings with similar issuer powers (e.g., other regulated stablecoins) inherit this same accepted risk; vaults whose underlying has no such powers do not.

---

## KI-003 — Dust withdraw intents can round down to a zero-asset claim

**Status:** Accepted — integer-floor pro-rata settlement in `claimAsset`; documented for user awareness.

**Last reviewed:** 2026-06-01

**Component:** Yieldcoin v2 vault withdraw lifecycle (`withdraw` / `claimAsset` in `ParentVault`)

### Summary

Withdraw claims are settled pro-rata per epoch in `claimAsset(epochNonce)`. For non-final claimants, the amount is calculated as:

`withdrawAmount = shareBurnAmount * epoch.remainingWithdrawClaimAmount / epoch.remainingShareBurnAmount`

Because this is integer division, it rounds down. For very small `shareBurnAmount`, `withdrawAmount` can be zero even though shares are burned. In that case, the withdraw intent is deleted and `IShare(i_share).burn(address(this), shareBurnAmount)` still executes, while the asset transfer is skipped by `if (withdrawAmount != 0)`.

### Why this is accepted

- This is expected behavior of integer-floor pro-rata accounting and prevents over-distribution of USDC across claimants.
- The final-claimant branch (`shareBurnAmount == epoch.remainingShareBurnAmount`) assigns the entire remainder to the last claim, preserving epoch-level conservation.
- Adding an on-chain non-zero minimum payout check would either reject otherwise-valid proportional claims or add complexity/gas overhead for an uneconomic dust edge case.
- The economically rational user action is to avoid submitting tiny withdraw intents whose expected claim is zero.

### User-facing mitigation

- Users interacting directly should avoid dust-sized withdraw intents

### Residual risk

- A user who submits and claims a dust-sized withdraw intent can burn shares and receive zero asset for that claim. This loss is self-inflicted and bounded by the dust amount; it does not affect protocol solvency or other users' balances.

---

## KI-004 — Residual CPU/memory DoS surface in `defillama-relay` upstream processing

**Status:** Accepted — mitigated but not eliminated.

**Last reviewed:** 2026-06-02

**Component:** `services/defillama-relay` (`src/lib.rs`, `read_upstream_json`, `read_upstream_body`, and `parse_upstream_json` → `serde_json::from_slice::<DefiLlamaResponse>`).

**Threat model:** A hostile or broken upstream response delivered by DefiLlama, a TLS-terminating/MITM path, or a misconfigured `DEFILLAMA_UPSTREAM_URL`.

### Summary

The relay fetches DefiLlama's pool list and enforces a hard byte cap while streaming the response body. The cap prevents the relay from accumulating more than `MAX_UPSTREAM_BYTES` into its own body buffer, and oversized chunks are rejected before being copied into that buffer.

Two residual resource-exhaustion surfaces remain:

1. The Cloudflare Worker runtime materializes each stream chunk before application code can inspect its size. A malicious or broken upstream that causes the runtime to deliver an unusually large chunk can therefore create transient memory pressure before `read_upstream_body` can reject it.
2. After the bounded body is read, `serde_json::from_slice` deserializes the full response into a `DefiLlamaResponse { data: Vec<Pool> }`. Filtering, allowlisting, and field bounding all happen **after** deserialization.

This means an attacker controlling the upstream response can still force the Worker to:

- Temporarily hold runtime-provided stream chunks before application-level size checks run,
- Tokenize up to the full accepted byte cap of JSON, and
- Allocate a `Vec<Pool>` and associated `String` fields proportional to that accepted body size,

within the Worker's CPU and memory budget for the request.

### Mitigations already in place

1. **Hard accumulated-body byte cap.** `MAX_UPSTREAM_BYTES` is set to **12 MiB**, enforced by `read_upstream_body` via chunked reads. `Content-Length` is used as a cheap early reject; the streamed-read enforcement is authoritative for bytes copied into the relay-owned body buffer and handles chunked / lying upstream responses. This does not prevent the Worker runtime from transiently materializing a stream chunk before application code receives it.
2. **Per-field byte bounds applied post-parse.** Pool IDs are length-bounded by canonical_pool_id; returned metadata fields chain, project, and symbol are trimmed and length-bounded by bounded_field.
3. **Per-response pool cap applied post-parse.** Filtered output is capped at `MAX_RELAY_POOLS`, so even a maximally large upstream cannot push an unbounded list downstream.
4. **Non-finite numeric rejection.** Pools with non-finite `apyBase` are dropped.
5. **Allowlist filtering.** Only pools whose IDs are in the configured allowlist are returned to CRE; unknown pool IDs are discarded.

The byte cap reduces parser exposure. The post-parse checks bound the CRE-facing output and downstream relay work after deserialization succeeds.

### Residual risk

The mitigations bound the relay-owned body buffer, output size, and output shape, but they do not eliminate all upstream-triggered resource use before validation completes. Practical residual effects, if a hostile upstream response is delivered:

- Transient memory pressure while the Worker runtime materializes a large stream chunk before `read_upstream_body` can reject it.
- Elevated CPU and memory while `serde_json` parses up to 12 MiB of attacker-influenced JSON before post-parse filtering and field bounds apply.
- Possible Worker resource-limit termination or relay error, producing a 502/504 or platform-level failure to CRE.
- CRE's rebalance simulation / execution for that cycle fails or stalls until the next successful fetch.

The failure mode is **denial of service for the affected request only**:

- No funds are at risk — the relay holds no assets and signs no transactions.
- No secrets are exposed — the relay has no privileged credentials beyond the outbound fetch.
- No on-chain state is written — the relay is read-only from CRE's perspective.
- Accounting and on-chain protocol state are unaffected; only the data feed is degraded.

### Why this is accepted, not further mitigated

Eliminating the residual would require one of:

- **Platform-level chunk/read controls.** This would be needed to prevent runtime chunk materialization before application code receives each chunk. The relay currently does not have lower-level control over Cloudflare's internal chunk allocation.
- **A bounded `serde` deserializer** (custom `SeqAccess` visitor capping pool count during parse). This is feasible with no new dependencies and would cap Pool allocation and data-array parsing after N pools, while the existing byte cap would still bound raw body buffering.
- **Streaming / incremental JSON parsing.** Adds meaningful complexity, and may require adapter code or additional dependencies in this Worker runtime.
- **Further lowering the byte cap.** 12 MiB is already chosen as the smallest value that comfortably fits a legitimate DefiLlama response with margin; going lower risks rejecting valid upstream payloads.

Given:

- The attack requires upstream compromise (not direct attacker access to the relay).
- The worst case is per-request DoS of a read-only data feed, not loss of funds or state.
- All downstream consumers (CRE, vaults) are designed to tolerate transient relay unavailability.

The team accepts the residual as commensurate with the impact and the simplicity goals of the relay. This entry exists so that any future change increasing the relay's privilege, the underlying asset's sensitivity to the feed, or the relay's role in on-chain decisions triggers a re-evaluation.

### Conditions that would warrant revisiting

- The relay gains write authority or signing capability.
- The relay's output begins driving automated on-chain actions without independent sanity checks downstream.
- DefiLlama's response format changes in a way that makes 12 MiB an uncomfortable fit, forcing the cap upward.
- A bounded-deserializer or streaming-parse implementation becomes cheap enough (in code complexity terms) to justify closing the residual.

### Related accepted risks

This entry is limited to relay resource consumption while processing upstream responses. Incorrect or manipulated yield data from a compromised DefiLlama API, relay deployment, or relay configuration is documented separately in [KI-011](#ki-011--compromised-defillama-api-or-relay-can-skew-rebalance-inputs).

---

## KI-005 — Settlement overwrites price-locked withdraw estimates with actual adapter/bridge output

**Status:** Accepted — deliberate to prevent stranded, untracked underlying asset tokens in the `ParentVault`.

**Last reviewed:** 2026-06-08

**Component:** `ParentVault.closeEpoch` (local-strategy settlement path) and `ParentVault._ccipReceive` (remote-strategy settlement path), in combination with strategy adapters (`AaveV3Adapter`, `AaveV4Adapter`, `CompoundV3Adapter`, and any future adapters).

### Summary

At epoch close, the vault initially price-locks an expected withdraw amount per epoch (`epoch.totalWithdrawClaimAmount`), computed from the epoch's share-to-asset price and the total shares queued for withdraw. The vault then calls the active adapter (or, for remote strategies, receives a CCIP bridged transfer from a `ChildVault`) to actually realize the withdrawn asset.

In both settlement paths, the vault then **overwrites** the price-locked estimate with the actual amount produced by the adapter / bridge, and uses that actual amount as `totalWithdrawClaimAmount` for the epoch's `claimAsset` distribution:

- **Local-strategy path (`closeEpoch`):** `totalWithdrawClaimAmount` is set to the adapter's reported withdraw output.
- **Remote-strategy path (`_ccipReceive`):** `totalWithdrawClaimAmount` is set to the `receivedAmount` delivered by CCIP from the withdrawing `ChildVault`.

If actual > expected, the surplus is attributed pro-rata to withdrawers in that epoch rather than retained by the vault. If actual < expected, withdrawers absorb the shortfall pro-rata (although in practice, this second condition should never occur, given adapters will revert if actual < expected).

### Why this is accepted, not mitigated

The vault's solvency model is anchored on `adapter.getTVL()`. The vault contract itself is treated as a transient holder of the underlying asset — funds either sit in an adapter (and are visible to `getTVL`) or are in-flight during deposit/close/claim. Any asset token left as an idle vault balance after `closeEpoch` is **invisible to `getTVL`** and therefore missing from the next epoch's share price calculation, where it would remain stranded indefinitely.

For each path, the alternative (cap the claim at the expected amount, retain the surplus in the vault) was considered and rejected:

- **Local-strategy path.** Redepositing any surplus into the still-active adapter in the same transaction is technically possible but was rejected to avoid an additional adapter call on the close-epoch hot path, and to remain symmetric with the remote path where redepositing is impossible.
- **Remote-strategy path.** Redepositing is not an option at all: the surplus tokens just arrived on the parent chain from a remote `ChildVault`. There is no local adapter to redeposit it into without re-issuing a cross-chain transfer.

Under the current adapter set (Aave V3 / V4, Compound V3 specific-amount withdraws), the discrepancy between requested and received is bounded by protocol-side rounding and is empirically ~0 per withdraw. Under CCIP, the bridged amount equals exactly what the `ChildVault` sent, so any surplus in the remote path originates from the same protocol-side rounding as the local path. Attributing this bounded surplus to the withdrawing cohort is acceptable in exchange for the invariant that **no idle asset accumulates outside `adapter.getTVL()` or in-flight deposit/close/claim**.

### Residual risk

- **Withdrawers absorb surplus and shortfall.** Withdrawers in the closing epoch receive any positive or negative delta between the price-locked estimate and the actual adapter / bridge output. Non-withdrawing shareholders are insulated from this delta. Given current adapters, this delta is bounded by protocol-side rounding (~0 for specific-amount withdraws) and is not materially distinguishable from normal pro-rata claim arithmetic.
- **Trust in adapter honesty.** The overwrite trusts the adapter's reported output and (for remote strategies) the CCIP-delivered amount. A malicious or buggy adapter that over-reports its withdraw output would cause the vault to over-attribute to withdrawers without actually holding it, manifesting as a failed transfer in `claimAsset`. This is consistent with the broader trust assumption that registered adapters are vetted; it is not introduced by the overwrite itself.
- **No solvency impact.** Share accounting (`totalShares`) and `getTVL`-based pricing remain correct. The overwrite affects only the distribution of a single epoch's withdraw cohort, not the vault's overall solvency or other users' balances.

### Conditions that would warrant revisiting

- A new adapter is registered whose withdraw output can deviate materially (more than protocol-rounding) from the requested amount — at which point the overwrite would shift non-trivial value between withdrawers and non-withdrawers and the cap-and-redeposit alternative should be reconsidered.
- A new strategy topology is introduced where surplus asset token can be redeposited cheaply into an adapter on the parent chain at epoch close (e.g., a permanently-active fallback adapter), making the local-path "redeposit surplus" alternative effectively free.
- CCIP semantics change such that the bridged amount can diverge from the `ChildVault`-sent amount, introducing a new source of remote-path delta independent of the underlying adapter's behavior.

---

## KI-006 — Management fee accumulator includes vault pause duration

**Status:** Accepted — mitigated by a one-year cap per management fee collection.

**Last reviewed:** 2026-06-13

**Component:** `ParentVaultFeesLib._collectManagementFee` (invoked from `ParentVaultRebalanceLib._finalizeRebalance`), vault pause controls, and rebalance finalization.

### Summary

Management fees accrue on calendar time between completed rebalances. `ParentVaultFeesLib._collectManagementFee` uses the elapsed time between `s_rebalance.lastRebalanceCompletedTimestamp` and the current rebalance finalization, capped at `365 days` per collection. It does not subtract time where the vault was paused.

This means a pause interval can contribute to the next management fee collection. The fee remains bounded by the annual management fee formula for a single collection: at the current `MANAGEMENT_FEE_BPS = 100`, no rebalance finalization can collect more than the one-year management fee amount (`ceil(totalShares * 1%)`) regardless of how long the vault was paused or how long rebalance finalization was delayed.

### Why this is accepted, not fully excluded

The management fee is treated as an AUM-style calendar-time fee, not purely as a fee for uninterrupted user-facing availability. During a pause, capital may still remain deployed in a strategy and continue earning yield.

The `ParentVault` can only observe its own pause state. It cannot reliably determine whether the full system was operational across ChildVaults, WorkflowRouters, underlying token transferability, strategy protocols, adapters, and cross-chain settlement. Subtracting only locally observed pause intervals would create incomplete liveness accounting and could undercharge management fees while funds remain deployed and yield-bearing.

### Mitigation

The fee collection is capped at one year of elapsed time per rebalance finalization. Long pauses, delayed rebalances, or other operational stalls cannot cause a single management fee collection to accrue across multiple years.

### Residual risk

Shareholders can still pay management fees for time when the user-facing vault was paused. The impact is bounded by the one-year cap per collection and by trusted pause/unpause operations. This is an accepted economic design choice rather than an accounting invariant violation.

### Conditions that would warrant revisiting

- Product policy changes to require no management fees during downtime.
- A reliable system-wide pause/liveness oracle is introduced across ParentVault, ChildVaults, WorkflowRouters, underlying token state, strategy protocols, and cross-chain settlement.
- Rebalance cadence changes in a way that makes repeated one-year capped collections during long-term operational downtime plausible.

---

## KI-007 — Epoch close depends on CRE workflow execution

**Status:** Accepted — operational liveness dependency.

**Last reviewed:** 2026-08-22

**Component:** CRE epoch workflow, `WorkflowRouter.onReport`, `ParentVault.closeEpoch`, and `ParentVault.completeEpochDeposit`.

### Summary

Epoch settlement is intentionally driven by the Chainlink CRE workflow. The workflow's cron handler reads the current parent epoch and its nonce, checks that it is open, has activity, is past `MIN_EPOCH_PERIOD`, has no active rebalance, reads TVL from the active strategy chain, and submits `closeEpoch(expectedEpochNonce, tvl)` through `WorkflowRouter.onReport`.

If the initial CRE step does not execute, cannot read the required state, cannot submit a valid report, or the report does not reach `WorkflowRouter`, the current parent epoch remains `OPEN`. If a required remote continuation fails, the closed epoch remains `EXECUTING`. There is no autonomous on-chain timer or public completion path; `closeEpoch` and `completeEpochDeposit` are restricted to `EPOCH_OPERATOR_ROLE`, which is granted to the `WorkflowRouter` under the normal access-control model.

### Impact

The failure mode is delayed settlement:

- The current epoch remains open until a valid workflow report closes it.
- Depositors and withdrawers for that epoch cannot claim shares or assets while the epoch remains open.
- The next epoch is not opened, so later user intents continue to accrue into the same open epoch rather than a new scheduled epoch.
- Settlement allocations use a TVL observation signed no more than 30 minutes before the eventual close, not a snapshot from an earlier missed close attempt. Once a report expires, settlement requires a fresh report.
- For remote-strategy net-withdraw epochs, the second CRE step (`EpochWithdrawExecuting` log handling on the child chain) is required before the parent epoch can become claimable.
- For remote-strategy net-deposit epochs, CRE observes the destination ChildVault's `EpochDepositToStrategySuccess` event and submits `completeEpochDeposit(event.epochNonce, event.amount)` before the parent epoch can become claimable.

With the report freshness check, a missed workflow execution does not by itself create an accounting inconsistency or direct loss of funds: an old failed report cannot later settle changed epoch contents using its historical TVL observation. User deposits and withdraw-intent shares remain escrowed by the protocol. While the epoch is still open, users may cancel their current-epoch deposit or withdraw intent through the normal cancellation functions, subject to the usual pause and state checks. Once the epoch itself is no longer open — including the `EXECUTING` window described above — cancellation is not available either; see [KI-017](#ki-017--deposit-and-withdraw-cancellation-is-scoped-to-the-current-epoch-only).

### Why this is accepted, not mitigated on-chain

Closing an epoch requires a fresh TVL value for the active strategy, which may live on the parent chain or a child chain. The contracts deliberately do not compute or validate that cross-chain TVL on-chain. Instead, CRE is the trusted automation and reporting layer for epoch settlement, and `WorkflowRouter` is the narrow on-chain ingress point: it validates workflow metadata and selector allowlists, binds the report to its intended chain and router, and rejects observations more than 30 minutes old.

Adding an on-chain time-based auto-close is not sufficient because the vault still needs the TVL input. Adding a broad manual close path would either:

- require a privileged operator to provide the same trusted TVL value directly, increasing human operational authority; or
- duplicate the existing CRE report path with another privileged ingress surface.

The current design keeps the authority narrow: the router validates workflow metadata, selector allowlists, report destination, and observation age, then calls only the configured vault. Liveness of that workflow is therefore an operational assumption, not a contract invariant.

### Operational mitigations

- Monitor missed CRE cron executions, failed workflow runs, Keystone Forwarder delivery failures, and `WorkflowRouter.onReport` reverts.
- Alert when `ParentVault.getEpochNonce()` has not advanced after the expected close window and the open epoch has nonzero activity.
- Alert when a remote net-deposit epoch remains `EXECUTING` after the destination ChildVault emits `EpochDepositToStrategySuccess`, or when the corresponding `completeEpochDeposit(expectedEpochNonce, actualDepositAmount)` report fails.
- Ensure the deployed workflow metadata and selector allowlists include both `closeEpoch(uint256,uint256)` and `completeEpochDeposit(uint256,uint256)` for the active epoch workflow ID.
- Keep CRE configuration, Keystone Forwarder configuration, workflow ownership, gas limits, and chain selectors under deployment/runbook review.
- In an emergency, the commercial operator can update workflow configuration or, if explicitly accepted through an operational runbook, grant temporary epoch authority to a replacement router/operator and revoke it after recovery. This is a privileged break-glass action and should be treated as an operational trust escalation.

### Residual risk

Epoch settlement can be delayed indefinitely if CRE or report delivery remains unavailable and operators do not execute a recovery process. During that delay, claims are unavailable and the epoch's final price remains unset. The primary impact is availability and timing uncertainty, not protocol solvency.

The risk is accepted because the protocol already trusts CRE for TVL reporting and workflow-triggered settlement. This entry documents that the same trust boundary includes liveness of the epoch-close workflow.

### Conditions that would warrant revisiting

- Product requirements change to require guaranteed epoch close by wall-clock time.
- A reliable on-chain or independently verified TVL source becomes available for all supported strategy chains.
- Operations require a standing manual close role rather than a break-glass process.
- CRE or Keystone Forwarder reliability assumptions change materially.

---

## KI-008 — Strategy TVL can include permissionless third-party supplies

**Status:** Accepted — epoch batching prevents the flash-loan variant; the permanent locked seed position bounds the bootstrap variant described in KI-024.

**Last reviewed:** 2026-08-22

**Component:** Strategy adapters (`AaveV3Adapter`, `AaveV4Adapter`, `CompoundV3Adapter`), active strategy `getTVL`, CRE epoch workflow, `ParentVault.closeEpoch`, and its zero-share-mint guard (`ParentVault__DepositWouldMintZeroShares`).

### Summary

The strategy adapters report TVL from the active lending-market position:

- `CompoundV3Adapter` reads the adapter's Comet balance.
- `AaveV3Adapter` reads the adapter's aToken balance.
- `AaveV4Adapter` reads the adapter's supplied assets from the Aave v4 Spoke.

The supported lending protocols allow assets to be supplied on behalf of another account. A third party can therefore supply underlying asset directly into the market on behalf of the adapter, increasing the adapter's reported strategy balance without interacting with the vault.

Because the CRE epoch workflow reads the current parent epoch nonce and TVL from the active strategy chain's `getTVL()`, then submits both to `ParentVault.closeEpoch(expectedEpochNonce, tvl)`, unsolicited on-behalf-of supplies can be included in the epoch settlement TVL.

### Why this is accepted, not mitigated in adapter accounting

Yieldcoin v2 settles deposits and withdrawals through epochs, not through synchronous mint/redeem operations against live TVL:

- `deposit()` records a pending deposit for the open epoch but does not mint shares immediately.
- `withdraw()` records a pending withdraw intent and escrows shares but does not redeem immediately.
- `closeEpoch(expectedEpochNonce, tvl)` is restricted to the epoch operator path and is executed by the CRE workflow.
- Cross-chain strategy settlement is asynchronous and may require a second workflow step before claims become available.

This architecture prevents the standard single-transaction flash-loan donation attack. An attacker who supplies on behalf of the adapter cannot withdraw those supplied funds back from the lending market; control of the credited position belongs to the adapter. The attacker therefore cannot flash-borrow, inflate TVL, complete a profitable mint/redeem cycle, withdraw the supplied funds, and repay the flash loan in one transaction.

The robust on-chain mitigation would be for each adapter to track protocol position units attributable only to vault-originated deposits and value only those accounted units in `getTVL()`. For example, Aave v3 would track scaled aToken balance and value it through the reserve index, while Compound v3 would track accounted Comet principal/base units and convert them to present value.

That mitigation was deferred because it materially increases adapter accounting complexity and must preserve legitimate organic yield while excluding unsolicited credited balances. Incorrect implementation could introduce more serious yield-accounting or withdrawal bugs than the residual issue accepted here.

### Operational mitigation

The CRE/operator process should monitor active strategy TVL for unexpected jumps before submitting `closeEpoch(expectedEpochNonce, tvl)`, especially changes that cannot be explained by:

- pending epoch net deposits or withdrawals,
- expected strategy yield,
- completed rebalances,
- recovery state, or
- known operator-funded supplies on behalf of the adapter.

Unexpected TVL changes should be investigated before epoch close where operationally feasible.

### Residual risk

A third party can still use real capital to inflate the active adapter's raw protocol balance before CRE samples TVL. This can affect:

- the epoch's implied TVL-to-share ratio,
- shares minted to pending depositors,
- assets allocated to pending withdrawers,
- management-fee accounting,
- rebalances that withdraw the adapter's full raw position, and
- epoch settlement liveness: a donation large enough to push the exchange rate past the point where a same-epoch minimum-size deposit would round to zero shares trips `closeEpoch`'s `ParentVault__DepositWouldMintZeroShares` guard, reverting the entire epoch's settlement rather than just the affected deposit. This is a griefing variant of the same donation mechanism, in the same cost-bounded shape already accepted under [KI-016](#ki-016--parentvault-epoch-and-rebalance-calls-revert-atomically-with-no-stored-recovery-allowing-cost-bounded-settlement-griefing) — recoverable the same way, via `forceCancelDeposit`/`CANCEL_DEPOSIT_OPERATOR_ROLE` clearing the blocking deposit.

An attacker with a pending withdrawal may recover a pro-rata portion of their own unsolicited supply through that epoch's withdrawal settlement. In a zero-net-flow epoch, fresh deposits can fund the withdrawal while the unsolicited strategy position remains as backing, allowing the supply to be recovered in full without privileged access.

With the permanent locked seed position established, this remains an attacker-funded settlement distortion rather than a practical principal-theft path. Without that supply floor, unsolicited TVL can be combined with coarse bootstrap shares and permissionless claim ordering to redirect depositor principal as described in [KI-024](#ki-024--unseeded-bootstrap-allows-adapter-donation-and-claim-ordering-to-redirect-depositor-principal).

### Conditions that would warrant revisiting

- Evidence appears that unsolicited on-behalf-of supplies can be profitably extracted without privileged role compromise.
- CRE TVL monitoring is removed or becomes unable to detect abnormal strategy-balance jumps.
- A new adapter is registered whose `getTVL()` can be inflated and later deflated by the same third party.
- Rebalance behavior changes such that unsolicited strategy balances are routinely swept into canonical accounting.
- Adapter-accounted protocol units become simple enough to implement and test without materially increasing strategy accounting risk.

---

## KI-009 — Management fee base includes shares escrowed for pending withdraw intents

**Status:** Accepted — pending withdraw intents remain economically active until epoch settlement.

**Last reviewed:** 2026-07-08

**Component:** `ParentVaultUserEpochLib.withdraw`, `ParentVaultEpochLib.closeEpoch`, `ParentVaultFeesLib._collectManagementFee`, and rebalance finalization.

### Summary

When a user submits a withdraw intent, `ParentVaultUserEpochLib.withdraw` transfers the user's shares into the `ParentVault` and records the amount in the current epoch's `totalShareBurnAmount`. The shares are held in escrow but are not burned immediately, and `s_totalShares` is not reduced at withdraw submission time.

The authoritative share count is reduced later, when the epoch closes:

`s_totalShares = s_totalShares + newShares - totalShareBurnAmount`

Management fees are collected on rebalance finalization, not during epoch close. If a rebalance finalizes while an epoch is open and that epoch contains pending withdraw intents, `ParentVaultFeesLib._collectManagementFee` computes the fee against `s_totalShares`, which still includes the shares escrowed for those pending withdraws.

### Why this is accepted, not mitigated

A withdraw intent is not treated as an immediate economic exit from the vault. Until the epoch closes:

- the withdrawer can cancel the intent and receive the escrowed shares back;
- the shares have not been burned;
- the withdrawal amount has not been price-locked;
- the user remains exposed to the epoch's eventual settlement ratio; and
- the shares remain part of the vault's authoritative share accounting.

For that reason, management fee collection uses the same `s_totalShares` value that the rest of the vault treats as authoritative before epoch settlement. Excluding pending-withdraw shares from the management-fee base would require either decrementing `s_totalShares` at withdraw submission or tracking a separate pending-withdraw fee exclusion. That would add cancel-withdraw, close-epoch, and claim-path complexity and would create a split between shares that are still economically exposed to settlement and shares counted for management-fee purposes.

The current design keeps share accounting simple: pending withdraw shares leave the fee base only when they are netted out at epoch close.

### Residual risk

If a rebalance finalizes after a withdraw intent is submitted but before that epoch closes, the management fee minted to the treasury includes the pending-withdraw shares in its fee base. This dilutes all shares that remain economically active at that time, including the escrowed shares that will later be burned for the withdraw claim.

The effect is bounded by:

- the management fee rate,
- the elapsed time since the previous rebalance completion, capped at one year per collection, and
- the amount of pending-withdraw shares still unsettled when the rebalance finalizes.

The failure mode is an accepted fee-timing effect of epoch-batched withdrawal settlement, not a solvency issue or direct loss of vault assets.

### Conditions that would warrant revisiting

- Product policy changes to treat withdraw intent submission as immediate economic exit for fee purposes.
- Rebalance cadence changes such that management fee collection commonly occurs while large withdraw intents remain pending.
- Withdraw intents become non-cancellable before epoch close.
- A simpler accounting model is introduced that can exclude pending-withdraw shares from management fees without complicating cancel-withdraw and close-epoch share accounting.

---

## KI-010 — Bootstrap share allocation ignores residual TVL when total shares return to zero

**Status:** Accepted — bounded by snapshot-to-execution drift and mitigated operationally by a permanent locked seed position.

**Last reviewed:** 2026-08-15

**Component:** `ParentVaultEpochLib.closeEpoch`.

### Summary

When `s_totalShares == 0`, `closeEpoch` allocates bootstrap shares from the deposit amount and token precisions, regardless of `tvl`:

```solidity
if (accounting.totalShares == 0) {
    accounting.newShares = ParentVaultMathLib._mulDivDown(
        accounting.totalDepositAmount,
        params.sharePrecision,
        params.assetPrecision
    );
}
```

`s_totalShares` can reach exactly zero through ordinary use: a full-supply exit, where the last holder's withdraw intent burns all outstanding shares in a `closeEpoch`. Nothing prevents this — `minAssetAmount` only floors new mints, not burns.

At the epoch closing a full exit, the withdraw amount pulled from the strategy is the epoch's computed `netWithdrawAmount` (derived from the operator-supplied `tvl` snapshot), not a "withdraw everything" call. If the strategy's actual balance drifts even slightly above that snapshot by execution time (e.g. interest accrued between the CRE workflow's off-chain TVL read and the on-chain `closeEpoch` transaction), a small residual is left behind in the adapter after `s_totalShares` hits zero.

The next epoch's depositor then receives the bootstrap share allocation, which ignores that residual. Their shares end up backed by `residual + their own deposit`, so they receive the residual for free instead of it going to the exited shareholders.

The root cause is bootstrap share allocation ignoring existing TVL when `s_totalShares == 0`, allowing the first depositor after a full reset to capture residual value.

### Why this is accepted, not mitigated

- **Operationally, `s_totalShares` should never return to zero after the first epoch.** The launch procedure transfers the initial seed shares to the immutable `YieldcoinShareSeedLock`, which has no function capable of transferring or withdrawing them. This is operationally established rather than enforced by ParentVault accounting.
- For a local strategy, `WorkflowRouter` caps the TVL observation age at 30 minutes when `closeEpoch` executes, bounding the residual to accrual and rounding drift over that window. For a remote net withdrawal, the later `executeEpochWithdraw` step remains asynchronous, so strategy growth between Parent settlement and Child withdrawal can still widen with the continuation delay described in [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution).
- Reaching the trigger condition requires total share supply to hit exactly zero, which (even setting the seed deposit aside) is a specific and infrequent state (a full protocol exit), not routine operation.
- Sweeping or reconciling the residual would require either tracking a per-reset "owed to exited holders" balance or an extra adapter call on the full-exit path — added accounting state and complexity to close a dust-sized gap, contrary to the project's simplicity priority.
- Once the locked seed is verified, the full-reset trigger is unreachable during ordinary operation. Before that mitigation is established, a low nonzero supply can expose other depositors to the combined issue in [KI-024](#ki-024--unseeded-bootstrap-allows-adapter-donation-and-claim-ordering-to-redirect-depositor-principal).

### Operational mitigation

- Follow the [deployment runbook](../operator/DEPLOYMENT.md#bootstrap-the-parent-vault): deposit at least 100 USDC in epoch one, close it through CRE, claim the resulting shares, and transfer them to the deployed `YieldcoinShareSeedLock` before launch.

### Residual risk

If the locked seed is not established, a full-supply reset can still transfer residual strategy value to the next depositor. For a local strategy, that residual is bounded by yield accrual and rounding over the report's maximum 30-minute observation window; a remote withdrawal can accrue additional drift while Child execution is delayed per [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution). More importantly, low nonzero supply before the lock is established enables the principal-redirection sequence in [KI-024](#ki-024--unseeded-bootstrap-allows-adapter-donation-and-claim-ordering-to-redirect-depositor-principal).

### Conditions that would warrant revisiting

- The seed shares are not transferred to the lock, or the deployed lock differs from the immutable blank contract documented in the runbook.
- CRE settlement delay (per [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution)) or an adapter/strategy topology change widens the gap between the operator's TVL snapshot and actual on-chain execution beyond dust-sized.
- Full-supply resets become a routine/expected operational pattern rather than an edge case.
- A cheap way to reconcile or sweep residual TVL at the zero-shares boundary becomes available without adding meaningful accounting complexity.
- The seed-deposit practice is formalized as a contract-enforced invariant (e.g. a permanent minimum-liquidity lock), at which point this entry could be closed rather than merely mitigated.

---

## KI-011 — Compromised DefiLlama API or relay can skew rebalance inputs

**Status:** Accepted — bounded off-chain data-integrity dependency.

**Last reviewed:** 2026-07-11

**Component:** DefiLlama API, `services/defillama-relay`, CRE rebalance workflow, `WorkflowRouter.onReport`, `AdapterRegistry`, and rebalance execution paths.

### Summary

Yieldcoin v2 uses off-chain DefiLlama pool data, fetched through the `defillama-relay`, to inform rebalance decisions. The relay is a read-only data service: it fetches upstream yield data, filters it to configured pool IDs, bounds returned metadata, and serves the result to the CRE workflow.

If the DefiLlama API, relay deployment, relay configuration, or TLS-terminating path is compromised, the CRE workflow can receive plausible but incorrect APY / yield data for otherwise allowed pools. That can cause the workflow to select a suboptimal supported strategy or to rebalance when it otherwise would not have.

This is distinct from [KI-004](#ki-004--residual-cpumemory-dos-surface-in-defillama-relay-upstream-processing), which covers CPU/memory resource exhaustion while parsing upstream responses.

### Mitigations already in place

- The relay does not hold funds, sign transactions, or write on-chain state.
- The relay filters responses to configured pool IDs; arbitrary upstream pool IDs are discarded.
- CRE reports still enter on-chain state only through `WorkflowRouter.onReport`.
- `WorkflowRouter` validates workflow metadata, the signed destination, report freshness, and allowlisted selectors before dispatching.
- Rebalance execution is constrained to supported protocols, registered adapters, and registered destination chains.

### Residual risk

A compromised or misconfigured data source can still influence strategy selection within the configured rebalance universe. The primary impact is economic underperformance or unnecessary rebalance activity, not direct theft:

- Capital may be moved to a lower-yield strategy than the true best option.
- A rebalance may execute based on overstated APY improvement.
- Expected yield may be reduced until operators detect the bad feed or correct the relay configuration.

The relay cannot by itself transfer funds, register adapters, add supported protocols, grant roles, or call vault functions. Any on-chain action still requires a valid CRE report and the existing on-chain allowlists and registry checks.

### Why this is accepted, not mitigated on-chain

The protocol intentionally treats rebalance choice as an off-chain optimization problem. On-chain contracts cannot cheaply verify third-party APY data across chains and lending protocols. Adding multiple oracle sources, quorum rules, or on-chain yield proofs would add substantial complexity while still leaving operational judgement in the rebalance process.

The current design keeps the data feed read-only and constrains the executable action space on-chain. The team accepts the residual as an operational data-integrity assumption for automated rebalancing.

### Operational mitigations

- Monitor relay responses and rebalance decisions for unexpected APY jumps, missing pools, or sudden strategy changes.
- Keep allowed pool IDs, supported protocols, adapter registrations, and destination chains under deployment/runbook review.
- Alert on relay configuration changes, `DEFILLAMA_UPSTREAM_URL` changes, and repeated divergence from independent market/yield observations.
- Pause rebalance execution or update relay/workflow configuration if the data source is suspected to be compromised.

### Conditions that would warrant revisiting

- The relay output begins driving broader on-chain actions beyond bounded rebalance selection.
- Product requirements change to require independently verified yield data.
- A practical multi-source or cryptographically verifiable yield-data source becomes available.
- Operators remove monitoring or manual review around rebalance decisions.

---

## KI-012 — DON node operators can observe the DefiLlama relay bearer token in plaintext

**Status:** Accepted — standard non-Confidential CRE HTTP cannot hide request auth material from the DON nodes executing the HTTP callback; impact is accepted because the token only gates read-only relay access to public-derived data.

**Last reviewed:** 2026-07-17

**Component:** `cre/workflow/internal/offchain/defillama.go` (`FetchAndSelectPools`, `fetchAndParse`), CRE `networking/http` capability.

### Summary

`FetchAndSelectPools` resolves `DEFILLAMA_RELAY_BEARER_TOKEN` via `runtime.GetSecret()`, places it in `fetchParams.BearerToken`, and passes that into `crehttp.SendRequest` (`defillama.go:96,104,111`). `crehttp.SendRequest` wraps `cre.RunInNodeMode`, so the callback that builds the `Authorization: Bearer <token>` header (`defillama.go:144`) executes in node mode — independently, on every DON node.

The exposure mechanism, traced against `cre-sdk-go v1.11.0`:

- `fetchParams` itself is **not** serialized to reach the node-mode callback — `cre.RunInNodeMode`'s generic wrapper invokes it as a direct, synchronous, in-process Go closure call (`internal/sdkimpl/runtime.go:178`, `observation := fn(nrt)`).
- The actual host-boundary crossing happens one layer deeper: once the callback builds the `*crehttp.Request` (headers included), `Client.SendRequest` protobuf-marshals it (`anypb.MarshalFrom`) and passes it to `runtime.CallCapability(...)` (`capabilities/networking/http@v1.3.0/client_sdk_gen.go:44-51`). That is where the token leaves the WASM sandbox and reaches the node's local host-side `http-actions` capability implementation, in cleartext, so the outbound HTTP call can actually be made.
- This happens once per DON node, independently — each node resolves its own copy of the secret via its own `GetSecret()` call and crosses its own host boundary with it. There is no peer-to-peer transmission of the secret between nodes.

Separately, per the CRE architecture ("Each node in the DON executes the workflow independently"; "DON Mode (Default): Code runs on all nodes simultaneously"), the earlier `runtime.GetSecret()` call — made in DON mode, before `SendRequest` — already executes identically on every node. So no DON node is being handed a secret it wouldn't otherwise have resolved itself.

### Why this is accepted, not mitigated

- `cre-sdk-go`'s own test suite (`standard_tests/secrets_fail_in_node_mode`) confirms `runtime.GetSecret()` is hard-disallowed _inside_ a node-mode callback (`NodeRuntime` does not implement `SecretsProvider`; calling it sets `modeErr = DonModeCallInNodeMode()`). Resolving the secret in DON mode and passing it into node-mode params is the straightforward SDK-supported pattern for attaching a secret-derived auth header to a node-executed HTTP request — but it is not the _only_ possible design. Alternatives not adopted include an unauthenticated relay, a static non-secret shared value, or Chainlink's **Confidential HTTP** capability (Vault DON secrets resolved via `{{.SECRET_NAME}}` templating inside an enclave, which never places the plaintext value in node WASM/host memory). The bearer-token design was a deliberate choice, not a forced default — this entry accepts that choice's consequence rather than treating it as unavoidable.
- The token's blast radius is narrow: it only gates read access to `services/defillama-relay`, a read-only proxy in front of DefiLlama's public pools API (see [KI-011](#ki-011--compromised-defillama-api-or-relay-can-skew-rebalance-inputs)). The relay holds no funds, signs no transactions, and writes no on-chain state. Worst case, a node operator who extracts the token calls the relay directly instead of through the workflow.
- DON node operators already hold substantially greater trust in this system: they execute the APY comparison logic and produce the consensus report that drives `ParentVault.initiateRebalance(expectedRebalanceNonce, newStrategy)`. A node operator misusing this token is a strictly smaller concern than that operator's existing role in the rebalance decision path.
- Adopting Confidential HTTP purely to hide this token would add Vault DON provisioning and enclave-based request construction — complexity disproportionate to a token whose worst-case misuse is querying a public-data proxy.

### Residual risk

A DON node operator (or anyone able to read that node's process memory during workflow execution) can extract the bearer token and call `services/defillama-relay` directly, outside the workflow. Given the relay is read-only and non-privileged, this does not create fund risk, write access, or a path to influence on-chain state beyond what a compromised node operator can already do through the workflow itself.

### Conditions that would warrant revisiting

- The relay or the token gains write authority, rate-limit-bypass value, or access to non-public data.
- CRE's Confidential HTTP path becomes cheap enough (in provisioning/operational terms) to justify closing this residual for a low-sensitivity token.
- The trust model changes such that DON node operators are less trusted than the current design assumes (e.g., a permissionless/open node set).

---

## KI-013 — A paused parent or child vault can leave a cross-chain epoch or rebalance in progress

**Status:** Accepted — intentional pause containment with an operator break-glass procedure.

**Last reviewed:** 2026-08-13

**Component:** `ParentVault.completeEpochDeposit`, `ParentVault.completeRebalance`, `ChildVault.executeEpochWithdraw`, `ChildVault.executeRebalance`, CRE epoch and rebalance workflows, and `WorkflowRouter`.

### Summary

For a remote-strategy net-withdraw epoch, `ParentVault.closeEpoch` records the epoch as `EXECUTING` and emits `EpochWithdrawExecuting`. For a rebalance whose active strategy is on a child chain, `ParentVault.initiateRebalance` records the rebalance as `REBALANCING` and emits `RebalanceInitiated`. CRE observes the relevant event and submits the corresponding child-chain call through `WorkflowRouter`.

If the affected `ChildVault` is paused before CRE calls `executeEpochWithdraw` or `executeRebalance`, the call reverts at `whenNotPaused`. The pause check occurs before the child attempts the strategy operation, sends a CCIP message, or stores typed recovery state. The parent has already entered its intermediate state, so it cannot advance until the child operation is deliberately resumed.

Likewise, if ParentVault is paused after a destination ChildVault successfully deposits a remote net epoch amount or rebalance amount but before CRE submits the corresponding completion report, `completeEpochDeposit` or `completeRebalance` reverts at `whenNotPaused`. ParentVault deliberately does not treat CRE's observation as sufficient to bypass incident containment. The epoch remains `EXECUTING` or the rebalance remains `REBALANCING` until operators reconcile the destination result and deliberately unpause ParentVault for finalization.

Repeated CRE execution cannot resolve the condition while the affected parent or child vault remains paused. In particular:

- The parent epoch remains `EXECUTING`, so its withdraw claims cannot become claimable and the previous-epoch guard prevents a later epoch from closing.
- The parent rebalance remains `REBALANCING`, so another rebalance cannot begin and epoch close is blocked.
- The child has no recovery state for a child execution reverted by its pause guard, and ParentVault records no new recovery for a completion reverted by its own pause guard.

### Why this is accepted, not mitigated on-chain

Pause is an incident-containment boundary. While paused, a vault must not call strategy adapters, send CCIP messages, process inbound CCIP messages, execute recovery, or accept CRE-authorized lifecycle finalization. ParentVault cannot independently prove the remote success that CRE reports, and completion makes economically meaningful accounting transitions. Allowing child execution or parent completion to bypass the pause guard would undermine that boundary precisely when operators are attempting to contain an incident.

ParentVault cannot safely infer or reconcile destination execution on-chain. It cannot know whether a child transaction succeeded or whether a CCIP message is already in flight without introducing additional cross-chain coordination and state. Automatically rolling back parent state is also unsafe because a delayed or manually executed child action may still occur.

The design therefore favors explicit containment and operator reconciliation over automatic liveness while a parent or child vault is paused. This is consistent with [DD-004](../protocol/DECISIONS.md#dd-004---pause-contains-external-execution-and-lifecycle-finalization).

### Operational mitigation

- Monitor failed CRE reports and `WorkflowRouter` calls for pause-related reverts after `EpochWithdrawExecuting`, `RebalanceInitiated`, `EpochDepositToStrategySuccess`, or `RebalanceDepositSuccess` events.
- Alert when a parent epoch remains `EXECUTING` or a rebalance remains `REBALANCING` beyond its expected completion window.
- Before retrying, reconcile the parent state, child state, recovery mode, transaction history, and CCIP message status so a source-chain action is not executed twice.
- Follow the [Paused Cross-Chain Execution](../operator/OPERATIONS.md#paused-cross-chain-execution) playbook. Keep the normal router paused or unauthorized, temporarily unpause only the affected vault, execute the exact event- or parent-state-derived calldata through an approved break-glass operator, and revoke temporary authority after reconciliation.

### Residual risk

An affected epoch or rebalance can remain in progress indefinitely while the parent or child remains paused or if operators do not complete the break-glass procedure. During that interval, epoch settlement and new rebalances are unavailable, and the previous-epoch guard may also prevent subsequent epoch closes.

The failure mode is availability and operational delay. The pause-triggered revert occurs before strategy or CCIP side effects and does not itself corrupt accounting or cause a direct loss of funds. Operational error during manual reconciliation remains part of the privileged-operator trust assumption documented in [KI-001](#ki-001--centralized-trust-in-privileged-operatoradmin-roles).

For the epoch-`EXECUTING` case specifically, depositors and withdrawers whose intent belongs to the affected, already-closed epoch have no cancellation path during the stall — see [KI-017](#ki-017--deposit-and-withdraw-cancellation-is-scoped-to-the-current-epoch-only). This does not apply to the `REBALANCING` case above: while a rebalance is stuck, `closeEpoch` cannot run at all, so the _current_ epoch remains `OPEN` and its own depositors/withdrawers retain normal cancellation.

### Conditions that would warrant revisiting

- Product requirements no longer permit an in-progress epoch or rebalance to wait for operator intervention during a parent- or child-vault pause.
- A safe on-chain acknowledgement or cancellation protocol is added between parent and child vaults.
- Pause semantics change to permit narrowly scoped continuation of operations that began before the pause.
- CRE or operator monitoring can no longer reliably detect and reconcile paused cross-chain execution.

---

## KI-014 — Strategy-withdraw recovery requires full market liquidity

**Status:** Accepted — recovery deliberately retries the original strategy withdrawal atomically.

**Last reviewed:** 2026-08-01

**Component:** `ChildVault.executeEpochWithdraw`, `ChildVault.executeRebalance`, `ChildVault.executeRecovery`, epoch- and rebalance-withdraw recovery state, strategy adapters, and the CRE global recovery guard.

### Summary

When a ChildVault cannot withdraw the requested assets from its active strategy, it stores typed recovery state and leaves the operation in progress. Recovery retries the original withdrawal rather than accepting incremental liquidity:

- `EPOCH_WITHDRAW` retries the full stored epoch withdrawal amount.
- `REBALANCE_WITHDRAW` retries withdrawal of the entire strategy position with `type(uint256).max`.

If the lending market cannot provide the full requested liquidity in one transaction, `executeRecovery()` continues to revert until sufficient liquidity returns. There is no path to withdraw a partial amount, reduce a stored remainder, or settle either operation through multiple withdrawals and CCIP messages.

### Impact

This is an availability limitation rather than an accounting or custody failure:

- An affected epoch remains `EXECUTING`, so its claims cannot become available and the previous-epoch guard prevents a later epoch from closing.
- An affected rebalance remains `REBALANCING`, so another rebalance cannot begin and epoch close remains blocked.
- The ChildVault remains in `EPOCH_WITHDRAW` or `REBALANCE_WITHDRAW` recovery mode.
- The normal CRE path detects the outstanding recovery and skips new fund-moving or state-creating operations across the configured deployment.
- Repeated recovery attempts cannot make incremental progress when only part of the requested liquidity is available.
- Depositors and withdrawers whose intent belongs to the affected, already-`EXECUTING` epoch (the `EPOCH_WITHDRAW` recovery case) have no cancellation path during the stall — see [KI-017](#ki-017--deposit-and-withdraw-cancellation-is-scoped-to-the-current-epoch-only). This does not apply to the `REBALANCE_WITHDRAW` recovery case: the current epoch cannot close while the rebalance is stuck, so it remains `OPEN` and its own depositors/withdrawers retain normal cancellation.

Assets that could not be withdrawn remain accounted for in the existing strategy position. The recovery does not create an unbacked claim, discard the requested amount, or clear the active adapter. The operational delay can nevertheless be indefinite if the market never again makes the full withdrawal available in one transaction.

### Why this is accepted, not mitigated on-chain

Recovery modes are intentionally exact continuations of previously accepted operations. Retrying the original amount or full position keeps recovery state deterministic and makes the resulting strategy and CCIP transitions straightforward to reconcile.

Partial recovery would require a substantially larger state machine: cumulative withdrawal accounting, stored remaining amounts, potentially repeated CCIP transfers, partial rebalance migration, epoch shortfall treatment across multiple receipts, and an explicit finalization condition. The protocol accepts waiting for full strategy liquidity rather than adding that complexity.

### Operational mitigations

- Monitor `EPOCH_WITHDRAW` and `REBALANCE_WITHDRAW` recovery mode, including the affected nonce, position size, and recovery age.
- Monitor lending-market liquidity and retry `executeRecovery()` only when the full requested withdrawal is expected to succeed.
- Track the affected ParentVault epoch or rebalance until it reaches `CLAIMABLE` or completes, including any subsequent CCIP message.
- Escalate prolonged market illiquidity through the incident and upgrade process rather than manually altering recovery state or repeating the original source operation.

### Conditions that would warrant revisiting

- Full-liquidity recovery delays become frequent or exceed the protocol's accepted settlement window.
- A supported lending market introduces persistent withdrawal queues or routinely exposes only partial liquidity.
- Product requirements demand bounded epoch or rebalance completion time.
- The protocol adopts a formally specified partial-withdrawal and multi-message settlement design.

---

## KI-015 — Operator-controlled cross-chain configuration remains mutable during in-flight operations

**Status:** Accepted — trusted configuration authority with operational safeguards.

**Last reviewed:** 2026-08-14

**Component:** `BaseVault.setCrosschainVaults`, `AdapterRegistry.setAdapter`, cross-chain epoch and rebalance execution, and ChildVault recovery.

### Summary

`CONFIG_OPERATOR_ROLE` can change trusted cross-chain vault routes and protocol adapter mappings. The contracts do not prevent this configuration from changing while an epoch, rebalance, CCIP message, or stored recovery depends on it.

Changing a required route mid-flight can interrupt the affected operation:

- An inbound message from the previously configured vault can fail source-vault validation.
- A new send or stored `CCIP_SEND` recovery can fail if its destination route was removed.
- A retry can use a replacement destination address rather than the address configured when recovery was stored.
- Destination execution can fail or use a replacement adapter if its protocol mapping changes before activation.
- A ChildVault can remain in its vault-wide recovery mode, blocking normal epoch, rebalance, and inbound CCIP processing until the route is corrected and recovery succeeds.

Recovery state is not lost when a retry reverts: EVM atomicity restores the stored recovery data and recovery mode. A trusted operator can normally restore the required mapping and retry. The primary risk is cross-chain liveness and operational misrouting, not an automatic loss of accounting state or funds.

### Worst-case impact: irrecoverable fund redirection, not just liveness

The failure modes above assume the replacement address is _wrong_ (stale, unreachable, or misconfigured) — the message or deposit fails, and EVM atomicity or stored recovery lets an operator correct the route and retry. The worst case is stronger: if `CONFIG_OPERATOR_ROLE` sets `s_crosschainVaults[chainSelector]` or registers an `AdapterRegistry` entry to an address that is _live and responsive_ but not a genuine Yieldcoin v2 counterpart (e.g. attacker-deployed), the next bridge or rebalance into that route does not fail — it succeeds, delivering the full transferred principal or rebalanced TVL to that address. `BaseVaultStrategyLib._setActiveAdapter`'s only check (`adapter.getVault() == vault`) is trivially satisfiable by a purpose-built malicious contract; `_setCrosschainVaults` performs no address validation at all. This is not a liveness incident with a recovery path — it is direct, permanent loss of the affected epoch's principal or the vault's active-strategy TVL.

This is accepted under the same operator-trust boundary as the rest of this entry (see "Why this is accepted" below), not because the impact is bounded to liveness.

### Why this is accepted

Cross-chain configuration must remain mutable so operators can deploy or rotate routes and adapters and respond to broken or compromised components. A universal on-chain lock could prevent an emergency correction when it is most needed.

The system therefore treats route continuity as a trusted operator responsibility. This assumption is also recorded in [ENV-006](./INVARIANTS.md#external-assumptions).

### Operational requirements

- Before changing a route or adapter mapping, reconcile active and previous epochs, rebalance state, every vault's recovery mode, and relevant CCIP messages.
- Preserve the old route while any accepted message, settlement, or recovery still depends on it unless an incident procedure explicitly requires replacement.
- Stop the relevant CRE automation before an emergency route change so it cannot submit new work against a partially updated deployment.
- Apply coordinated configuration changes across the affected chains and verify both send-side destination and receive-side source authentication.
- After restoring or replacing a route, retry stored recovery and monitor the parent epoch or rebalance through final completion.
- Route and adapter-mapping changes require each signer to independently verify off-chain that the destination address is source-verified Yieldcoin v2 deployment code, not merely a nonzero address responding correctly to `getVault()` — this manual verification is the sole control against the worst-case fund-redirection impact above, since no on-chain validation or timelock exists for either setter.

See [CONFIG - Vault Configuration](../operator/CONFIG.md#vault-configuration) and [OPERATIONS - Paused Cross-Chain Execution](../operator/OPERATIONS.md#paused-cross-chain-execution).

### Residual risk

An incorrect or incomplete route change can leave an epoch or rebalance in progress indefinitely and can block unrelated ChildVault operations through the vault-wide recovery singleton. Restoring the prior configuration normally recovers liveness, but an address rotation performed after messages have already been emitted may require careful reconciliation or a purpose-built upgrade if the original counterparty cannot safely be restored.

### Conditions that would warrant revisiting

- Cross-chain route changes become frequent routine operations rather than exceptional configuration changes.
- Operational monitoring cannot reliably identify messages and recoveries that still depend on an existing route.
- A route-versioning or two-phase rotation design is introduced that can preserve old counterparties for outstanding messages.
- CCIP exposes an on-chain mechanism that lets the vault reliably enumerate or prove all messages still in flight for a route.
- A cheap, on-chain two-step commit (propose → delay → activate) for `setCrosschainVaults`/`setAdapter` becomes worth the added complexity, at which point the worst-case fund-redirection impact above would move from "operator-verification-only" to independently inspectable before it can take effect.

---

## KI-016 — ParentVault epoch and rebalance calls revert atomically with no stored recovery, allowing cost-bounded settlement griefing

**Status:** Accepted — atomic revert is the deliberate design for parent-chain-only failures; no cross-chain or partially-executed state exists to recover.

**Last reviewed:** 2026-08-31

**Component:** `ParentVault.closeEpoch` (`DEPOSIT_TO_LOCAL_STRATEGY` / `WITHDRAW_FROM_LOCAL_STRATEGY` / `SEND_DEPOSIT_TO_REMOTE_STRATEGY` branches), `ParentVault.initiateRebalance` (local-to-local, local-withdraw, and `WITHDRAW_LOCAL_TO_REMOTE` branches), `BaseVault._executeDeposit` / `_executeWithdraw` (`revertOnFailure == true` path), `BaseVault._ccipSend` (Parent's direct, non-try/catch call, as opposed to `ChildVault`'s overridden version), and whichever strategy adapter is locally active on the parent chain.

### Summary

When ParentVault's active strategy is local to the parent chain, `closeEpoch` and `initiateRebalance` call the active adapter's `deposit()`/`withdraw()` with `revertOnFailure = true`. If the adapter call fails — for example the underlying Aave/Compound reserve cannot supply the requested withdrawal liquidity, or a deposit cannot be credited because a supply cap is reached — `BaseVault` reverts the whole transaction (`BaseVault__DepositFailed` / `BaseVault__WithdrawFailed`) instead of catching the failure and storing typed recovery state the way every equivalent `ChildVault` call site does (`REBALANCE_WITHDRAW`, `REBALANCE_DEPOSIT`, `EPOCH_DEPOSIT`, `EPOCH_WITHDRAW`, `CCIP_SEND`).

The same shape applies to Parent's _outbound_ CCIP sends. `closeEpoch`'s `SEND_DEPOSIT_TO_REMOTE_STRATEGY` branch and `initiateRebalance`'s `WITHDRAW_LOCAL_TO_REMOTE` branch call `BaseVault._ccipSend` directly, with no try/catch — unlike `ChildVault`, which overrides `_ccipSend` to catch most failed sends and store `CCIP_SEND` recovery. Child selectively rethrows `TokenMaxCapacityExceeded`, for which replaying the same amount cannot make progress. A failed fee calculation, token approval, or other router call (e.g. an underfunded LINK balance) reverts the whole Parent `closeEpoch`/`initiateRebalance` transaction the same way a failed local adapter call does.

This is intentional in both cases, not an oversight: per `docs/concepts/RECOVERY.md`, "other parent-chain failures generally revert atomically. In those cases, no cross-chain state has escaped and the transaction can leave clean state without storing recovery," and `INVARIANTS.md` `REC-009` documents and Foundry/Medusa-tests this exact behavior — Parent's synchronous local strategy calls use `revertOnFailure == true` so a caught adapter failure is rethrown and the transaction reverts, creating no recovery state. The CCIP-send branches carry the identical rationale: the epoch/rebalance state transition and the outbound send happen in the same transaction, so if the send fails, nothing has yet been committed that another chain is depending on or expecting a follow-up for — the whole transaction, including the epoch/rebalance state writes, rolls back together.

Because the revert is atomic, nothing partially executed: the epoch remains `OPEN` (or the rebalance never leaves `NONE`), and the next attempt — the following CRE cron cycle calling `closeEpoch`/`initiateRebalance` again — is a complete, ordinary retry, not a specialized recovery path. This is architecturally different from `ChildVault`, where a caught failure follows funds that have already left the source chain, already landed as an incoming CCIP transfer, or where Parent has _already_, in a prior and separately-committed transaction, closed an epoch or initiated a rebalance that now expects Child to follow up — Parent cannot "undo" that already-finalized prior transaction, so Child must retry until it succeeds rather than revert and forget.

### Residual risk

While no state is lost and no funds are misplaced, an actor can hold the local reserve in a condition that reliably fails the adapter call — for example borrowing against posted collateral to drive the reserve's utilization high enough that `withdraw()` cannot return the requested liquidity, or supplying directly to a capped reserve so `deposit()` cannot be credited. This capital is fully recoverable by the actor (cost is only borrow interest / opportunity cost), and sustaining the condition causes every `closeEpoch` and `initiateRebalance` attempt against the local strategy to revert for as long as it is maintained:

- `closeEpoch` cannot settle the current epoch, so its depositors and withdrawers cannot claim (though they retain the ability to cancel their own current-epoch intent while it remains `OPEN`, the same escape hatch `KI-007` already documents).
- `initiateRebalance`'s local-to-local and local-withdraw paths hit the same adapter and fail identically, so the protocol cannot rebalance away from the affected strategy either.

The CCIP-send branches carry the same settlement-blocking shape. When the active strategy is remote, any positive net deposit causes ParentVault to send a CCIP message and pay the fee from its LINK balance. A permissionless user can therefore deposit the one-asset minimum in successive epochs, retain the resulting shares, and repeatedly consume a full Parent CCIP fee. Once ParentVault lacks enough LINK, `closeEpoch` reverts atomically and the epoch remains open until LINK is supplied or its deposits are cancelled.

The failure mode is availability and settlement delay, not loss of funds or accounting corruption — consistent with the general shape already accepted in `KI-007` (CRE liveness dependency) and `KI-014` (child-side recovery requires full market liquidity), but this specific parent-side, cost-bounded griefing mechanic was not previously named by either entry.

### Why this is accepted, not mitigated on-chain

Building a local recovery mode symmetric with `ChildVault`'s would mean storing and replaying state for a case where nothing needs replaying — the transaction already reverted cleanly with no committed side effects. Doing so would add a parallel state machine and reconciliation surface to `ParentVault`'s synchronous settlement path for no correctness benefit over simply retrying the same call once market conditions allow it, contrary to the project's simplicity priority. The atomic-revert design keeps parent state provably clean at every boundary, which the existing `REC-009`/`SOLV-*` invariant suite already relies on. This applies identically to the CCIP-send branches: they resolve within the same synchronous transaction as the local-adapter branches, so the same "nothing to replay" reasoning covers both.

### Operational mitigations

- Monitor for repeated `closeEpoch`/`initiateRebalance` reverts against the local active adapter (distinguishable from other revert reasons via the `BaseVault__DepositFailed`/`BaseVault__WithdrawFailed` selectors).
- Monitor local active-reserve utilization and available supply-cap headroom ahead of each scheduled epoch close or rebalance attempt, alongside the existing `KI-007` monitoring for epochs that fail to advance past their expected close window.
- Monitor `ParentVault`'s LINK balance and CCIP fee levels ahead of each scheduled epoch close or rebalance attempt targeting a remote strategy, so a `closeEpoch`/`initiateRebalance` revert on the CCIP-send branches is distinguishable from local-adapter griefing and resolved by top-up rather than mistaken for a market-liquidity issue.
- Monitor repeated minimum-sized remote net deposits and the ratio between deposited value and the CCIP fee paid by ParentVault.
- If sustained griefing is detected, operators can rebalance away from the affected local strategy once liquidity briefly recovers, or pause the vault while coordinating a response, consistent with the operator trust model in `KI-001`.

### Conditions that would warrant revisiting

- Local (parent-chain) active strategies become materially more common than remote ones, raising the practical exposure to this griefing pattern.
- Monitoring cannot reliably distinguish this condition from ordinary market illiquidity in time to respond operationally.
- A low-cost, symmetry-preserving way to add local recovery (without duplicating `ChildVault`'s state machine) becomes available.
- Supported lending markets are observed to have utilization or supply-cap dynamics that make sustained griefing meaningfully cheaper than assumed here.
- Parent-side CCIP fees become material relative to the minimum deposit, making repeated minimum-sized remote deposits economical as a fee-drain strategy.

---

## KI-017 — Deposit and withdraw cancellation is scoped to the current epoch only

**Status:** Accepted — cancellation is intentionally limited to the still-open, not-yet-settled epoch.

**Last reviewed:** 2026-08-08

**Component:** `ParentVaultUserEpochLib._cancelDepositCore` (shared by `cancelDeposit` and `forceCancelDeposit`), `ParentVaultUserEpochLib._cancelWithdraw`, and `ParentVault.cancelDeposit` / `cancelWithdraw`.

### Summary

`_cancelDepositCore` and `_cancelWithdraw` both derive the epoch to act on from `$.s_epochNonce` — the _current_ epoch — and then require that epoch's status to be `OPEN`. Neither function takes an epoch nonce as a parameter, so cancellation can only ever reach whichever epoch is presently open. Once an epoch's own settlement moves it past `OPEN` (to `EXECUTING`, or directly to `CLAIMABLE`) and `closeEpoch` opens the next epoch, an intent recorded under the now-settled epoch is permanently outside the reach of these two functions. The position is not lost — it remains claimable once (and if) that epoch itself reaches `CLAIMABLE` — but it cannot be cancelled early.

Under normal, healthy operation this has no visible effect: an epoch reaches `CLAIMABLE` promptly and its participants proceed straight to `claimShares`/`claimAsset`. The consequence only becomes material when an epoch's settlement stalls indefinitely for a reason documented elsewhere:

- [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution) — a remote net-deposit or net-withdraw epoch waiting on a second CRE step.
- [KI-013](#ki-013--a-paused-parent-or-child-vault-can-leave-a-cross-chain-epoch-or-rebalance-in-progress) — a cross-chain epoch stuck `EXECUTING` because parent completion or child execution is blocked by pause.
- [KI-014](#ki-014--strategy-withdraw-recovery-requires-full-market-liquidity) — a remote net-withdraw epoch stuck `EXECUTING` because the strategy cannot supply the full requested liquidity (`EPOCH_WITHDRAW` recovery).

In each of these cases, depositors and withdrawers whose intent belongs to the affected epoch have no self-service path to their funds during the stall: not cancellation (their epoch is no longer `OPEN`) and not claiming (their epoch is not yet `CLAIMABLE`). Funds are fully inaccessible, not merely delayed, for the duration of the underlying stall.

This does **not** apply when a _rebalance_ alone is stuck (`REBALANCING`, or the `REBALANCE_WITHDRAW` recovery case in KI-014): `closeEpoch` cannot run at all while a rebalance is in progress, so the current epoch remains `OPEN` and its own depositors/withdrawers retain normal cancellation. The gap described here is specific to an epoch that has itself already left `OPEN`.

### Why this is accepted, not mitigated

Cancellation exists to let a user exit an intent before it has been priced or folded into shared settlement math. Once `closeEpoch` runs, a deposit or withdraw amount is no longer just that user's individual escrow — it becomes part of a shrinking-pool settlement structure shared with every other participant in that epoch (`remainingDepositClaimAmount`/`remainingShareMintAmount` on the deposit side, `remainingShareBurnAmount`/`remainingWithdrawClaimAmount` on the withdraw side). Supporting cancellation past that point would mean unwinding one participant's contribution out of an already-computed shared pool, which risks breaking the shrinking-pool invariants (`EPOCH-008`, `EPOCH-011`) that are otherwise Foundry/Medusa-verified. Scoping cancellation to the pre-settlement, still-`OPEN` window avoids that complexity entirely.

The stalls that make this material (`KI-007`, `KI-013`, `KI-014`) are already accepted operational-liveness risks with their own monitoring and break-glass procedures. This entry's purpose is to make explicit that "no cancellation" is a strict, additional consequence whenever one of those stalls occurs, so operator response expectations are sized around "funds are fully locked until the stall resolves," not merely "settlement is delayed."

### Operational mitigations

- Treat any alert already raised under `KI-007`/`KI-013`/`KI-014` for an epoch stuck past its expected `EXECUTING` window as equivalent to "affected users have zero self-service exit," not just "settlement delayed," when sizing escalation urgency.
- No additional monitoring beyond what `KI-007`/`KI-013`/`KI-014` already specify is needed to detect this condition — it is a direct consequence of the same stuck-epoch state those entries already watch for.

### Conditions that would warrant revisiting

- Product requirements demand a self-service exit for users caught in a stalled epoch, rather than relying on the stall itself resolving.
- A scoped-cancellation design becomes available that can unwind a single participant's contribution from an epoch's shared settlement pool without breaking the shrinking-pool invariants (`EPOCH-008`, `EPOCH-011`).
- Stalls covered by `KI-007`, `KI-013`, or `KI-014` become frequent enough that "no cancellation while stuck" materially affects user experience rather than remaining a rare tail event.

---

## KI-018 — Management fee is billed against a point-in-time share snapshot, not time-weighted per holder

**Status:** Accepted — inherent to a periodic AUM-style fee with no per-holder accrual ledger.

**Last reviewed:** 2026-08-08

**Component:** `ParentVaultFeesLib._collectManagementFee`, invoked from `ParentVaultRebalanceLib._finalizeRebalance`.

### Summary

`_collectManagementFee` computes the fee as `s_totalShares` (read at collection time) × `MANAGEMENT_FEE_BPS` × elapsed time since the previous rebalance completed, capped at 365 days, and mints the resulting shares to the treasury from whichever shares happen to be outstanding at that moment. There is no per-holder join timestamp anywhere in share accounting, so the fee cannot distinguish a holder present for the full elapsed window from one who joined the day before, and it entirely misses anyone who fully exited earlier in that window.

This is the general form of two already-documented symptoms of the same design: [KI-006](#ki-006--management-fee-accumulator-includes-vault-pause-duration) (pause duration counted in the elapsed-time base) and [KI-009](#ki-009--management-fee-base-includes-shares-escrowed-for-pending-withdraw-intents) (pending-withdraw shares counted in the totalShares base). Both describe _what_ gets included in a single fee calculation; this entry describes the underlying reason a single calculation can misattribute the fee across holders at all.

### Why this is accepted, not mitigated

Per [DD-010](../protocol/DECISIONS.md#dd-010---management-fee-accrual-is-gated-on-rebalance-finalization), management fee is deliberately modeled as a coarse, rebalance-gated AUM charge rather than a continuously-accruing per-holder fee, to keep share accounting simple. Attributing fee liability to each holder's actual entry/exit window would require tracking a per-user accrual checkpoint (or moving to a share-index/rebase model) — additional state written on every deposit, withdraw, cancel, and claim, purely to serve this one fee calculation. That cost is judged disproportionate to the fee's purpose: it would meaningfully complicate the core deposit/withdraw/claim paths to fix a redistribution effect that is bounded, non-adversarial (no party profits by causing it — it's a byproduct of ordinary timing), and doesn't threaten solvency.

### Residual risk

- With rebalances expected roughly daily, each fee collection's elapsed window is typically ~1 day, so any single misattribution (a holder billed for time they didn't hold, or a holder escaping the fee entirely) is naturally bounded to about a day's worth of fee — small in absolute terms under normal operation.
- The effect only grows if actual rebalance cadence drifts materially longer than the daily target — e.g. during an extended period with no sufficiently large APY differential to trigger a rebalance, or during a CRE/liveness stall (see [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution)). In those windows the same mechanism applies at whatever elapsed duration has actually accumulated.
- Net effect: passive, long-term holders who happen to be present at finalization subsidize short-term holders who aren't, in proportion to how long the actual gap since the last rebalance was — bounded by design under expected daily cadence, larger only when cadence degrades. Not a solvency or fund-safety issue — aggregate accounting stays correct throughout.

### Conditions that would warrant revisiting

- Actual rebalance cadence departs materially from the daily target for sustained periods (e.g. low-APY-differential regimes, or CRE liveness degradation per KI-007), making the per-instance redistribution effect large enough to matter economically.
- Product requirements change to require fee attribution proportional to actual holding time regardless of cadence.
- A per-holder accrual mechanism is added to the vault for an unrelated reason (e.g. vesting, streaming rewards), at which point extending it to management fees would be close to free.

---

## KI-019 — `initialize` functions have no access control

**Status:** Accepted — mitigated by atomic proxy deployment.

**Last reviewed:** 2026-08-09

**Component:** `ParentVault.initialize`, `ChildVault.initialize`, `YieldcoinShare.initialize`.

### Summary

`ParentVault`, `ChildVault`, and `YieldcoinShare` are deployed behind `ERC1967Proxy` and each expose an `initialize` function guarded only by OpenZeppelin's `initializer` modifier (single-call-only), not by any caller-restricting access control. In isolation, an uninitialized proxy could be front-run by anyone calling `initialize` first.

### Why this is accepted, not mitigated

Every deploy script (`DeployParent.s.sol`, `DeployChild.s.sol`) constructs the `ERC1967Proxy` with the `initialize` call encoded directly as the proxy constructor's `data` argument, so deployment and initialization happen in the same transaction, atomically. There is never a block in which the proxy exists on-chain without already being initialized, so there is no window for a third party to call `initialize` first. Each implementation contract's constructor also calls `_disableInitializers()`, so the implementation itself can never be initialized or hijacked directly.

Adding caller-restricting access control (e.g. an `onlyOwner`/`onlyDeployer` check) to `initialize` would require passing and storing a deployer/owner address ahead of the very call that sets up roles, purely to guard against a front-running window that atomic proxy construction already eliminates. That's extra state and logic for no additional safety margin.

### Conditions that would warrant revisiting

- A future deployment path decouples proxy creation from the `initialize` call (e.g. a two-step deploy-then-initialize flow, or a factory that deploys proxies for later initialization by a separate transaction).
- `initialize` is added to a contract that isn't deployed exclusively through the atomic `ERC1967Proxy` constructor-calldata pattern used today.

---

## KI-020 — Pausing `YieldcoinShare` independently of a vault can stall rebalance finalization and, transitively, epoch settlement

**Status:** Accepted — inherent to `YieldcoinShare` and the vaults having independent pause authority.

**Last reviewed:** 2026-08-13

**Component:** `ParentVaultFeesLib._collectManagementFee` (invoked from `ParentVaultRebalanceLib._finalizeRebalance`, reached via `ParentVault.completeRebalance`, `ParentVault.executeRecovery`, and the rebalance branch of `ParentVault._ccipReceive`), `YieldcoinShare.mint`/`_update`.

### Summary

`YieldcoinShare` and each vault hold separate `PAUSER_ROLE`/`UNPAUSER_ROLE` grants (see [ACCESS_CONTROL_MATRIX](./ACCESS_CONTROL_MATRIX.md)). Per [DD-004](../protocol/DECISIONS.md#dd-004---pause-contains-external-execution-and-lifecycle-finalization), pausing ParentVault blocks `completeRebalance` and `completeEpochDeposit`. Pausing only `YieldcoinShare` while ParentVault remains unpaused creates a separate finalization dependency.

The rebalance finalization path mints management-fee shares: `ParentVaultRebalanceLib._finalizeRebalance` unconditionally calls `ParentVaultFeesLib._collectManagementFee`, which calls `IShare(share).mint($.s_treasury, feeShares)` whenever `feeShares != 0`. `YieldcoinShare.mint` routes through `_update`, gated `whenNotPaused` on the token's own pause state. If an operator pauses only `YieldcoinShare` while ParentVault remains unpaused, the fee mint reverts, and with it the entire `completeRebalance`/`executeRecovery`/CCIP-finalize transaction. `s_rebalance.state` remains `REBALANCING` until the token is unpaused and finalization is retried. While `REBALANCING`, `ParentVaultEpochLib._closeEpoch` unconditionally reverts (`ParentVault__RebalanceInProgress`), so no epoch anywhere in the deployment can settle until the stuck rebalance clears.

Since `MIN_REBALANCE_PERIOD` is one hour and any live deployment carries `s_totalShares > 0`, `feeShares` rounds to nonzero on essentially every real finalization — this is the default outcome of a token-only pause during an in-progress rebalance, not a rare edge case.

### Why this is accepted, not mitigated

`YieldcoinShare` is deeply coupled into ordinary vault operation independent of this path: `claimShares` mints and `claimAsset` burns through the same token, so token pause necessarily disrupts vault-adjacent user flows. Wrapping the fee mint in a try/catch would decouple this one call site from token pause but would not change the operational dependency between independently pausable components. It would also weaken the atomic relationship between rebalance finalization and management-fee accounting. Operators therefore pause the token and vault together for full containment and avoid token-only pause while a rebalance is in flight.

### Residual risk

- No funds are lost, stuck, or misdirected — this is a liveness/availability effect only. `s_rebalance.state` and the affected epoch remain in a well-defined, inspectable state (`REBALANCING`, `OPEN`) rather than any corrupted or ambiguous one.
- Users can still submit new deposits and withdraw intents into the current `OPEN` epoch while stuck, and can cancel them per the normal current-epoch cancellation path, but no epoch can settle and no existing claim can be paid until the token is unpaused.
- The stall is fully recoverable by the same operator action that caused it: unpausing `YieldcoinShare` allows the next `completeRebalance`/`executeRecovery`/CCIP-finalize retry to succeed and immediately unblocks `closeEpoch`.
- The specific trigger — pausing the token while leaving ParentVault unpaused during a `REBALANCING` state — requires deliberate, narrowly scoped operator action; it is not reachable by any unprivileged actor. Pausing ParentVault also blocks finalization under KI-013 before fee minting is attempted.

### Conditions that would warrant revisiting

- Incident-response experience shows operators reaching for "pause the token only" during an in-progress rebalance often enough that the resulting settlement stall becomes a recurring operational cost rather than a rare mistake.
- A future change makes management-fee collection (or any other mint/burn folded into rebalance finalization) conditional or deferrable without weakening the atomicity the current design relies on for its invariant guarantees.
- `YieldcoinShare` pause/unpause authority is ever separated from the operator group already coordinating vault pause/unpause, increasing the chance the two are toggled independently without full context.

---

## KI-021 — Secondary protocol rewards may be unclaimed, expire, or become unrecoverable

**Status:** Accepted — secondary incentives are outside the audit-ready MVP's accounting and recovery requirements.

**Last reviewed:** 2026-08-13

**Component:** Protocol adapters and external incentive systems, including Aave rewards controllers, Merkl distributions, partner incentives, points programs, and Compound V3 rewards.

**Applies to:** Any current or future strategy whose position may qualify for rewards beyond the underlying asset's base supply yield.

### Summary

Yieldcoin v2 accounts only for yield reflected in the underlying-asset value returned by each adapter's `getTVL()`. A protocol or third party may separately assign ERC-20 rewards, Merkle-based distributions, points, or other incentives to the adapter address holding a strategy position. Those secondary incentives are not included in vault TVL, share price, epoch settlement, withdrawal claims, fees, or any user entitlement.

Reward systems are not uniform across supported strategies. Aave V3 may use protocol-native rewards controllers, Aave V4 may expose Merkl campaigns or off-chain points programs, Compound V3 may use its legacy CometRewards contract or external distribution systems, and partner programs may introduce other claim requirements. Some rewards require the earning adapter itself or an authorized operator to submit protocol-specific calls or Merkle proofs before a deadline. Where an adapter does not implement that mechanism, rewards may remain unclaimed, expire, or become permanently unrecoverable.

`CompoundV3Adapter.claimRewards(to)` is a best-effort, Compound-specific custody/recovery hook. Its presence does not establish a protocol requirement or interface guarantee that secondary incentives are supported uniformly across adapters. A market with no configured Compound reward token is also valid: the adapter still attempts the protocol claim but skips the configured-token balance sweep.

### Why this is accepted, not mitigated

The audit-ready MVP is designed to capture the base supply yield that increases the underlying value of its lending position. Additional incentive rewards are not a product priority and are deliberately excluded from the protocol's user-facing accounting model under [DD-009](../protocol/DECISIONS.md#dd-009---yield-accounting-is-underlying-asset-only).

Uniform secondary-reward recovery would not be a small adapter abstraction. It would require protocol-specific controller and distributor integrations, Merkle-proof sourcing, claim-deadline monitoring, recipient and operator management, treatment of off-chain points, reward-token custody policy, and decisions about sale or distribution. A generic token sweep would also create additional privileged authority and would need to protect position tokens and underlying principal. Adding that surface solely to recover non-required ancillary value would increase implementation, testing, operational, and audit complexity without improving user principal safety or the base-yield product.

### Residual risk

- Users and the protocol may forgo economic value from secondary incentives while a strategy is active.
- Claimable rewards may expire or become unrecoverable when no compatible adapter claim path or external forwarding arrangement exists.
- Secondary rewards do not back Yieldcoin shares, so foregoing them does not make the vault insolvent or reduce the underlying-asset TVL already reported by adapters.
- The presence or absence of a reward program does not affect deposits, withdrawals, rebalances, or epoch settlement unless a future integration explicitly couples those paths.
- The existing Compound claim hook is best effort and may not cover future Compound reward-delivery mechanisms.

### Operational treatment

- Do not include secondary incentives in advertised vault APY, TVL, user balances, or expected withdrawal value.
- Treat any recovered Compound rewards as outside normal vault accounting and handle them according to the operator's off-chain custody policy.
- No operational guarantee is made that Aave, Merkl, partner, points, or future Compound incentives will be monitored or claimed.

### Conditions that would warrant revisiting

- Product requirements change to include secondary incentives in advertised yield, protocol revenue, or user entitlements.
- The expected value of foregone rewards becomes material relative to the cost and risk of supporting them.
- A stable, common claiming or forwarding mechanism becomes available across the supported strategies.
- A future adapter integration makes secondary-reward recovery a launch requirement.

---

## KI-022 — Adapter-resolution failure during rebalance activation reverts atomically instead of degrading into typed recovery state

**Status:** Accepted — atomic revert is safe (no fund loss or state desync), but the failure surfaces outside Yieldcoin's own recovery bookkeeping.

**Last reviewed:** 2026-08-15

**Component:** `ChildVault._rebalanceToNewStrategy` (local branch, `ChildVault.sol`), `BaseVault._handleCCIPRebalance` (`BaseVault.sol`, reached from both vaults' `_ccipReceive` REBALANCE branch), `BaseVaultStrategyLib._setActiveAdapter`.

### Summary

When a rebalance activates a new strategy adapter on the destination chain, `_setActiveAdapter(protocolId)` is called directly, with no try/catch, immediately before the destination deposit attempt:

```solidity
// ChildVault._rebalanceToNewStrategy, local branch
address newAdapter = _setActiveAdapter(newStrategy.protocolId); // reverts if unregistered/vault-mismatched
bool success = _executeDeposit(tvlToRebalance, false, newAdapter); // this failure IS caught
```

`_setActiveAdapter` reverts if the target protocol has no registered adapter on this chain (`BaseVault__NoAdapterRegistered`) or the registered adapter is bound to a different vault (`BaseVault__InvalidAdapterVault`). Unlike the deposit call one line later — which uses `revertOnFailure = false` and, on failure, stores `RebalanceDepositRecovery` — a revert from `_setActiveAdapter` is not caught anywhere in the call chain up to the external entry point (`ChildVault.executeRebalance`, `ChildVault.executeRecovery`, or `_ccipReceive` on either vault). The whole transaction reverts.

This is the same shape on the CCIP-receive side (`BaseVault._handleCCIPRebalance`, shared by both vaults' `_ccipReceive` REBALANCE handling): `_setActiveAdapter` is called before `_handleCCIPRebalanceDeposit`, uncaught, so an unregistered destination adapter reverts CCIP message execution itself rather than producing a Yieldcoin-tracked recovery.

### Why this is accepted, not mitigated in code

EVM atomicity makes the revert safe: nothing partially executes. For `ChildVault`'s same-chain continuation, an already-completed withdrawal from the old adapter earlier in the same transaction rolls back too — the old adapter still holds the funds and `s_activeProtocolAdapter` still points at it, exactly as if the call had never been attempted. For the CCIP-receive path, the message/tokens are not lost; CCIP's own execution-retry mechanics (external to these contracts, see [ENV-002](#external-assumptions)) apply, the same way [KI-014](#ki-014--strategy-withdraw-recovery-requires-full-market-liquidity) already accepts that "local recovery does not guarantee global CCIP liveness."

Per [DD-011](../protocol/DECISIONS.md#dd-011---adapter-registry-changes-are-not-live-migrations), operators are already responsible for registering the destination adapter before a rebalance activates there. This entry exists to make explicit what DD-011 did not previously spell out: violating that responsibility does not degrade into the same typed-recovery framework (`s_recoveryMode` + its 5 structs, see [Recovery](./INVARIANTS.md#recovery)) that covers every other fallible step in the same call chain — it produces a raw transaction revert (same-chain case) or a CCIP-layer execution failure (cross-chain case) instead.

Catching this specific revert and converting it into a 6th typed recovery mode was considered and rejected: it would add a new state-machine surface and reconciliation path for a failure that requires operator misconfiguration to trigger and has no fund-loss consequence today, contrary to the project's simplicity priority — the same reasoning [KI-016](#ki-016--parentvault-epoch-and-rebalance-calls-revert-atomically-with-no-stored-recovery-allowing-cost-bounded-settlement-griefing) applies to Parent's synchronous local-strategy reverts.

### Residual risk

An operator who initiates or continues a rebalance toward a protocol that is globally supported (`ParentVault.s_supportedProtocol`) but not yet adapter-registered on the specific destination chain will see the operation fail outright rather than land in `s_recoveryMode`. Monitoring that watches only `executeRecovery()`/`getRecoveryMode()` will not detect this failure. For the same-chain case, the fix is operational: register the adapter, then retry the CRE report. For the cross-chain case, operators must additionally check CCIP's own message-execution status, not only Yieldcoin's recovery state, before concluding the rebalance is stuck.

No funds are lost or become unbacked in either case — this is an operational-visibility gap, not a solvency or accounting issue.

### Operational mitigations

- Before initiating or approving a rebalance to a new protocol, verify the destination chain's `AdapterRegistry` already has a valid, vault-bound adapter registered for that protocol ID (per [DD-011](../protocol/DECISIONS.md#dd-011---adapter-registry-changes-are-not-live-migrations)'s existing operator responsibility).
- Extend the [KI-007](#ki-007--epoch-close-depends-on-cre-workflow-execution)/[KI-013](#ki-013--a-paused-parent-or-child-vault-can-leave-a-cross-chain-epoch-or-rebalance-in-progress) monitoring to also alert on `WorkflowRouter.onReport` reverts specifically during rebalance activation, and to check CCIP message-execution status (not just `s_recoveryMode`) whenever a cross-chain rebalance appears stuck.

### Conditions that would warrant revisiting

- Adapter-resolution failures during rebalance activation are observed in practice, rather than remaining a purely theoretical operator-sequencing mistake.
- The project decides the added state-machine complexity of a 6th typed recovery mode is worth full symmetry with the deposit-failure case.
- CCIP's own execution-retry visibility becomes difficult for operators to monitor independently of Yieldcoin's own recovery state.

---

## KI-023 — Default admin role transfer delay remains zero until the admin raises it post-handoff

**Status:** Accepted — operational responsibility of the incoming default admin, not enforced on-chain.

**Last reviewed:** 2026-08-15

**Component:** `ParentVault`, `ChildVault`, `YieldcoinShare` (`AccessControlDefaultAdminRulesUpgradeable`).

### Summary

Per [DD-018](../protocol/DECISIONS.md#dd-018---default-admin-role-transfer-delay-starts-at-zero-to-support-deploy-script-bootstrapping), the three upgradeable contracts holding or minting/burning user funds (`ParentVault`, `ChildVault`, `YieldcoinShare`) initialize their default-admin transfer delay to zero, so the deploy script can hand off `DEFAULT_ADMIN_ROLE` from the deployer EOA to the configured default admin without waiting out a delay first.

That zero delay is not automatically raised by the contracts themselves. Until the incoming default admin calls `changeDefaultAdminDelay(newDelay)` — expected to be one of its first actions after accepting the role, targeting roughly 3-7 days — any `beginDefaultAdminTransfer`/`acceptDefaultAdminTransfer` pair on any of these three contracts completes with no delay and no window for `cancelDefaultAdminTransfer()` to be used in response.

### Why this is accepted, not enforced on-chain

Enforcing a nonzero delay in the contracts themselves would reintroduce the exact deploy-script bootstrapping problem [DD-018](../protocol/DECISIONS.md#dd-018---default-admin-role-transfer-delay-starts-at-zero-to-support-deploy-script-bootstrapping) avoids: the deployer-to-admin handoff itself would have to wait out that delay, since the delay applies to every transfer, not only ones initiated after some hypothetical "launch complete" marker the contracts have no way to observe. There is no on-chain signal available to distinguish "this is the one-time deploy handoff" from "this is a later, potentially adversarial transfer" — the contracts intentionally do not try to guess, and instead rely on the incoming admin to raise the delay themselves once they hold the role.

### Residual risk

Between the deploy-script handoff completing and the default admin calling `changeDefaultAdminDelay`, a compromised `DEFAULT_ADMIN_ROLE` key on any of the three contracts can complete a hostile transfer instantly, with no cancellation window. If the admin never raises the delay at all, this window is indefinite rather than transient.

This is bounded by the same operator-trust assumption already accepted in [KI-001](#ki-001--centralized-trust-in-privileged-operatoradmin-roles) (`DEFAULT_ADMIN_ROLE` is held behind a multisig with qualified signers) — a zero delay narrows the response window if that multisig is compromised, but does not itself grant any authority the multisig didn't already have. `DEFAULT_ADMIN_ROLE` alone administers roles only ([AC-001](./INVARIANTS.md#access-control)); it has no recurring operational authority unless separately granted an operational role, so a hostile transfer's immediate blast radius is role administration, not direct fund movement.

### Operational mitigations

- The incoming default admin raises the delay via `changeDefaultAdminDelay` on all three contracts (`ParentVault`, `ChildVault`, `YieldcoinShare`) as one of its first post-handoff actions, targeting a value in the 3-7 day range.
- Monitor `DefaultAdminTransferScheduled`/`DefaultAdminDelayChangeScheduled` events (emitted by `AccessControlDefaultAdminRulesUpgradeable`) on all three contracts from deployment onward, so any transfer attempted before the delay is raised is visible immediately, not discovered after the fact.
- Treat the delay-raise transaction as part of the launch runbook, not a follow-up task — verify it has landed before treating deployment as complete.

### Conditions that would warrant revisiting

- The delay-raise step is observed being skipped or delayed in practice across deployments.
- OpenZeppelin's `AccessControlDefaultAdminRules` exposes a way to set a nonzero delay that takes effect only after a distinguishable "deployment complete" signal, removing the bootstrapping conflict this entry currently accepts.
- `DEFAULT_ADMIN_ROLE` is ever granted additional recurring operational authority beyond role administration, which would raise the blast radius of a zero-delay-window compromise beyond what [KI-001](#ki-001--centralized-trust-in-privileged-operatoradmin-roles) already bounds.

---

## KI-024 — Unseeded bootstrap allows adapter donation and claim ordering to redirect depositor principal

**Status:** Accepted — mitigated by a permanent locked seed position established during launch.

**Last reviewed:** 2026-08-25

**Component:** `ParentVaultEpochLib._closeEpoch`, `ParentVaultUserEpochLib._claimShares`, `ParentVault.claimSharesFor`, strategy-adapter TVL accounting, and parent deployment.

### Summary

The parent vault begins with zero authoritative and ERC-20 share supply. If an unprivileged first depositor obtains the bootstrap supply, they can withdraw almost all of it and leave a deliberately coarse share unit. They can then supply underlying directly to the active lending protocol on behalf of the adapter, where it is included in strategy TVL as described in [KI-008](#ki-008--strategy-tvl-can-include-permissionless-third-party-supplies).

In an epoch with equal deposits and withdrawals, `closeEpoch` performs no adapter movement. Fresh deposits can therefore pay the attacker's old withdrawal while the unsolicited adapter position remains as backing for newly allocated shares, fully recovering the out-of-band supply.

Deposit claims are allocated from shrinking remaining-deposit and remaining-share pools. Each non-final claim rounds down, while the claim that exhausts the pool receives the remainder. Because `claimSharesFor` is permissionless, the attacker can claim for other depositors first and reserve that remainder for their own deposit. At a coarse share unit, the remainder can represent material principal rather than dust.

### Why this is accepted, not mitigated in accounting

The launch procedure permanently locks at least the shares produced by a 100 USDC bootstrap deposit. With 18-decimal shares and 6-decimal USDC, this establishes at least `100e18` non-withdrawable share wei. Making one share wei materially valuable would then require infeasible strategy TVL, and the existing zero-share-mint settlement guard binds first.

The lock is a blank, non-upgradeable contract deployed with ParentVault and has no function capable of transferring, approving, or withdrawing its shares. Both `withdraw` and `withdrawFor` escrow shares from the caller, so neither can remove shares held by the lock.

Changing claim allocation to use immutable epoch totals or reserving minimum liquidity in ParentVault would add accounting and invariant complexity. The permanent seed establishes the required supply floor without changing the settlement model.

### Operational mitigation

- Follow the [parent bootstrap procedure](../operator/DEPLOYMENT.md#bootstrap-the-parent-vault): deposit at least 100 USDC into epoch one, then activate CRE to close the epoch, manually claim the shares, and transfer all seed shares to the deployed `YieldcoinShareSeedLock`.
- Verify the lock bytecode and confirm both `ParentVault.getTotalShares()` and its share-token balance are at least `100e18` before treating the vault as launched.
- Monitor unexpected strategy TVL increases as required by [KI-008](#ki-008--strategy-tvl-can-include-permissionless-third-party-supplies).

### Residual risk

The contracts do not require the seed transfer before accepting ordinary deposits. Until launch operators complete and verify the lock step, an unprivileged bootstrapper can establish coarse supply and retain the combined donation and claim-ordering path. Once the locked supply floor exists, the shares cannot be withdrawn and the attack precondition cannot be recreated through ordinary vault use.

### Conditions that would warrant revisiting

- A deployment is opened for normal use before the locked seed position is verified.
- The seed amount, underlying precision, share precision, or minimum deposit changes such that the documented supply floor no longer provides the intended bound.
- A future lock contract gains executable or upgradeable behavior.
- Claim allocation or adapter TVL accounting changes enough to remove the underlying attack path in code.

---

## KI-025 — Over-cap unrepresentable deposits can remain in Child recovery

**Status:** Accepted — fail-closed dust-buffer bound; terminal deposit cancellation is deferred.

**Last reviewed:** 2026-08-28

**Component:** Aave V3/V4 adapters and `ChildVault` epoch-deposit recovery.

### Summary

The Aave adapters retain deposits that are too small to mint protocol shares, but cap the tracked buffer at 50 underlying base units. If an inbound Child deposit would still mint zero shares after the aggregate buffer exceeds that cap, the adapter reverts and `ChildVault` stores the exact amount as `EPOCH_DEPOSIT` recovery.

Recovery retries the same amount. Because Aave's asset-per-share exchange rate is non-decreasing, waiting generally cannot make an unrepresentable amount mint shares, and the recovery may remain pending until an upgrade or state repair. The underlying assets remain held and accounted for in `ChildVault`; the risk is loss of liveness, not loss of funds.

### Why this is accepted

- The fixed cap prevents a paused, misconfigured, or malfunctioning protocol from causing a large deposit to be silently retained and reported as successfully invested.
- Fifty base units is economically negligible for USDC and far above the current live rounding boundary. Reaching an exchange rate where more than 50 base units mint zero shares is not considered practically reachable for the configured reserves.
- A safe terminal resolution requires coordinated Child-to-Parent cancellation or abort accounting, which is outside the adapter-level dust fix.

### Conditions that would warrant revisiting

- A configured reserve's first share-minting amount approaches the 50-base-unit cap.
- An over-cap `EPOCH_DEPOSIT` recovery occurs in production.
- The protocol adds an authenticated cross-chain deposit-abort or terminal-recovery mechanism.

---

## KI-026 — Extreme remote-deposit reconciliation can remain executing when adjusted shares round to zero

**Status:** Accepted — fail closed; mitigated by the permanent locked seed position.

**Last reviewed:** 2026-08-28

**Component:** `ParentVaultEpochLib._completeEpochDeposit`, remote net-deposit completion, and parent bootstrap.

### Summary

Remote deposit completion reduces the affected epoch's pending shares when CCIP delivers less than Parent sent. For gross deposits `D`, withdrawal claims `W`, actual destination deposit `A`, and nominal pending shares `R`, the reconciled allocation is `floor(R * (W + A) / D)`. Parent reverts with `ParentVault__DepositWouldMintZeroShares` if that result is zero, leaving the epoch `EXECUTING`.

Before the aggregate allocation reaches zero, an extreme reconciliation can leave the epoch with a nonzero adjusted share allocation that is nevertheless too small to allocate one share wei to every minimum-size deposit. During `claimShares`, each non-final claim is calculated as `floor(depositAmount * remainingShareMintAmount / remainingDepositClaimAmount)`. That calculation can return zero for a small depositor, while the final claimant receives the remaining share wei through the last-claim remainder rule. This requires the same near-total delivery loss or pathologically coarse share supply described below.

The current open-epoch `forceCancelDeposit` escape hatch cannot resolve this state: the affected epoch has already closed and its net assets have reached the remote strategy. Finalizing with zero shares would confiscate the deposit cohort's value, while forcing one share could socialize a material loss when supply is pathologically coarse. A generic post-close escape hatch is therefore not exposed.

### Why this is accepted

- The close-time zero-share guard guarantees `R * 1 USDC >= D`, so reconciliation cannot round to zero when `W + A >= 1 USDC`.
- With the launch-required `100e18` locked-share floor, any positive six-decimal USDC delivery continues to represent at least one share wei until strategy TVL exceeds roughly $100 trillion. Triggering the guard under intended initialization additionally requires a near-total CCIP loss.
- Without the locked seed, a tiny nonzero supply can make one share wei materially valuable and allow the guard to trigger at ordinary TVL. That is part of the coarse-supply condition already mitigated by [KI-024](#ki-024--unseeded-bootstrap-allows-adapter-donation-and-claim-ordering-to-redirect-depositor-principal).
- Failing closed preserves the exact cross-chain state for investigation instead of silently choosing which cohort absorbs an unrepresentable allocation.

### Operational mitigation

- Complete and verify the permanent 100 USDC seed lock before enabling normal deposits.
- Alert on `ParentVault__DepositWouldMintZeroShares` from remote deposit completion and keep the affected Parent and Child paths contained.
- If the condition occurs, inspect the delivered amount, strategy balance, share supply, and epoch accounting, then deploy a purpose-built UUPS repair that defines the economic resolution explicitly.

### Conditions that would warrant revisiting

- A valid production completion reaches the zero-adjusted-share guard.
- A valid production claim returns zero shares after remote-deposit reconciliation.
- The minimum deposit, asset precision, share precision, or locked-seed amount changes.
- Supported CCIP routes can apply near-total transfer losses in normal operation.
- The protocol adds authenticated cross-chain epoch abort, refund, or recapitalization accounting.

---

## KI-027 — Aave supply caps can leave rebalance or epoch deposits in recovery

**Status:** Accepted — Low at launch scale, conditioned on maintaining substantial live reserve headroom.

**Last reviewed:** 2026-08-29

**Component:** `ChildVault` `REBALANCE_DEPOSIT` / `EPOCH_DEPOSIT` recovery and `AaveV3Adapter`.

### Summary

A Child deposit into Aave requires enough reserve capacity for the full amount. If a rebalance deposit exceeds the reserve supply cap, `ChildVault` stores `REBALANCE_DEPOSIT` recovery. If an inbound epoch deposit exceeds the cap, it stores `EPOCH_DEPOSIT` recovery. Both recovery paths retry the same deposit amount and cannot abort, reduce, or reroute it.

Aave also allows anyone to supply on behalf of an adapter. A third party can use this to consume reserve capacity while transferring ownership of the supplied assets to the adapter. If the adapter-owned balance and pending deposit exceed the supply cap on their own, unrelated Aave suppliers exiting will not restore liveness because the recovery path cannot withdraw the adapter balance.

While either recovery remains pending, normal Child operations are blocked and the corresponding Parent lifecycle cannot complete. The impact is potentially indefinite loss of availability rather than theft or insolvency. The pending deposit remains held by `ChildVault`, while unsolicited supply remains owned by the adapter; recovery requires an Aave cap increase or a purpose-built upgrade that reconciles and clears the blocked lifecycle.

### Why this is accepted

The Aave pools being considered generally have eight-figure or greater supply caps and available headroom, while expected Yieldcoin TVL is extremely low by comparison. The third-party attack also requires the attacker to give up ownership of the supplied assets and receive no claim against the adapter. Under these conditions, the required capital is disproportionate to the value immobilized. The protocol accepts this liveness risk rather than adding further rebalance-recovery state transitions.

This rating depends on the margin between the position and live headroom, not on a contract-enforced bound. The attacker cost falls below the value immobilized as the position approaches half the available headroom.

### Operational considerations

- At every target-selection review, compare the position with current available headroom for every candidate reserve; configured supply caps alone are insufficient because ordinary supply consumes headroom.
- Use a position reaching 10% of the smallest live headroom across candidate targets as an early review threshold.
- Re-rate the issue if the position approaches 50% of the available headroom of any candidate target, if ordinary supply materially contracts that headroom, or if a target whose headroom is close to the position may be selected.

---

## KI-028 — Remote withdraw dust can settle with a zero claim pool

**Status:** Accepted — bounded withdrawal forfeiture avoids uneconomic Child CCIP sends.

**Last reviewed:** 2026-08-31

**Component:** `ParentVaultEpochLib._closeEpoch` remote net-withdraw path.

### Summary

When a remote epoch's net withdrawal is below `getRemoteWithdrawDustThreshold()`, ParentVault sends no Child request and makes the epoch immediately claimable using only that epoch's deposits. If the epoch has no deposits, its withdraw claim pool is zero. Claiming then burns the escrowed shares without transferring any asset.

The threshold is one hundredth of a whole underlying asset unit, or `0.01 USDC` for the USDC vault. The forfeiture is strictly less than that threshold per affected epoch, but it can equal the withdrawing user's full expected payout. This is distinct from claim-time integer rounding documented in KI-003.

### Operational considerations

- User interfaces should warn on withdrawals expected to fall within the remote dust threshold.
- Monitor `RemoteWithdrawDustForfeited`, including epochs whose withdraw claim pool is zero.

---

## KI-029 — Subsidized remote flows can exhaust LINK and delay epoch settlement

**Status:** Accepted — bounded by remote-withdraw dust forfeiture, configured daily settlement, and operational LINK monitoring.

**Last reviewed:** 2026-09-02

**Component:** `ParentVault.closeEpoch`, `ChildVault.executeEpochWithdraw`, and vault-funded CCIP sends.

### Summary

Vaults pay CCIP fees from shared LINK reserves rather than charging the users whose epoch activity causes a message. A user can therefore submit repeated remote flows that consume LINK without permanently paying the corresponding fee.

For remote net deposits, a positive net flow causes ParentVault to send a CCIP message. If ParentVault lacks enough LINK, `closeEpoch` reverts atomically and the epoch remains open. Users retain the normal ability to cancel their current-epoch intents.

For remote net withdrawals, shortfalls below `getRemoteWithdrawDustThreshold()` are forfeited and cause no message. A shortfall at or above the threshold is serviced in full and causes ChildVault to pay for a CCIP message. If the strategy withdrawal succeeds but the send fails, ChildVault stores `CCIP_SEND` recovery and the Parent epoch remains `EXECUTING` until LINK is supplied and recovery succeeds.

The dust rule prevents a small share position from being split into base-unit withdrawals that each consume a full fee. It does not make serviced messages user-funded: consecutive withdrawal messages require at least `getRemoteWithdrawDustThreshold()` of share entitlement per epoch, while a small position can be recycled more slowly through alternating withdrawal and deposit epochs.

Production workflow configuration settles eligible epochs once per day, limiting ordinary attack throughput to one epoch close per day. The contract-level minimum period remains one hour, so the daily cadence is an operational configuration rather than an on-chain invariant.

`getParentOperationalState()` exposes authoritative `totalShares` alongside the current epoch so the workflow can estimate the net remote withdrawal before closing and gracefully take no action when it falls below the workflow's economic floor. This mitigation is operational and is not enforced onchain.

The impact is availability and settlement delay rather than loss of principal or accounting corruption. The protocol accepts this residual risk because amplification below the remote service threshold is removed, CCIP activity is rate-limited by epoch settlement, and LINK reserves can be monitored and replenished.

### Operational considerations

- Configure production epoch settlement to run no more than once per day and review any cadence change as a security-relevant configuration change.
- Monitor ParentVault and every ChildVault LINK balance against current route quotes and maintain sufficient forward runway.
- Alert on repeated minimum-sized remote net deposits or serviced remote net withdrawals.
- Alert when an epoch remains `OPEN` or `EXECUTING` beyond its expected daily settlement window, and distinguish insufficient LINK from adapter, router, or workflow failures.
- Replenish ParentVault LINK and retry `closeEpoch`, or replenish ChildVault LINK and call permissionless `executeRecovery()`, according to the failure path.

### Conditions that would warrant revisiting

- Production epoch settlement is configured materially more frequently than once per day.
- CCIP fees increase enough to shorten LINK runway materially.
- Monitoring or replenishment cannot restore settlement within the protocol's availability objectives.
- Repeated subsidized remote flows are observed in production.
