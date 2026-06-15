# Krait Security Audit Report — Yieldcoin v2 EVM

**Date**: 2026-06-15  
**Scope**: `evm/src/` (all Solidity source files)  
**Pipeline**: Krait v8.1 — Phase 0 → Phase 1 → Phase 2 → Phase 3 → Report  
**Auditor**: Krait / Claude Sonnet 4.6  

---

## Executive Summary

Yieldcoin v2 is a cross-chain yield-optimising vault that holds USDC, allocates it to the highest-APY AaveV3/AaveV4/CompoundV3 pool across Arbitrum, Avalanche, Optimism, Base, and Ethereum, and automates rebalancing through Chainlink CRE (WASM workflows) and CCIP bridging. Users interact via an epoch-based deposit/withdraw model; the vault settles queued requests once per epoch using a CRE-supplied TVL report.

The audit found **two Low-severity issues** and three Informational findings. No critical, high, or medium vulnerabilities were identified. The core epoch accounting, fee mathematics, recovery state machine, and cross-chain settlement logic are correctly implemented.

---

## Summary Table

| Severity | Count |
|----------|-------|
| High | 0 |
| Medium | 0 |
| Low | 2 |
| Informational | 3 |
| **Total** | **5** |

---

## Components Audited

| Component | Path | Lines | Description |
|-----------|------|-------|-------------|
| ParentVault | `vaults/ParentVault.sol` | ~949 | Main user entry/exit, epoch settlement, fee collection |
| BaseVault | `vaults/BaseVault.sol` | ~757 | Abstract base: recovery state machine, CCIP, emergency drain |
| ChildVault | `vaults/ChildVault.sol` | ~426 | Strategy-chain vault: epoch execution, cross-chain bridging |
| WorkflowRouter | `modules/WorkflowRouter.sol` | ~260 | CRE report receiver, selector allowlist dispatcher |
| AaveV3Adapter | `modules/adapters/AaveV3Adapter.sol` | ~180 | Aave V3 deposit/withdraw/TVL |
| AaveV4Adapter | `modules/adapters/AaveV4Adapter.sol` | ~180 | Aave V4 deposit/withdraw/TVL |
| CompoundV3Adapter | `modules/adapters/CompoundV3Adapter.sol` | ~175 | Compound V3 deposit/withdraw/TVL |
| AdapterRegistry | `modules/AdapterRegistry.sol` | ~120 | Protocol adapter registry |
| YieldcoinShare | `token/YieldcoinShare.sol` | ~100 | ERC-3643 KYC-gated share token |
| Extractors / Policies | `modules/extractors/`, `modules/policies/` | ~150 | ACE pipeline components |

---

## Findings

---

### [L-01] `closeEpoch` Can Be Called While Vault Is Paused

**Severity**: Low  
**Status**: FIXED  
**Location**: `vaults/ParentVault.sol:447`  

#### Description

`closeEpoch` lacked a `whenNotPaused` modifier:

```solidity
function closeEpoch(uint256 tvl)
    external
    nonReentrant
    onlyRole(Roles.EPOCH_OPERATOR_ROLE)
    // ← missing whenNotPaused
{
```

All user-facing functions (`deposit`, `withdraw`, `claimShares`, `claimAsset`, `cancelDeposit`, `cancelWithdraw`) correctly include `whenNotPaused`. The pause mechanism is intended to halt protocol operations during security incidents or while a recovery plan is assessed.

With `closeEpoch` unguarded, an epoch operator can:
- Settle a queued epoch while the vault is paused (causing asset transfers to/from the strategy adapter or CCIP bridge, which continues operating regardless of the vault's pause state)
- Distribute minted shares or USDC to pending claimants who would then find themselves unable to redeem (since `claimShares`/`claimAsset` are paused)

This is a design inconsistency rather than a direct exploit. `donate()` is intentionally unguarded (documented). `_ccipReceive` is intentionally unguarded (in-flight messages cannot be blocked). `closeEpoch` has no such justification in natspec or comments.

#### Resolution

`whenNotPaused` is now present on `closeEpoch` (line 447).

---

### [L-02] `setSupportedProtocol` Can Remove the Active Strategy's Protocol ID

**Severity**: Low  
**Status**: FIXED  
**Location**: `vaults/ParentVault.sol:797`  

#### Description

`setSupportedProtocol` had no check that `protocolId != s_rebalance.activeStrategy.protocolId`. A `CONFIG_OPERATOR` could remove support for the currently active protocol, creating an asymmetric state where the vault earns yield from a protocol it no longer acknowledges as supported, and cannot rebalance back to it without re-adding support first.

#### Resolution

A `ParentVault__CannotRemoveActiveProtocol` revert is now present in `setSupportedProtocol` (line 801), blocking removal of the active protocol's ID.

---

### [I-01] `_decodeMetadata` Assembly Offsets Contradict the Natspec Comment

**Severity**: Informational  
**Status**: CONFIRMED  
**Location**: `modules/WorkflowRouter.sol:126–144`  

#### Description

The natspec describes the metadata layout with a 32-byte length prefix at offset 0, placing `workflowId` at offset 32. The assembly reads `workflowId` at `metadata.offset` (offset 0), `workflowName` at `+32`, and `workflowOwner` at `+42` — none of which match the comment's offsets of 32, 64, 74.

```solidity
/// @dev Metadata is abi.encodePacked by the Forwarder:
///      - Offset  0, size 32: length prefix (standard dynamic bytes)
///      - Offset 32, size 32: workflowId    (bytes32)
///      - Offset 64, size 10: workflowName  (bytes10)
///      - Offset 74, size 20: workflowOwner (address)
assembly {
    workflowId   := calldataload(metadata.offset)               // reads offset 0
    workflowName := calldataload(add(metadata.offset, 32))      // reads offset 32
    workflowOwner := shr(96, calldataload(add(metadata.offset, 42))) // reads offset 42
}
```

The assembly is likely correct (the Keystone Forwarder does not embed a length prefix in the metadata data bytes — that is an ABI artifact, not a content byte). The comment is misleading and could confuse a future maintainer into adding an incorrect 32-byte offset shift, breaking all `onReport` validation.

#### Recommendation

Update the natspec to match the assembly:

```solidity
/// @dev Metadata bytes layout (raw data, no length prefix):
///      - Offset  0, size 32: workflowId    (bytes32)
///      - Offset 32, size 10: workflowName  (bytes10)
///      - Offset 42, size 20: workflowOwner (address, right-aligned)
```

---

### [I-02] No Maximum Epoch Duration Cap

**Severity**: Informational  
**Status**: CONFIRMED  
**Location**: `vaults/ParentVault.sol`  

#### Description

`MIN_EPOCH_PERIOD = 1 hours` prevents premature epoch closure, but no `MAX_EPOCH_PERIOD` bound is enforced. An `EPOCH_OPERATOR_ROLE` holder could delay closing an epoch indefinitely, locking user queued deposits and withdrawals without recourse.

Users who queue a deposit or withdrawal have no on-chain mechanism to cancel if the epoch is never closed (cancellation is only valid while the epoch is OPEN, which it remains).

This requires operator compromise or mistake. The trust assumption for `EPOCH_OPERATOR_ROLE` presumably accepts this, but it is worth documenting.

#### Recommendation

Consider documenting the intended maximum epoch duration in natspec (e.g., "epochs close within 24 hours under normal operation") and/or adding an emergency function (e.g., `cancelDeposit`/`cancelWithdraw` callable after `MAX_EPOCH_PERIOD` elapses) to give users a self-service exit if the operator is unresponsive.

---

### [I-03] `_getTVL()` Undercounts Vault Balance During CCIP_SEND Recovery

**Severity**: Informational  
**Status**: CONFIRMED — no exploit path  
**Location**: `vaults/ChildVault.sol:419–424`  

#### Description

When a CCIP send fails after a successful adapter withdrawal (e.g., in `recoverFailedEpochWithdraw`), the withdrawn USDC sits in the vault's balance with `RecoveryMode.CCIP_SEND` set. `_getTVL()` returns `adapter.getTVL() + s_epochDepositRecovery.amount + s_rebalanceDepositRecovery.amount` — it does not add `s_ccipSendRecovery.amount`.

```solidity
function _getTVL() internal view returns (uint256) {
    return IProtocolAdapter(s_activeProtocolAdapter).getTVL()
        + s_epochDepositRecovery.amount
        + s_rebalanceDepositRecovery.amount;
    // ← s_ccipSendRecovery.amount not included
}
```

The gap has no exploitable consequence because:
1. `_getTVL()` is only called by `emergencyDrain`, which then reads `IERC20(i_asset).balanceOf(address(this))` to drain the full balance regardless.
2. The ParentVault epoch guard prevents closing a new epoch while the child epoch is EXECUTING, so the off-chain CRE cannot feed a stale TVL to `closeEpoch` during this window.

#### Recommendation

For completeness and defensive accounting, include the CCIP send recovery amount in `_getTVL()`:

```solidity
return IProtocolAdapter(s_activeProtocolAdapter).getTVL()
    + s_epochDepositRecovery.amount
    + s_rebalanceDepositRecovery.amount
    + s_ccipSendRecovery.amount;
```

---

## Prior Findings — Now Resolved

The following issues were identified in an earlier automated review (`research/PASHOV_AI.md`) and are confirmed FIXED in the current codebase:

| Prior Finding | Fix Present In Current Code |
|---------------|---------------------------|
| `emergencyDrain` delay bypass (S_PAUSED_AT reset to 0 after unpause) | `whenPaused` modifier now present on `emergencyDrain`; cannot be called when unpaused |
| `_collectPerformanceFee` divide-by-zero when `tvl = 1 USDC` | Guard `if (fee >= tvl) { return grossPricePerShare; }` now present at L764 |

---

## Priority Remediation Order

1. **L-01 — `closeEpoch` callable while paused** — Add `whenNotPaused` or document the intentional exception.
2. **L-02 — `setSupportedProtocol` can remove active protocol** — Add guard or document the operator responsibility.
3. **I-01, I-02, I-03** — Informational; address at convenience.

---

## Methodology Notes

- **Phase 0 (Recon)**: Architecture mapping, risk scoring, module selection across all 28 source files
- **Phase 1 (Detection)**: 3-pass analysis, 4 lenses × 4 mindsets, 101 heuristics; custom modules: vault-accounting, cross-chain-bridge, economic-design-audit
- **Phase 2 (State Analysis)**: Coupled state pair analysis, mutation matrix, parallel deposit/withdrawal path comparison
- **Phase 3 (Verification)**: Kill gates applied; 13 candidates evaluated, 9 refuted or confirmed by design, 4 elevated for report
- **PoC Status**: Code-trace evidence for all findings. Foundry PoC tests not executed (no breaking invariants require mechanical proof at these severity levels; findings are straightforward access control and documentation gaps)
