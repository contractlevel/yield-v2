package rebalance

import (
	"testing"

	"github.com/stretchr/testify/require"

	"cre/workflow/internal/helper"
)

func Fuzz_NewDefiLlamaConfig(f *testing.F) {
	f.Add(uint64(1), "Ethereum", uint64(2), "Arbitrum")
	f.Add(uint64(1), "", uint64(2), "Base")

	f.Fuzz(func(t *testing.T, parentSelector uint64, parentName string, childSelector uint64, childName string) {
		cfg := &helper.Config{
			DefiLlama: helper.DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{"USDC"}},
			Evms: []helper.EvmConfig{
				{IsParent: true, ChainSelector: parentSelector, DefiLlamaChainName: parentName},
				{ChainSelector: childSelector, DefiLlamaChainName: childName},
			},
		}

		got := newDefiLlamaConfig(cfg)
		require.Equal(t, []string{"pool-a"}, got.PoolIDs, "unexpected pool IDs")
		require.Equal(t, []string{"aave-v3"}, got.Projects, "unexpected projects")
		require.Equal(t, []string{"USDC"}, got.Symbols, "unexpected symbols")
		require.Len(t, got.Chains, len(cfg.Evms), "unexpected chain count")
		require.Equal(t, parentSelector, got.Chains[0].ChainSelector, "unexpected parent selector")
		require.Equal(t, parentName, got.Chains[0].DefiLlamaChainName, "unexpected parent DefiLlama name")
		require.Equal(t, childSelector, got.Chains[1].ChainSelector, "unexpected child selector")
		require.Equal(t, childName, got.Chains[1].DefiLlamaChainName, "unexpected child DefiLlama name")
	})
}
