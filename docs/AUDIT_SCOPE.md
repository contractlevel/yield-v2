# Audit Scope

## In Scope

Only the Solidity source files in [`evm/src/`](../evm/src/) are in scope for this audit.

Auditors should review the following documents as part of the audit context:

- [`security/KNOWN_ISSUES.md`](./security/KNOWN_ISSUES.md) lists known and accepted issues.
- [`protocol/DECISIONS.md`](./protocol/DECISIONS.md) records intentional design decisions and
  tradeoffs.
- [`protocol/GAS.md`](./protocol/GAS.md) records known and accepted gas inefficiencies.

Behavior already disclosed and accepted in those documents should not be reported as a new finding
solely because that documented behavior exists. Issues arising from a distinct root cause remain in
scope for review.

## Out of Scope

Everything outside `evm/src/` is out of scope, including:

- `cre/`
- `services/`
- `evm/test/`
- `evm/script/`
- documentation, deployment configuration, and external dependencies

Out-of-scope files may be referenced for context, but they do not expand the code audit scope beyond
`evm/src/`. The contracts in `evm/src/` define the implemented behavior. `KNOWN_ISSUES.md`,
`DECISIONS.md`, and `GAS.md` document the team's intended behavior, accepted risks, design
rationale, and accepted gas inefficiencies. Any inconsistency between those documents and
`evm/src/` should be raised for clarification.

## CRE Notice

The implementation in `cre/` is outdated relative to the current EVM contracts. It may be used only
to understand the protocol's general architecture and intended off-chain coordination. It must not
be relied on for exact calldata, interfaces, selectors, events, state transitions, validation,
sequencing, or other implementation details of the current contracts.
