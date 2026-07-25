# CRE Testing

All commands below run from the Go module root, `cre/`.

Run tests:

`go test ./...`

Run a single package:

`go test ./workflow/internal/helper`

Run the workflow root package only:

`go test ./workflow`

See coverage:

`go test -cover ./...`

`go test -coverprofile=coverage.out ./...`

`go tool cover -html=coverage.out`

Run single test:

`go test -run Test_funcName ./...`

`go test -v -run Test_funcName ./...`

Running groups of tests:

We name our tests like so `Test_group_funcName`

`go test -run Test_group ./...`

`go test -v -run Test_group ./...`

Clean cache:

`go clean -testcache`

Integration tests:

`go test -tags=integration ./...`

## Fuzz Tests

Each fuzz target lives in its own package and must be run individually (Go does not support fuzzing multiple targets in one invocation):

```
go test ./workflow -run='^$' -fuzz=Fuzz_InitWorkflow_ConfigShape -fuzztime=30s

go test ./workflow/internal/helper -run='^$' -fuzz=Fuzz_FindEvmConfigByChainSelector -fuzztime=30s
go test ./workflow/internal/helper -run='^$' -fuzz=Fuzz_ValidateConfig_parentCount -fuzztime=30s
go test ./workflow/internal/helper -run='^$' -fuzz=Fuzz_ValidateConfig_defiLlamaProjectCanonicalDuplicates -fuzztime=30s
go test ./workflow/internal/helper -run='^$' -fuzz=Fuzz_ValidateConfig_defiLlamaSymbolCanonicalDuplicates -fuzztime=30s

go test ./workflow/internal/onchain -run='^$' -fuzz=Fuzz_NewParentVaultBinding_addressValidation -fuzztime=10s
go test ./workflow/internal/onchain -run='^$' -fuzz=Fuzz_NewChildVaultBinding_addressValidation -fuzztime=10s
go test ./workflow/internal/onchain -run='^$' -fuzz=Fuzz_SubmitReport_propagatesWriteInputs -fuzztime=10s
go test ./workflow/internal/onchain -run='^$' -fuzz=Fuzz_ReadWrappers_passThroughInputs -fuzztime=10s

go test ./workflow/internal/offchain -run='^$' -fuzz=Fuzz_PoolToProtocolId_deterministic -fuzztime=10s
go test ./workflow/internal/offchain -run='^$' -fuzz=Fuzz_PoolToChainSelector_configuredOrMissing -fuzztime=10s

go test ./workflow/internal/rebalance -run='^$' -fuzz=Fuzz_NewDefiLlamaConfig -fuzztime=10s
go test ./workflow/internal/rebalance -run='^$' -fuzz=Fuzz_NeedRebalance_threshold -fuzztime=5s
go test ./workflow/internal/rebalance -run='^$' -fuzz=Fuzz_RebalanceCooldownElapsed -fuzztime=5s

go test ./workflow/internal/epoch -run='^$' -fuzz=Fuzz_OnEpochCronTrigger_guardOutcomes -fuzztime=10s
```

Formatting:

`gofmt -w .`

Static analysis:

`go vet ./...`

`golangci-lint run ./...`

`gosec ./...`

`govulncheck ./...`
