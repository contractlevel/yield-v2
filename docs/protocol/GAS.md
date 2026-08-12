# Gas Optimization

## Purpose

This document tracks known, deliberately-accepted gas inefficiencies in the Yieldcoin v2 contracts - redundant SLOADs, redundant SSTOREs, or redundant validation checks that were identified but left unchanged. Each entry explains what the inefficiency is and why it is being accepted rather than removed.

This is not a list of open findings to fix. Entries here are judged tradeoffs: removing them would trade away a safety margin, add meaningful new code-path surface area, or duplicate logic across shared functions, for comparatively little gas.

## GAS-001 - Duplicate rebalance-state check on the CCIP-receive path

`ParentVaultCcipLib._validateRebalance` checks `s_rebalance.state == REBALANCING`, and `ParentVaultRebalanceLib._finalizeRebalance` checks the same field again moments later, on the `_ccipReceive` rebalance-complete path specifically.

`_finalizeRebalance` needs to stay safe to call standalone from each of its entrypoints. Splitting it into checked/unchecked variants adds surface area for one warm SLOAD (~100 gas). A checked/unchecked split already exists on this same function for the synchronous local-to-local rebalance path, but that split conflates "skip the check" with "skip the `state`/`pendingStrategy` reset writes" (both true only for that case). The CCIP-receive path needs the opposite combination: skip the check, but still perform the writes, since they are genuinely needed there. Reusing the existing flag isn't possible; a fix would need a third distinct code path. Not worth it for ~100 gas on this path.

## GAS-002 - Duplicate CCIP-send validation in `ChildVault._ccipSend`

`_ccipSend` validates parameters directly, then invokes `tryCcipSend` (an external self-call for try/catch), which validates again internally inside `_send`.

This is deliberate, not accidental. Validating before the try/catch boundary means a configuration error (bad destination chain, zero amount) reverts the whole transaction atomically. If validation only happened inside the try block, the catch clause would treat a configuration bug the same as a genuine CCIP send failure and store it as recovery state - silently masking the bug behind a retry flow instead of surfacing it immediately.

## GAS-003 - Duplicate crosschain-vault lookup in remote rebalance initiation

`ParentVault.initiateRebalance` checks that the destination chain is a registered crosschain vault, then, on the remote-withdraw branch, `_ccipSend` resolves the same mapping key again to build the CCIP message.

Not a pure duplicate check: the second lookup also returns the vault address needed for the message, not just a boolean. A real fix means a second variant of the CCIP-send validation/send functions that accepts a pre-known vault address, since every other CCIP-send call site (child sends, epoch withdraws, recovery paths) doesn't have the address pre-known and still needs the full lookup. A new code path in a widely-shared library for ~100 gas on a rare path (remote-chain rebalance initiation only) isn't a good trade.

## GAS-004 - Zero-adapter check in `_executeDeposit`/`_executeWithdraw`

Both functions check their `activeAdapter` parameter for the zero address before proceeding. At several call sites this is provably redundant, since the caller already proved the adapter non-zero moments earlier (via `_setActiveAdapter`, which reverts on an unregistered protocol, or via a locally-computed boolean derived from the same storage read).

Unlike everything else on this page, this isn't a storage read - the adapter address is already a function parameter sitting in memory, so the check is a cheap comparison (roughly 10-15 gas), not a ~100 gas warm SLOAD. Splitting the shared helper into checked/unchecked variants isn't worth the surface area for single-digit gas.
