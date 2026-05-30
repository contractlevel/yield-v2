package helper

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func Fuzz_FindEvmConfigByChainSelector(f *testing.F) {
	f.Add(uint64(1), uint64(2), uint64(3), uint64(2))
	f.Add(uint64(1), uint64(2), uint64(3), uint64(9))
	f.Add(uint64(5), uint64(5), uint64(5), uint64(5))

	f.Fuzz(func(t *testing.T, a, b, c, target uint64) {
		evms := []EvmConfig{
			{ChainName: "a", ChainSelector: a},
			{ChainName: "b", ChainSelector: b},
			{ChainName: "c", ChainSelector: c},
		}

		cfg, err := FindEvmConfigByChainSelector(evms, target)

		var want *EvmConfig
		for i := range evms {
			if evms[i].ChainSelector == target {
				want = &evms[i]
				break
			}
		}

		if want != nil {
			require.NoError(t, err, "expected no error when selector exists")
			require.NotNil(t, cfg, "expected non-nil cfg when selector exists")
			require.Equal(t, want.ChainSelector, cfg.ChainSelector, "unexpected ChainSelector")
			require.Equal(t, want.ChainName, cfg.ChainName, "unexpected ChainName")
		} else {
			require.Error(t, err, "expected error when selector is missing")
			require.Nil(t, cfg, "expected nil cfg when selector is missing")
			require.ErrorContains(t, err, fmt.Sprintf("no evm config found for chainSelector %d", target))
		}
	})
}

func Fuzz_ValidateConfig_parentCount(f *testing.F) {
	f.Add(false, false, false)
	f.Add(true, false, false)
	f.Add(true, true, false)
	f.Add(true, true, true)

	f.Fuzz(func(t *testing.T, parentA, parentB, parentC bool) {
		cfg := &Config{
			DefiLlama: validDefiLlamaConfig(),
			Evms: []EvmConfig{
				validEvmConfig(func(e *EvmConfig) {
					e.IsParent = parentA
					e.ChainName = "chain-a"
					e.ChainSelector = 1
					e.VaultAddress = "0x0000000000000000000000000000000000000001"
					e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000002"
				}),
				validEvmConfig(func(e *EvmConfig) {
					e.IsParent = parentB
					e.ChainName = "chain-b"
					e.ChainSelector = 2
					e.VaultAddress = "0x0000000000000000000000000000000000000003"
					e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000004"
				}),
				validEvmConfig(func(e *EvmConfig) {
					e.IsParent = parentC
					e.ChainName = "chain-c"
					e.ChainSelector = 3
					e.VaultAddress = "0x0000000000000000000000000000000000000005"
					e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000006"
				}),
			},
		}

		parentCount := 0
		for _, isParent := range []bool{parentA, parentB, parentC} {
			if isParent {
				parentCount++
			}
		}

		err := ValidateConfig(cfg)
		if parentCount == 1 {
			require.NoError(t, err, "expected config with exactly one parent to pass")
		} else {
			require.Error(t, err, "expected config without exactly one parent to fail")
			require.ErrorContains(t, err, fmt.Sprintf("expected exactly one parent chain (IsParent=true), got %d", parentCount))
		}
	})
}

func Fuzz_ValidateConfig_defiLlamaProjectCanonicalDuplicates(f *testing.F) {
	f.Add("aave-v3", "compound-v3")
	f.Add("aave-v3", "AAVE-V3")
	f.Add(" aave-v3 ", "AAVE-V3")
	f.Add("", "aave-v3")
	f.Add(" ", "aave-v3")

	f.Fuzz(func(t *testing.T, projectA, projectB string) {
		cfg := &Config{
			DefiLlama: DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{projectA, projectB}, Symbols: []string{"USDC"}},
			Evms:      []EvmConfig{validEvmConfig()},
		}

		err := ValidateConfig(cfg)
		canonicalA := canonicalDefiLlamaValue(projectA)
		canonicalB := canonicalDefiLlamaValue(projectB)
		if canonicalA == "" || canonicalB == "" || canonicalA == canonicalB {
			require.Error(t, err, "expected empty or duplicate canonical project values to fail")
			return
		}
		require.NoError(t, err, "expected distinct canonical project values to pass")
	})
}

func Fuzz_ValidateConfig_defiLlamaSymbolCanonicalDuplicates(f *testing.F) {
	f.Add("USDC", "DAI")
	f.Add("USDC", "usdc")
	f.Add(" USDC ", "usdc")
	f.Add("", "USDC")
	f.Add(" ", "USDC")

	f.Fuzz(func(t *testing.T, symbolA, symbolB string) {
		cfg := &Config{
			DefiLlama: DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{symbolA, symbolB}},
			Evms:      []EvmConfig{validEvmConfig()},
		}

		err := ValidateConfig(cfg)
		canonicalA := canonicalDefiLlamaValue(symbolA)
		canonicalB := canonicalDefiLlamaValue(symbolB)
		if canonicalA == "" || canonicalB == "" || canonicalA == canonicalB {
			require.Error(t, err, "expected empty or duplicate canonical symbol values to fail")
			return
		}
		require.NoError(t, err, "expected distinct canonical symbol values to pass")
	})
}
