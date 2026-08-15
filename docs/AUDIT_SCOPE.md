# Audit Scope

## In Scope

Only the Solidity source files in [`evm/src/`](../evm/src/) are in scope for this audit.

## Out of Scope

Everything outside `evm/src/` is out of scope, including:

- `cre/`
- `services/`
- `evm/test/`
- `evm/script/`
- documentation, deployment configuration, and external dependencies

Out-of-scope files may be referenced for context, but they are not authoritative descriptions of
the in-scope contracts. If any out-of-scope material conflicts with `evm/src/`, the implementation
in `evm/src/` is authoritative.

## CRE Notice

The implementation in `cre/` is outdated relative to the current EVM contracts. It may be used only
to understand the protocol's general architecture and intended off-chain coordination. It must not
be relied on for exact calldata, interfaces, selectors, events, state transitions, validation,
sequencing, or other implementation details of the current contracts.
