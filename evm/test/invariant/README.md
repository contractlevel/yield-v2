# Yieldcoin V2 Invariant Tests

Two complementary approaches live here, each targeting a different class of correctness guarantee.

## chimera/ — stateful fuzzing

A full simulated environment: three vaults, CCIP mocks, and a shared actor model. Written in Chimera style so the same handlers and properties can drive Foundry, Medusa, and Recon Fuzzer. Fuzzers explore long call sequences to find invariant violations that only emerge from realistic multi-step interactions.

- `chimera/ghosts/` contains model state grouped by concern.
- `chimera/Properties.t.sol` contains global invariants.
- Handler-local transition checks live beside the handler that mutates the relevant state.
- `chimera/TargetFunctions.t.sol` contains the active target functions exposed to fuzzers.

## halmos/ — isolated symbolic execution

Lean, single-vault tests that prove arithmetic properties hold for **all** possible inputs, not just sampled ones. State is written directly into storage via `stdstore`; only the function under proof is called. No multi-step sequences, no CCIP topology.

- `halmos/ClaimSolvency.t.sol` proves the deposit-side and withdraw-side claim counter pairs always reach zero together.

## Commands

- Foundry setup/debug: `forge test --match-contract CryticToFoundry -vv`
- Foundry invariants: `FOUNDRY_PROFILE=invariants forge test --match-contract CryticToFoundry -vv`
- Medusa:

  ```sh
  medusa fuzz \
    --config medusa.json \
    --compilation-target test/invariant/chimera/CryticTester.t.sol \
    --target-contracts CryticTester \
    --test-limit 1000 \
    --timeout 60
  ```

- Recon-fuzzer: `recon fuzz . --config echidna.yaml --contract CryticTester`

```
recon fuzz . \
    --config echidna.yaml \
    --contract CryticTester \
    --recon-corpus-dir recon-corpus \
    --workers 10 \
    --stop-on-fail
```

- Echidna smoke: `echidna . --contract CryticTester --config echidna.yaml --test-limit 10000`

- Halmos (install once: `pip install halmos==0.3.3`):

```sh
FOUNDRY_PROFILE=halmos forge build
halmos --contract ClaimSolvency --forge-build-out out-halmos --function check_ \
       --solver-timeout-branching 10000 --solver-timeout-assertion 30000

halmos --forge-build-out out-halmos --solver-timeout-assertion 0
```

The `halmos` profile targets `shanghai` (avoids the MCOPY opcode that Halmos does not support). `via_ir` is required by dependencies and stays on. Artifacts go to `out-halmos/` to avoid conflicting with the main build.

Each `check_*` function writes symbolic counter values directly into vault storage via `stdstore`, then calls the real contract function. This proves the counter-pair solvency property holds for every possible input, not just sampled ones.
