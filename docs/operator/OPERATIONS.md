# Operations

This runbook covers normal public operator responsibilities for Yieldcoin v2. Use placeholder addresses in public docs unless a deployment intentionally publishes real addresses.

Potential post-MVP work is tracked separately in the [`ROADMAP`](../protocol/ROADMAP.md).

// @review seal 911/usmans msig series - https://x.com/0xusmanf/status/2078584503350776182

## Routine Monitoring

Operators should monitor:

- current parent epoch status;
- whether the previous epoch is still executing;
- active and pending strategy state;
- rebalance state;
- recovery state on parent and child vaults;
- WorkflowRouter configuration and pause state;
- CRE workflow execution status;
- CCIP message status and LINK balances;
- adapter registration and active strategy TVL;

## CRE Service Quotas

The workflow registers EVM log triggers for the parent vault and every configured child vault. Under the standard [CRE service quota of five EVM log-trigger contracts](https://docs.chain.link/cre/service-quotas#evm-log-trigger), the protocol can therefore monitor at most five vaults across five networks.

Before adding a network, the commercial operator must:

1. Count every parent and child vault registered as an EVM log source.
2. Confirm that the resulting workflow remains within the current CRE service quota.
3. If necessary, arrange a limit increase with Chainlink Labs before updating or deploying the workflow.
4. Simulate and verify the updated workflow configuration before production activation.

The technical trigger mapping is documented in [`WORKFLOW`](../protocol/WORKFLOW.md#triggers-and-handlers).

## Epoch Operations

Epoch close is executed through Chainlink CRE and `WorkflowRouter`. Operators should verify the workflow is live, uses the intended configuration, and reads the current parent epoch nonce before submitting `closeEpoch(expectedEpochNonce, tvl)`.

The epoch cron handler does not currently check recovery state before submitting TVL — see `ENV-001` in [`INVARIANTS`](../security/INVARIANTS.md). Until that check is added to the workflow, operators should manually confirm no recovery is pending on the active strategy's vault before an epoch close is expected to run.

If an epoch remains executing, operators should identify whether it is waiting on child-chain execution, CCIP delivery, or stored recovery state.

## Rebalance Operations

Rebalances are executed through Chainlink CRE and `WorkflowRouter`. Operators should monitor the old active strategy, pending strategy, current rebalance nonce, CCIP status for cross-chain moves, and completion events. Rebalance initiation and completion reports must include the current nonce read from `ParentVault.getRebalance()`.

Do not treat rebalancing as a manual user action. Strategy selection and execution authority should follow the configured CRE and router path.

## Recovery Monitoring

Recovery is permissionless. Anyone can call recovery once the stored failed operation can succeed. Operators should still monitor recovery state because unresolved recovery can block normal progress or indicate external dependency failure.

Recovery callers must not choose arbitrary amounts, destinations, strategies, recipients, or calldata. Those values come from stored protocol state.

## Pauses And Escalation

Use pause controls according to role assignments in [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md). Escalate unusual states, external protocol failures, compromised keys, incorrect TVL, or CCIP disruption through [`INCIDENT_RESPONSE`](./INCIDENT_RESPONSE.md).

## Paused Cross-Chain Execution

Pausing a vault blocks recovery, child epoch withdrawals, child rebalances, inbound CCIP processing, and ParentVault completion calls. An epoch or rebalance may therefore remain in progress across chains, including after the destination action succeeded, until operators deliberately resume or finalize it.

Before temporarily unpausing a vault, pause the normal `WorkflowRouter` or revoke its operational role on that vault. Record the relevant transactions, events, recovery modes, adapter state, balances, and CCIP message IDs. Determine whether execution stopped before the source-chain call, during stored recovery, after a CCIP send, or during destination execution. Never repeat a source-chain action unless its transaction and CCIP message status show that it was not successfully executed.

### Parent Paused Before Completion

1. For `completeEpochDeposit(expectedEpochNonce)`, read `ParentVault.getEpochNonce()`, set `expectedEpochNonce` to that current nonce minus one, require that epoch to remain `EXECUTING` and net-positive, then verify the canonical destination ChildVault emitted `EpochDepositToStrategySuccess` for that epoch and that no relevant recovery remains outstanding.
2. For `completeRebalance(expectedRebalanceNonce)`, read `ParentVault.getRebalance()`, set `expectedRebalanceNonce` to its current nonce, require the rebalance to remain `REBALANCING`, verify its pending strategy, and confirm the complete rebalance amount reached and was deposited into that strategy with no source withdrawal, CCIP delivery, target deposit, or relevant recovery outstanding.
3. Keep the normal `WorkflowRouter` paused or unauthorized while performing reconciliation. Grant the appropriate completion role temporarily to an approved break-glass executor if the existing role assignment cannot be used safely.
4. Unpause ParentVault, call only the reconciled `completeEpochDeposit(expectedEpochNonce)` or `completeRebalance(expectedRebalanceNonce)` function with the state-derived nonce, and verify the expected `EpochClaimable` or `RebalanceCompleted` event and resulting state.
5. Re-pause ParentVault if containment remains necessary, revoke temporary authority, and restore automation only after the full cross-chain state is reconciled and approved.

### Child Paused Before Rebalance Execution

1. Read `ParentVault.getRebalance()` and require `state == REBALANCING`.
2. Confirm `activeStrategy.chainSelector` identifies the paused child and verify the pending strategy, adapters, destination vault, and CCIP route are safe.
3. Use the exact `nonce` and `pendingStrategy` returned by the parent. The child cannot validate these arguments against parent state, so the calldata must be independently reviewed.
4. Grant `REBALANCE_OPERATOR_ROLE` temporarily to the approved break-glass executor while the normal router remains paused or unauthorized.
5. Unpause only the affected child and call `executeRebalance(nonce, pendingStrategy)`.
6. Record whether execution succeeded or stored rebalance-withdraw, rebalance-deposit, or CCIP-send recovery. Track any emitted CCIP message before taking another action.
7. Re-pause the child if containment remains necessary, revoke the temporary role, and restore automation only after state reconciliation and approval.

### Child Paused Before Epoch Withdraw Execution

1. Identify the canonical `EpochWithdrawExecuting(epochNonce, amount)` event emitted by the parent.
2. Confirm the parent epoch is still `EXECUTING`, the paused child holds the active strategy, and the child execution or resulting CCIP message has not already succeeded.
3. Use the exact `epochNonce` and `amount` from the event; do not recalculate the amount manually.
4. Grant `EPOCH_OPERATOR_ROLE` temporarily to the approved break-glass executor while the normal router remains paused or unauthorized.
5. Unpause only the affected child and call `executeEpochWithdraw(epochNonce, amount)`.
6. Record whether execution succeeded or stored epoch-withdraw or CCIP-send recovery, and track any emitted CCIP message until the parent settles the epoch.
7. Re-pause the child if necessary, revoke the temporary role, and restore automation only after state reconciliation and approval.

### Destination Paused During CCIP Delivery

When destination execution reverts because the vault is paused, validate and manually execute the CCIP message after the destination is unpaused. Verify its source chain, sender, token, amount, transaction type, nonce, and protocol ID. Do not repeat the originating withdrawal or rebalance call. Confirm the destination vault and recovery state before restoring automation.

For exact protocol flows, see [`PATHS`](../protocol/PATHS.md). For accepted risks and liveness dependencies, see [`KNOWN_ISSUES`](../security/KNOWN_ISSUES.md).
