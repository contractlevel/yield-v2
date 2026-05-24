# Yieldcoin V2 Invariant Tests

The integrated stateful invariant suite lives in `test/invariant/suite`.

The suite is written in Chimera style so the same handlers and properties can run through Foundry, Medusa, Echidna, Recon Fuzzer.

## Layout

- `suite/ghosts/` contains model state grouped by concern.
- `suite/Properties.t.sol` contains global invariants.
- Handler-local transition checks live beside the handler that mutates the relevant state.
- `suite/TargetFunctions.t.sol` contains the active target functions exposed to fuzzers.

## Commands

- Foundry setup/debug: `forge test --match-contract CryticToFoundry -vv`
- Foundry invariants: `FOUNDRY_PROFILE=invariants forge test --match-contract CryticToFoundry -vv`
- Medusa:

  ```sh
  medusa fuzz \
    --config medusa.json \
    --compilation-target test/invariant/suite/CryticTester.t.sol \
    --target-contracts CryticTester \
    --test-limit 1000 \
    --timeout 60
  ```

- Echidna smoke: `echidna . --contract CryticTester --config echidna.yaml --test-limit 10000`

Medusa is the primary bring-up fuzzer for the initial suite. Echidna and Halmos should be run after the handler surface is compiling and reaching meaningful coverage.
