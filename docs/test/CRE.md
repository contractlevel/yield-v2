# CRE Testing

Run tests:

`go test -v .`

See coverage:

`go test -cover .`

`go test -coverprofile=coverage.out`

`go tool cover -html=coverage.out`

`go test -coverprofile=coverage.out ./internal/onchain` - for a specific package

`go test -coverprofile=coverage.out ./workflow/internal/compoundV3` - for a specific package

Run single test:

`go test -run Test_funcName`

`go test -v -run Test_funcName`

Running groups of tests:

We name our tests like so `Test_group_funcName`

`go test -run Test_group`

`go test -v -run Test_group`

Clean cache:

`go clean -testcache`

Integration tests:

`go test -tags=integration .`

Fuzz tests:

`go test -v -fuzz FuzzTest_name`

```
go test ./internal/helper -run='^$' -fuzz=Fuzz_FindEvmConfigByChainSelector -fuzztime=30s
go test ./internal/helper -run='^$' -fuzz=Fuzz_ValidateConfig_parentCount -fuzztime=30s

go test -run='^$' -fuzz=Fuzz_InitWorkflow_ConfigShape -fuzztime=30s

go test -run '^$' -fuzz=Fuzz_NewParentVaultBinding_addressValidation -fuzztime=10s ./internal/onchain
go test -run '^$' -fuzz=Fuzz_NewChildVaultBinding_addressValidation -fuzztime=10s ./internal/onchain
go test -run '^$' -fuzz=Fuzz_SubmitReport_propagatesWriteInputs -fuzztime=10s ./internal/onchain

go test -run '^$' -fuzz=Fuzz_PoolToProtocolId_deterministic -fuzztime=10s ./internal/offchain
go test -run '^$' -fuzz=Fuzz_PoolToChainSelector_configuredOrMissing -fuzztime=10s ./internal/offchain

go test -run '^$' -fuzz=Fuzz_NewDefiLlamaConfig -fuzztime=10s ./internal/rebalance
go test -run '^$' -fuzz=Fuzz_NeedRebalance_threshold -fuzztime=5s ./workflow/internal/rebalance

go test -run '^$' -fuzz=Fuzz_OnEpochCronTrigger_guardOutcomes -fuzztime=10s ./internal/epoch

go test -run '^$' -fuzz=Fuzz_PoolToProtocolId_deterministic -fuzztime=10s ./internal/offchain
go test -run '^$' -fuzz=Fuzz_PoolToChainSelector_configuredOrMissing -fuzztime=10s ./internal/offchain

go test -run '^$' -fuzz=Fuzz_FindEvmConfigByChainSelector -fuzztime=10s ./internal/helper
go test -run '^$' -fuzz=Fuzz_ValidateConfig_parentCount -fuzztime=10s ./internal/helper

go test -run '^$' -fuzz=Fuzz_ReadWrappers_passThroughInputs -fuzztime=10s ./internal/onchain
```

Formatting:

`gofmt -w .`

Static analysis:

`go vet .`

`golangci-lint run .`

`gosec .`

`govulncheck .`
