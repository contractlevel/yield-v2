# Yieldcoin v2 Documentation

Yieldcoin v2 is a multichain, compliance-gated yield vault. Users interact with `ParentVault` on the parent chain. Chainlink CRE drives epoch settlement, rebalancing, and cross-chain coordination. CCIP is used when funds move across chains; message-only cross-chain coordination is handled by events and CRE log-triggered writes. ACE gates user access and share-token behavior.

This documentation is public. The codebase is under active development, has no live deployments, and does not currently have a bug bounty program.

## Start Here

| Reader | Start with | Purpose |
| --- | --- | --- |
| Auditors and security reviewers | [`protocol/ARCHITECTURE`](./protocol/ARCHITECTURE.md), [`security/THREAT_MODEL`](./security/THREAT_MODEL.md), [`security/INVARIANTS`](./security/INVARIANTS.md), [`security/ACCESS_CONTROL_MATRIX`](./security/ACCESS_CONTROL_MATRIX.md), [`security/KNOWN_ISSUES`](./security/KNOWN_ISSUES.md), [`protocol/PATHS`](./protocol/PATHS.md), [`protocol/DECISIONS`](./protocol/DECISIONS.md) | Understand system shape, authority, assumptions, safety claims, accepted limitations, exact flows, and design rationale. |
| Users | [`USER_GUIDE`](./USER_GUIDE.md) | Understand direct `ParentVault` interactions and KYC-gated user flows. |
| Operators | [`operator/DEPLOYMENT`](./operator/DEPLOYMENT.md), [`operator/OPERATIONS`](./operator/OPERATIONS.md), [`operator/COMPLIANCE`](./operator/COMPLIANCE.md), [`operator/INCIDENT_RESPONSE`](./operator/INCIDENT_RESPONSE.md), [`operator/UPGRADES`](./operator/UPGRADES.md) | Deploy, configure, monitor, and operate the protocol. |
| Contributors and testers | [`test/EVM`](./test/EVM.md), [`test/CRE`](./test/CRE.md), [`test/SERVICES`](./test/SERVICES.md) | Run local checks, fuzzing, formal verification, workflow tests, and service tests. |

## Documentation Ownership

These docs intentionally avoid duplicating canonical details across multiple files.

| Document | Owns |
| --- | --- |
| [`protocol/ARCHITECTURE`](./protocol/ARCHITECTURE.md) | System components, relationships, and lifecycle overview. |
| [`protocol/PATHS`](./protocol/PATHS.md) | Canonical epoch and rebalance execution paths. |
| [`protocol/DECISIONS`](./protocol/DECISIONS.md) | Design rationale and intentional tradeoffs. |
| [`security/THREAT_MODEL`](./security/THREAT_MODEL.md) | Trust boundaries, threat surfaces, and controls. |
| [`security/ACCESS_CONTROL_MATRIX`](./security/ACCESS_CONTROL_MATRIX.md) | Role meanings, authorities, and privileged entry points. |
| [`security/INVARIANTS`](./security/INVARIANTS.md) | Safety properties and verification status. |
| [`security/KNOWN_ISSUES`](./security/KNOWN_ISSUES.md) | Accepted limitations, deferred risks, and revisit conditions. |
| [`concepts/`](./concepts/) | Human-readable explanations of major protocol mechanisms. |
| [`operator/`](./operator/) | Deployment, operations, compliance, incident, and upgrade runbooks. |

## Concepts

Concept docs explain how the protocol works without replacing the canonical execution matrix or security catalogue.

- [`concepts/EPOCH`](./concepts/EPOCH.md) — epoch lifecycle, batched settlement, claims, and user-visible timing.
- [`concepts/REBALANCE`](./concepts/REBALANCE.md) — strategy migration, active and pending strategies, and CRE-driven rebalancing.
- [`concepts/RECOVERY`](./concepts/RECOVERY.md) — permissionless stored-state recovery and why there is no recovery operator role.
- [`concepts/YIELDCOIN_SHARE`](./concepts/YIELDCOIN_SHARE.md) — share accounting, ACE policy checks, RBAC-gated token functions, KYC transfer checks, freezes, forced transfers, and CCIP admin behavior.

## Security Reporting

Please report suspected vulnerabilities to `contractlevel@proton.me`. Do not disclose suspected issues publicly until the team has had a reasonable opportunity to investigate and respond.

See [`SECURITY`](./SECURITY.md) for reporting details.

## Documentation Conventions

- Keep security docs direct about trust assumptions and accepted limitations.
- Link to canonical docs instead of repeating exact path, invariant, or role details.
- Use role names from [`security/ACCESS_CONTROL_MATRIX`](./security/ACCESS_CONTROL_MATRIX.md) and `src/libraries/Roles.sol`.
- Use placeholder addresses in public operator docs unless real deployment addresses are intentionally published.
