# Known Issues

This document records security-relevant issues that are known to the protocol team and have been explicitly accepted, deferred, or judged to be outside the trust boundary of the system. Each entry describes the issue, why it is not being mitigated in code (or is only partially mitigated), and the operational or design assumptions that bound its impact.

Entries here are intentionally **not assigned a severity rating** — they are accepted properties of the system, not open findings.

IDs are stable. Once assigned, a KI-XXX identifier is never reused or renumbered, even after the underlying issue is resolved. Resolved issues remain in this document with their status updated.

---

## KI-001 — Centralized trust in privileged operator/admin roles

**Status:** Accepted.

**Last reviewed:** 2026-06-02

**Component:** Access control across vaults, router, registry, token, and PolicyEngine.

**Applies to:** ParentVault, ChildVault, WorkflowRouter, AdapterRegistry, YieldcoinShare, and PolicyEngine-governed ACE policy administration.

### Summary

Yieldcoin v2 relies on multiple privileged roles for protocol operation. Human-held privileged roles include:

- **`DEFAULT_ADMIN_ROLE`** for local role administration (grant/revoke and admin-transfer acceptance via `AccessControlDefaultAdminRules`).
- **`CONFIG_OPERATOR_ROLE`** for protocol configuration (vault/router/registry settings, adapter registration, treasury/emergency receiver, workflow metadata/selectors, token metadata/CCIP admin wiring).
- **`PAUSER_ROLE` / `UNPAUSER_ROLE`** for pause controls across vaults, WorkflowRouter, and YieldcoinShare.
- **`EMERGENCY_DRAINER_ROLE`** for paused-mode emergency asset drain (subject to delay guards).
- **`LINK_OPERATOR_ROLE`** for LINK withdrawal from vaults.
- **`POLICY_ENGINE_MANAGER_ROLE`** for replacing attached policy engines on policy-protected contracts.
- **`COMPLIANCE_OPERATOR_ROLE`** for forced transfer and freeze/unfreeze functions on YieldcoinShare.
- **PolicyEngine `ADMIN_ROLE` / `POLICY_CONFIG_ADMIN_ROLE`** for policy wiring and policy configuration.

The system also includes contract-held or infrastructure roles such as `KEYSTONE_FORWARDER_ROLE` (CRE report ingress) and token `MINTER_ROLE`/`BURNER_ROLE` held by ParentVault.

_Note: `DEFAULT_ADMIN_ROLE` for ACE components does not have the same `AccessControlDefaultAdminRules` safeguards as `DEFAULT_ADMIN_ROLE` for the native Yieldcoin v2 components. Please see [ACCESS_CONTROL_MATRIX](./ACCESS_CONTROL_MATRIX.md) for further info._

### Threat model

A compromised or malicious signer controlling a privileged role can take adverse actions within that role's authorized scope (for example, misconfiguration, service interruption, policy rewiring, compliance actions, or emergency operations).

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

**Threat model:** DefiLlama compromise, TLS-terminating/MITM compromise, or misconfiguration of DEFILLAMA_UPSTREAM_URL to an attacker-controlled endpoint.

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

**Component:** `ParentVault._collectManagementFee`, vault pause controls, and rebalance finalization.

### Summary

Management fees accrue on calendar time between completed rebalances. `ParentVault._collectManagementFee` uses the elapsed time between `s_rebalance.lastRebalanceCompletedTimestamp` and the current rebalance finalization, capped at `365 days` per collection. It does not subtract time where the vault was paused.

This means a pause interval can contribute to the next management fee collection. The fee remains bounded by the annual management fee formula for a single collection: at the current `MANAGEMENT_FEE_BPS = 100`, no rebalance finalization can collect more than the one-year management fee amount (`ceil(totalShares * 1%)`) regardless of how long the vault was paused or how long rebalance finalization was delayed.

### Why this is accepted, not fully excluded

The management fee is treated as an AUM-style calendar-time fee, not purely as a fee for uninterrupted user-facing availability. During a pause, capital may still remain deployed in a strategy and continue earning yield.

The `ParentVault` can only observe its own pause state. It cannot reliably determine whether the full system was operational across ChildVaults, WorkflowRouters, underlying token transferability, strategy protocols, adapters, and cross-chain settlement. Subtracting only `ParentVault.s_pausedAt` intervals would create incomplete liveness accounting and could undercharge management fees while funds remain deployed and yield-bearing.

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

**Last reviewed:** 2026-07-08

**Component:** CRE epoch workflow, `WorkflowRouter.onReport`, and `ParentVault.closeEpoch`.

### Summary

Epoch settlement is intentionally driven by the Chainlink CRE workflow. The workflow's cron handler reads the current parent epoch, checks that it is open, has activity, is past `MIN_EPOCH_PERIOD`, has no active rebalance, reads TVL from the active strategy chain, and submits `closeEpoch(tvl)` through `WorkflowRouter.onReport`.

If the CRE workflow does not execute, cannot read the required state, cannot submit a valid report, or the report does not reach `WorkflowRouter`, the current parent epoch remains `OPEN`. There is no autonomous on-chain timer and no public `closeEpoch` path; `ParentVault.closeEpoch` is restricted to `EPOCH_OPERATOR_ROLE`, which is granted to the `WorkflowRouter` under the normal access-control model.

### Impact

The failure mode is delayed settlement:

- The current epoch remains open until a valid workflow report closes it.
- Depositors and withdrawers for that epoch cannot claim shares or assets while the epoch remains open.
- The next epoch is not opened, so later user intents continue to accrue into the same open epoch rather than a new scheduled epoch.
- The settlement price is based on TVL at the eventual close, not at the missed scheduled close time.
- For remote-strategy net-withdraw epochs, the second CRE step (`EpochExecuting` log handling on the child chain) is also required before the parent epoch can become claimable.

This does not by itself create an accounting inconsistency or direct loss of funds. User deposits and withdraw-intent shares remain escrowed by the protocol. While the epoch is still open, users may cancel their current-epoch deposit or withdraw intent through the normal cancellation functions, subject to the usual pause and policy checks.

### Why this is accepted, not mitigated on-chain

Closing an epoch requires a fresh TVL value for the active strategy, which may live on the parent chain or a child chain. The contracts deliberately do not compute or validate that cross-chain TVL on-chain. Instead, CRE is the trusted automation and reporting layer for epoch settlement, and `WorkflowRouter` is the narrow on-chain ingress point for CRE reports.

Adding an on-chain time-based auto-close is not sufficient because the vault still needs the TVL input. Adding a broad manual close path would either:

- require a privileged operator to provide the same trusted TVL value directly, increasing human operational authority; or
- duplicate the existing CRE report path with another privileged ingress surface.

The current design keeps the authority narrow: the router validates workflow metadata and selector allowlists, then calls only the configured vault. Liveness of that workflow is therefore an operational assumption, not a contract invariant.

### Operational mitigations

- Monitor missed CRE cron executions, failed workflow runs, Keystone Forwarder delivery failures, and `WorkflowRouter.onReport` reverts.
- Alert when `ParentVault.getEpochNonce()` has not advanced after the expected close window and the open epoch has nonzero activity.
- Ensure the deployed workflow metadata and selector allowlists include the `closeEpoch(uint256)` selector for the active workflow ID.
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

**Status:** Accepted — epoch batching prevents the flash-loan variant; residual unsolicited-donation risk is monitored operationally.

**Last reviewed:** 2026-07-08

**Component:** Strategy adapters (`AaveV3Adapter`, `AaveV4Adapter`, `CompoundV3Adapter`), active strategy `getTVL`, CRE epoch workflow, and `ParentVault.closeEpoch`.

### Summary

The strategy adapters report TVL from the active lending-market position:

- `CompoundV3Adapter` reads the adapter's Comet balance.
- `AaveV3Adapter` reads the adapter's aToken balance.
- `AaveV4Adapter` reads the adapter's supplied assets from the Aave v4 Spoke.

The supported lending protocols allow assets to be supplied on behalf of another account. A third party can therefore supply underlying asset directly into the market on behalf of the adapter, increasing the adapter's reported strategy balance without calling the vault's `donate()` function.

Because the CRE epoch workflow reads TVL from the active strategy chain's `getTVL()` and submits that value to `ParentVault.closeEpoch(tvl)`, unsolicited on-behalf-of supplies can be included in the epoch settlement TVL.

### Why this is accepted, not mitigated in adapter accounting

Yieldcoin v2 settles deposits and withdrawals through epochs, not through synchronous mint/redeem operations against live TVL:

- `deposit()` records a pending deposit for the open epoch but does not mint shares immediately.
- `withdraw()` records a pending withdraw intent and escrows shares but does not redeem immediately.
- `closeEpoch(tvl)` is restricted to the epoch operator path and is executed by the CRE workflow.
- Cross-chain strategy settlement is asynchronous and may require a second workflow step before claims become available.

This architecture prevents the standard single-transaction flash-loan donation attack. An attacker who supplies on behalf of the adapter cannot withdraw those supplied funds back from the lending market; control of the credited position belongs to the adapter. The attacker therefore cannot flash-borrow, inflate TVL, complete a profitable mint/redeem cycle, withdraw the supplied funds, and repay the flash loan in one transaction.

The robust on-chain mitigation would be for each adapter to track protocol position units attributable only to vault-originated deposits and value only those accounted units in `getTVL()`. For example, Aave v3 would track scaled aToken balance and value it through the reserve index, while Compound v3 would track accounted Comet principal/base units and convert them to present value.

That mitigation was deferred because it materially increases adapter accounting complexity and must preserve legitimate organic yield while excluding unsolicited credited balances. Incorrect implementation could introduce more serious yield-accounting or withdrawal bugs than the residual issue accepted here.

### Operational mitigation

The CRE/operator process should monitor active strategy TVL for unexpected jumps before submitting `closeEpoch(tvl)`, especially changes that cannot be explained by:

- pending epoch net deposits or withdrawals,
- expected strategy yield,
- completed rebalances,
- recovery state, or
- authorized `donate()` operations.

Unexpected TVL changes should be investigated before epoch close where operationally feasible.

### Residual risk

A third party can still use real capital to inflate the active adapter's raw protocol balance before CRE samples TVL. This can affect:

- the epoch price per share,
- shares minted to pending depositors,
- assets allocated to pending withdrawers,
- performance-fee and high-water-mark accounting, and
- rebalance or emergency paths that withdraw the adapter's full raw position.

An attacker with a pending withdrawal may recover a pro-rata portion of their own unsolicited supply through that epoch's withdrawal settlement. Any unrecovered amount is absorbed by other participants, remaining shareholders, or protocol fees. The attacker cannot atomically recover the full supplied amount unless they also control privileged workflow or vault execution paths, which is outside the permissionless threat model.

The accepted failure mode is settlement distortion funded by the attacker's own capital, not direct theft of protocol funds or a flash-loan-amplified insolvency path.

### Conditions that would warrant revisiting

- Evidence appears that unsolicited on-behalf-of supplies can be profitably extracted without privileged role compromise.
- CRE TVL monitoring is removed or becomes unable to detect abnormal strategy-balance jumps.
- A new adapter is registered whose `getTVL()` can be inflated and later deflated by the same third party.
- Rebalance or emergency-drain behavior changes such that unsolicited strategy balances are routinely swept into canonical accounting.
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
- the user remains exposed to the epoch's eventual settlement price; and
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

## KI-010 — Bootstrap price-per-share ignores residual TVL when total shares return to zero

**Status:** Accepted — bounded to dust-level amounts, consistent with the existing `donate()` bootstrap-pricing tradeoff, and further mitigated operationally by a permanent admin seed deposit.

**Last reviewed:** 2026-07-10

**Component:** `ParentVaultFeesLib._calculatePricePerShare`, `ParentVaultEpochLib.closeEpoch`.

### Summary

`_calculatePricePerShare` prices shares at par (`sharePrecision`) whenever `s_totalShares == 0`, regardless of `tvl`:

```solidity
uint256 totalShares = $.s_totalShares;
if (totalShares != 0 && tvl != 0) {
    pricePerShare = tvl * sharePrecision / totalShares;
    ...
} else if (totalShares == 0) {
    pricePerShare = sharePrecision;
```

`s_totalShares` can reach exactly zero through ordinary use: a full-supply exit, where the last holder's withdraw intent burns all outstanding shares in a `closeEpoch`. Nothing prevents this — `minDepositAmount` only floors new mints, not burns.

At the epoch closing a full exit, the withdraw amount pulled from the strategy is the epoch's computed `netWithdrawAmount` (derived from the operator-supplied `tvl` snapshot), not a "withdraw everything" call. If the strategy's actual balance drifts even slightly above that snapshot by execution time (e.g. interest accrued between the CRE workflow's off-chain TVL read and the on-chain `closeEpoch` transaction), a small residual is left behind in the adapter after `s_totalShares` hits zero.

The next epoch's depositor then mints shares at par against `_calculatePricePerShare`, which ignores that residual. Their shares end up backed by `residual + their own deposit`, so they receive the residual for free instead of it going to the exited shareholders.

This is the same root-cause pattern already called out on `donate()` (`BaseVault.sol`): *"First-depositor captures full donation when `s_totalShares == 0` due to bootstrap pricing ignoring existing TVL."* This entry extends that acknowledgment to the organic (non-`donate()`) case.

### Why this is accepted, not mitigated

- **Operationally, `s_totalShares` should never actually return to zero after the first epoch.** The deployer/admin makes an initial seed deposit as part of launch and does not redeem it. This is not enforced on-chain (there is no dead-shares burn or minimum-liquidity lock in the contracts) — it is a deployment-runbook practice, so the trigger condition requires both every other holder to exit *and* the admin to redeem the permanent seed position, which is not expected operational behavior.
- The residual is bounded to dust: the withdrawal amount is computed directly from a trusted, near-real-time operator TVL estimate, so any leftover is limited to accrual/rounding drift over a single transaction, not an arbitrary amount.
- Reaching the trigger condition requires total share supply to hit exactly zero, which (even setting the seed deposit aside) is a specific and infrequent state (a full protocol exit), not routine operation.
- Sweeping or reconciling the residual would require either tracking a per-reset "owed to exited holders" balance or an extra adapter call on the full-exit path — added accounting state and complexity to close a dust-sized gap, contrary to the project's simplicity priority.
- No other user's balance is diluted or put at risk; the effect is a one-time transfer of dust value to whichever depositor happens to open the next epoch after a full reset.

### Operational mitigation

- Deployer/admin makes a seed deposit at launch and does not redeem it, keeping `s_totalShares > 0` permanently in practice. This is a runbook practice, not a contract-enforced invariant — nothing prevents the admin from redeeming it.

### Residual risk

If the seed-deposit practice is not followed, or the admin's seed position is ever fully redeemed alongside all other holders, the next depositor after a full-supply reset can receive a small amount of value (bounded by inter-transaction yield accrual / rounding on the prior full exit) that arguably belonged to the exited shareholders. This does not affect protocol solvency, other users' balances, or any live position — it is a bounded, one-time bootstrap-pricing artifact, and under normal operation is not expected to be reachable at all.

### Conditions that would warrant revisiting

- The admin seed deposit is redeemed (removing the operational mitigation) and total shares can realistically return to zero.
- An adapter or strategy topology is introduced where the gap between the operator's TVL snapshot and actual on-chain execution can be large rather than dust-sized.
- Full-supply resets become a routine/expected operational pattern rather than an edge case.
- A cheap way to reconcile or sweep residual TVL at the zero-shares boundary becomes available without adding meaningful accounting complexity.
- The seed-deposit practice is formalized as a contract-enforced invariant (e.g. a permanent minimum-liquidity lock), at which point this entry could be closed rather than merely mitigated.

---
