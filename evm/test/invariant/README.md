# Yieldcoin V2 Invariant Tests

The initial Chimera suite lives in `test/invariant/epoch` and focuses on epoch lifecycle coverage. Shared helpers live in `test/invariant/shared` only when they are expected to be reused by future suites such as rebalance.

## Commands

- Foundry setup/debug: `forge test --match-contract CryticToFoundry -vv`
- Foundry invariants: `FOUNDRY_PROFILE=invariants forge test --match-contract CryticToFoundry -vv`
- Medusa: `medusa fuzz`
- Echidna smoke: `echidna . --contract CryticTester --config echidna.yaml --test-limit 10000`

Medusa is the primary bring-up fuzzer for the initial suite. Echidna and Halmos should be run after the handler surface is compiling and reaching meaningful coverage.
