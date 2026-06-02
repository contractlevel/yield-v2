# Known Issues

This document records security-relevant issues that are known to the protocol team and have been explicitly accepted, deferred, or judged to be outside the trust boundary of the system. Each entry describes the issue, why it is not being mitigated in code (or is only partially mitigated), and the operational or design assumptions that bound its impact.

Entries here are intentionally **not assigned a severity rating** — they are accepted properties of the system, not open findings.

IDs are intended to remain stable after this revision. This PR introduces an initial restructuring of KI numbering into the current KI-001..KI-004 sequence.

---

## KI-001 — Centralized trust in privileged operator/admin roles

**Status:** Accepted.
**Last reviewed:** 2026-06-02
**Component:** Access control across vaults, router, registry, token, and PolicyEngine.
**Applies to:** ParentVault, ChildVault, WorkflowRouter, AdapterRegistry, YieldcoinShare, and PolicyEngine-governed ACE policy administration.

### Summary

Yieldcoin v2 relies on multiple privileged roles for governance and operations. Human-held privileged roles include:

- **`DEFAULT_ADMIN_ROLE`** for local role administration (grant/revoke and admin-transfer acceptance via `AccessControlDefaultAdminRules`).
- **`CONFIG_OPERATOR_ROLE`** for protocol configuration (vault/router/registry settings, adapter registration, treasury/emergency receiver, workflow metadata/selectors, token metadata/CCIP admin wiring).
- **`PAUSER_ROLE` / `UNPAUSER_ROLE`** for pause controls across vaults, WorkflowRouter, and YieldcoinShare.
- **`EMERGENCY_DRAINER_ROLE`** for paused-mode emergency USDC drain (subject to delay guards).
- **`LINK_OPERATOR_ROLE`** for LINK withdrawal from vaults.
- **`POLICY_ENGINE_MANAGER_ROLE`** for replacing attached policy engines on policy-protected contracts.
- **`COMPLIANCE_OPERATOR_ROLE`** for forced transfer and freeze/unfreeze functions on YieldcoinShare.
- **PolicyEngine `ADMIN_ROLE` / `POLICY_CONFIG_ADMIN_ROLE`** for policy wiring and policy configuration.

The system also includes contract-held or infrastructure roles such as `KEYSTONE_FORWARDER_ROLE` (CRE report ingress) and token `MINTER_ROLE`/`BURNER_ROLE` held by ParentVault.

### Threat model

A compromised or malicious signer controlling a privileged role can take adverse actions within that role's authorized scope (for example, misconfiguration, service interruption, policy rewiring, compliance actions, or emergency operations).

### Mitigations

- Split privileged responsibilities across distinct role addresses so no single key controls multiple critical functions.
- Hold each human-operated privileged role behind a multisig.
- Use Cyfrin-qualified signers for privileged multisigs.

### Residual risk

This design still depends on trusted operators and governance signers acting correctly. The risk is accepted as an operational trust assumption and reviewed alongside role assignments and signer hygiene.

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

The protocol team accepts issuer risk as the cost of denominating vaults in widely-used regulated stablecoins. Vault selection and underlying-asset choice are governance / product decisions, not security bugs.

### Operational assumptions

- Issuer action against a legitimate protocol address is treated as an external incident, handled through off-chain communication with the issuer, not through on-chain mitigations.
- Users are informed (via product documentation and disclosures) that withdrawals depend on the continued transferability of the underlying asset.
- Future vaults using underlyings with similar issuer powers (e.g., other regulated stablecoins) inherit this same accepted risk; vaults whose underlying has no such powers do not.

---

## KI-003 — Dust withdraw intents can round down to a zero-USDC claim

**Status:** Accepted — integer-floor pro-rata settlement in `claimUsdc`; documented for user awareness.
**Last reviewed:** 2026-06-01
**Component:** Yieldcoin v2 vault withdraw lifecycle (`withdraw` / `claimUsdc` in `ParentVault`)

### Summary

Withdraw claims are settled pro-rata per epoch in `claimUsdc(epochNonce)`. For non-final claimants, the amount is calculated as:

`usdcWithdrawAmount = shareBurnAmount * epoch.remainingWithdrawClaimAmount / epoch.remainingShareBurnAmount`

Because this is integer division, it rounds down. For very small `shareBurnAmount`, `usdcWithdrawAmount` can be zero even though shares are burned. In that case, the withdraw intent is deleted and `IShare(i_share).burn(address(this), shareBurnAmount)` still executes, while the USDC transfer is skipped by `if (usdcWithdrawAmount != 0)`.

### Why this is accepted

- This is expected behavior of integer-floor pro-rata accounting and prevents over-distribution of USDC across claimants.
- The final-claimant branch (`shareBurnAmount == epoch.remainingShareBurnAmount`) assigns the entire remainder to the last claim, preserving epoch-level conservation.
- Adding an on-chain non-zero minimum payout check would either reject otherwise-valid proportional claims or add complexity/gas overhead for an uneconomic dust edge case.
- The economically rational user action is to avoid submitting tiny withdraw intents whose expected claim is zero.

### User-facing mitigation

- Users interacting directly should avoid dust-sized withdraw intents

### Residual risk

- A user who submits and claims a dust-sized withdraw intent can burn shares and receive zero USDC for that claim. This loss is self-inflicted and bounded by the dust amount; it does not affect protocol solvency or other users' balances.

---

## KI-004 — Residual CPU/memory DoS surface in `defillama-relay` JSON deserialization

**Status:** Accepted — mitigated but not eliminated.
**Last reviewed:** 2026-06-02
**Component:** `services/defillama-relay` (`src/lib.rs`, `read_upstream_json` → `serde_json::from_slice::<DefiLlamaResponse>`).
**Threat model:** DefiLlama compromise, TLS-terminating/MITM compromise, or misconfiguration of DEFILLAMA_UPSTREAM_URL to an attacker-controlled endpoint.

### Summary

The relay fetches DefiLlama's pool list, enforces a hard byte cap while streaming the response body, and then deserializes the entire body in one shot via `serde_json::from_slice` into a `DefiLlamaResponse { data: Vec<Pool> }`. Filtering, allowlisting, and field bounding all happen **after** deserialization.

This means a malicious upstream response that is well-formed JSON and within the byte cap is still parsed in full before any per-pool limits apply. An attacker controlling the upstream response can therefore force the Worker to:

- Tokenize up to the full byte cap of JSON, and
- Allocate a `Vec<Pool>` and associated `String` fields proportional to that size,

within the Worker's CPU and memory budget for the request.

### Mitigations already in place

1. **Hard upstream byte cap.** `MAX_UPSTREAM_BYTES` is set to **12 MiB**, enforced by `read_upstream_body` via chunked reads. `Content-Length` is used as a cheap early reject; the streamed-read enforcement is authoritative and handles chunked / lying upstream responses.
2. **Per-field byte bounds applied post-parse.** Pool IDs are length-bounded by canonical_pool_id; returned metadata fields chain, project, and symbol are trimmed and length-bounded by bounded_field.
3. **Per-response pool cap applied post-parse.** Filtered output is capped at `MAX_RELAY_POOLS`, so even a maximally large upstream cannot push an unbounded list downstream.
4. **Non-finite numeric rejection.** Pools with non-finite `apyBase` are dropped.
5. **Allowlist filtering.** Only pools whose IDs are in the configured allowlist are returned to CRE; unknown pool IDs are discarded.

The byte cap reduces parser exposure. The post-parse checks bound the CRE-facing output and downstream relay work after deserialization succeeds.

### Residual risk

The mitigations bound **output size and shape**, but the deserialization step itself still runs over up to 12 MiB of attacker-influenced JSON before any of them apply. Practical residual effects, if a hostile upstream response is delivered:

- Elevated CPU and memory for that single request.
- Possible Worker resource-limit termination or relay error, producing a 502/504 or platform-level failure to CRE.
- CRE's rebalance simulation / execution for that cycle fails or stalls until the next successful fetch.

The failure mode is **denial of service for the affected request only**:

- No funds are at risk — the relay holds no assets and signs no transactions.
- No secrets are exposed — the relay has no privileged credentials beyond the outbound fetch.
- No on-chain state is written — the relay is read-only from CRE's perspective.
- Accounting and on-chain protocol state are unaffected; only the data feed is degraded.

### Why this is accepted, not further mitigated

Eliminating the residual would require one of:

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
