# Operations

This runbook covers normal public operator responsibilities for Yieldcoin v2. Use placeholder addresses in public docs unless a deployment intentionally publishes real addresses.

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
- ACE policy wiring and provider availability.

## Epoch Operations

Epoch close is executed through Chainlink CRE and `WorkflowRouter`. Operators should verify the workflow is live, uses the intended configuration, and submits TVL only after checking relevant recovery and strategy state.

If an epoch remains executing, operators should identify whether it is waiting on child-chain execution, CCIP delivery, or stored recovery state.

## Rebalance Operations

Rebalances are executed through Chainlink CRE and `WorkflowRouter`. Operators should monitor the old active strategy, pending strategy, CCIP status for cross-chain moves, and completion events.

Do not treat rebalancing as a manual user action. Strategy selection and execution authority should follow the configured CRE and router path.

## Recovery Monitoring

Recovery is permissionless. Anyone can call recovery once the stored failed operation can succeed. Operators should still monitor recovery state because unresolved recovery can block normal progress or indicate external dependency failure.

Recovery callers must not choose arbitrary amounts, destinations, strategies, recipients, or calldata. Those values come from stored protocol state.

## Pauses And Escalation

Use pause controls according to role assignments in [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md). Escalate unusual states, external protocol failures, compromised keys, incorrect TVL, CCIP disruption, or ACE policy issues through [`INCIDENT_RESPONSE`](./INCIDENT_RESPONSE.md).

For exact protocol flows, see [`PATHS`](../protocol/PATHS.md). For accepted risks and liveness dependencies, see [`KNOWN_ISSUES`](../security/KNOWN_ISSUES.md).
