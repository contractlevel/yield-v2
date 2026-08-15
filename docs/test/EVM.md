# EVM Testing

All commands below run from the EVM project root, `evm/`.

## Build

```
forge build --build-info
```

```
forge build src/vaults/ParentVault.sol --sizes
```

## Coverage with via_ir

Run for coverage:

```
forge coverage --report lcov
forge coverage --ir-minimum --report lcov
forge coverage --ir-minimum --report lcov --no-match-path "test/fork/**"
```

Inspect the report:

```
genhtml lcov.info -o coverage
open coverage/index.html
```

## Static Analysis

```
slither . --filter-path lib
```

```
aderyn .
```

## Invariants

```
forge test --match-contract CryticToFoundry -vv
```

```
medusa fuzz --config medusa.json --test-limit 1000 --timeout 60
```

Do not delete medusa/ between runs if you want it to build on prior corpus. Delete it only when you need a clean rerun.

### Clean Medusa Reset

The following command permanently deletes the accumulated Medusa corpus and coverage data. Run it only when you need a clean fuzzing run.

```
rm -rf medusa
medusa fuzz \
    --config medusa.json \
    --compilation-target test/invariant/chimera/CryticTester.t.sol \
    --target-contracts CryticTester \
    --test-limit 1000 \
    --timeout 60
```

```
medusa fuzz \
    --config medusa.json \
    --compilation-target test/invariant/chimera/CryticTester.t.sol \
    --target-contracts CryticTester \
    --test-limit 5000 \
    --timeout 600
```

```
open medusa/coverage/coverage_report.html
```

```
recon fuzz . --config echidna.yaml --contract CryticTester
```

```
recon fuzz . \
    --config echidna.yaml \
    --contract CryticTester \
    --recon-corpus-dir recon-corpus \
    --workers 10 \
    --stop-on-fail
```

```
halmos --contract ClaimSolvency --forge-build-out out-halmos --function check_ \
         --solver-timeout-branching 10000 --solver-timeout-assertion 30000
```

## Certora

_Note: Some of the ParentVault rules require ParentVault::\_finalizeRebalance and \_finalizeLocalToLocalRebalance to be virtual_

```
certoraRun ./certora/conf/modules/AdapterRegistry.conf

certoraRun ./certora/conf/modules/adapters/AaveV3Adapter.ProtocolAdapter.conf
certoraRun ./certora/conf/modules/adapters/AaveV4Adapter.ProtocolAdapter.conf
certoraRun ./certora/conf/modules/adapters/CompoundV3Adapter.ProtocolAdapter.conf

certoraRun ./certora/conf/modules/adapters/AaveV3Adapter.conf
certoraRun ./certora/conf/modules/adapters/AaveV4Adapter.conf
certoraRun ./certora/conf/modules/adapters/CompoundV3Adapter.conf

certoraRun ./certora/conf/modules/WorkflowRouter.conf

certoraRun ./certora/conf/token/YieldcoinShare.conf

certoraRun certora/conf/libraries/BaseVaultCcipLib.conf
certoraRun certora/conf/libraries/BaseVaultConfigLib.conf
certoraRun certora/conf/libraries/BaseVaultStrategyLib.conf

certoraRun certora/conf/libraries/ParentVaultCcipLib.conf
certoraRun certora/conf/libraries/ParentVaultConfigLib.conf
certoraRun certora/conf/libraries/ParentVaultEpochLib.conf
certoraRun certora/conf/libraries/ParentVaultFeesLib.conf
certoraRun certora/conf/libraries/ParentVaultRebalanceLib.conf
certoraRun certora/conf/libraries/ParentVaultUserEpochLib.conf

// Some of the ParentVault rules require ParentVault::_finalizeRebalance and _finalizeLocalToLocalRebalance to be virtual

certoraRun certora/conf/vaults/ChildVault.BaseVault.conf
certoraRun certora/conf/vaults/ParentVault.BaseVault.conf

certoraRun certora/conf/vaults/ChildVault.rules.conf
certoraRun certora/conf/vaults/ChildVault.invariants.conf

// Some of the ParentVault rules require ParentVault::_finalizeRebalance and _finalizeLocalToLocalRebalance to be virtual

certoraRun certora/conf/vaults/ParentVault.rules.conf
certoraRun certora/conf/vaults/ParentVault.localAdapter.conf
certoraRun certora/conf/vaults/ParentVault.invariants.conf

`ParentVault.localAdapter.conf` runs rules that require a concrete local active adapter. It links the
`s_activeProtocolAdapter` storage path to `MockProtocolAdapter` so Certora can resolve local strategy
deposit and withdrawal calls. Keep this mutable-storage link out of the shared ParentVault
configurations. The shared rules conf excludes these rules so they are verified only by the
dedicated target.
```

---

## Note

The Foundry test suite uses the [Contract Level fork](https://github.com/contractlevel/chainlink-local/tree/main) of Chainlink's CCIP local simulator for added USDC/CCTP support.
