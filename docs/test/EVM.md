# EVM Testing

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
FOUNDRY_PROFILE=halmos forge build
halmos --contract ClaimSolvency --forge-build-out out-halmos --function check_ \
         --solver-timeout-branching 10000 --solver-timeout-assertion 30000
```

## Certora

```
certoraRun ./certora/conf/modules/AdapterRegistry.conf

certoraRun ./certora/conf/modules/adapters/AaveV3Adapter.ProtocolAdapter.conf
certoraRun ./certora/conf/modules/adapters/AaveV4Adapter.ProtocolAdapter.conf
certoraRun ./certora/conf/modules/adapters/CompoundV3Adapter.ProtocolAdapter.conf

certoraRun ./certora/conf/modules/adapters/AaveV3Adapter.conf
certoraRun ./certora/conf/modules/adapters/AaveV4Adapter.conf
certoraRun ./certora/conf/modules/adapters/CompoundV3Adapter.conf

certoraRun ./certora/conf/modules/WorkflowRouter.conf

certoraRun ./certora/conf/modules/extractors/SenderExtractor.conf
certoraRun ./certora/conf/modules/extractors/YieldcoinShareKycExtractor.conf

certoraRun ./certora/conf/modules/policies/TerminalAllowPolicy.conf
certoraRun ./certora/conf/modules/policies/CredentialRegistryAccountListValidatorPolicy.conf

certoraRun ./certora/conf/token/YieldcoinShare.conf

certoraRun certora/conf/libraries/BaseVaultCcipLib.conf
certoraRun certora/conf/libraries/BaseVaultStrategyLib.conf

certoraRun certora/conf/libraries/ParentVaultCcipLib.conf
certoraRun certora/conf/libraries/ParentVaultEpochLib.conf
certoraRun certora/conf/libraries/ParentVaultFeesLib.conf
certoraRun certora/conf/libraries/ParentVaultRebalanceLib.conf
certoraRun certora/conf/libraries/ParentVaultUserEpochLib.conf

certoraRun certora/conf/vaults/ParentVault.BaseVault.conf
certoraRun certora/conf/vaults/ChildVault.BaseVault.conf

certoraRun certora/conf/vaults/ChildVault.conf
certoraRun certora/conf/vaults/ParentVault.conf

```
