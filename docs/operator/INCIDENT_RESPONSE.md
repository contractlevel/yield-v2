# Incident Response

This public runbook defines the minimum response to a suspected protocol incident. The commercial operator must maintain a separate private contact register for approved signers, emergency responders, legal counsel, law enforcement, exchanges, underlying asset issuers, and infrastructure providers.

## 1. Assess

- Open an incident record and appoint an incident lead.
- Record the detection time, affected chains and contracts, observed transactions, balances, events, configuration, and recovery state.
- Determine whether the incident affects the protocol, an active strategy, an inactive strategy, a privileged key, or an external dependency.
- Treat uncertain impact as active until it is ruled out.

## 2. Contain

Where practicable, pause the CRE workflow before pausing affected vaults, WorkflowRouter or the share token. This prevents new automated writes while containment state is being established.

- Pause only the components necessary to contain the incident.
- Revoke or replace compromised roles and keys.
- Do not repeat cross-chain actions until their source transactions and CCIP message status have been reconciled.
- Do not use recovery functions unless the stored recovery state and original operation have been verified.
- Record every containment transaction and approval.

Use [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) for authority and [`OPERATIONS`](./OPERATIONS.md#paused-cross-chain-execution) for paused cross-chain handling.

## 3. Respond By Incident Type

### Protocol Compromise

Stop automation, pause affected contracts across all chains, protect remaining privileged access, and reconcile all assets and in-flight messages. Escalate immediately through the private contact register.

### Active-Strategy Incident

Stop epoch and rebalance automation, pause the affected vaults, and determine whether withdrawing or moving funds is safe. Do not initiate a rebalance until the destination and cross-chain path have been independently reviewed.

### Inactive-Strategy Incident

Disable the affected protocol and adapter from future use where safe. Confirm that it is not active, pending, referenced by recovery state, or involved in an in-flight operation before changing configuration.

### Privileged-Key Compromise

Stop automation controlled by the key, revoke its roles, rotate related credentials, and review every action authorized by it. If an admin or upgrader key is affected, escalate immediately to the commercial operator's authorized incident signers and replace the affected authority.

## 4. Preserve And Communicate

- Preserve transaction hashes, logs, configuration snapshots, alerts, relevant communications, and key-access records.
- Notify approved internal, legal, compliance, security, infrastructure, and counterparty contacts from the private register.
- Use a designated spokesperson for public updates. State confirmed facts, user impact, and current precautions without speculating or disclosing sensitive response details.
- Report suspected vulnerabilities according to [`SECURITY`](../SECURITY.md).

## 5. Recover

Resume only after the incident lead and required commercial-operator approvers confirm that the cause is understood, containment is effective, state is reconciled across chains, and recovery steps have been tested.

Restore components in a controlled order, monitor the first successful operations, and document all state changes. Afterward, complete a written review covering the cause, impact, response, control failures, and required follow-up work.
