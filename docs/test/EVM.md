# EVM Testing

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

### Invariants

```
forge test --match-contract CryticToFoundry -vv
```

```
medusa fuzz --config medusa.json --test-limit 1000 --timeout 60
```

```
rm -rf medusa
medusa fuzz \
    --config medusa.json \
    --compilation-target test/invariant/suite/CryticTester.t.sol \
    --target-contracts CryticTester \
    --test-limit 1000 \
    --timeout 60
```

```
open medusa/coverage/coverage_report.html
```
