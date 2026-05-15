package offchain

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func Fuzz_PoolToProtocolId_deterministic(f *testing.F) {
	f.Add("aave-v3")
	f.Add("compound-v3")
	f.Add("")

	f.Fuzz(func(t *testing.T, project string) {
		require.Equal(t, PoolToProtocolId(project), PoolToProtocolId(project), "expected deterministic protocol ID")
	})
}

func Fuzz_PoolToChainSelector_configuredOrMissing(f *testing.F) {
	f.Add("Ethereum")
	f.Add("Arbitrum")
	f.Add("Base")
	f.Add("")

	f.Fuzz(func(t *testing.T, chain string) {
		cfg := Config{
			Chains: []ChainConfig{
				{ChainSelector: 1, DefiLlamaChainName: "Ethereum"},
				{ChainSelector: 2, DefiLlamaChainName: "Arbitrum"},
				{ChainSelector: 3, DefiLlamaChainName: ""},
			},
		}

		selector, err := PoolToChainSelector(cfg, chain)
		switch chain {
		case "Ethereum":
			require.NoError(t, err, "expected configured chain to map")
			require.Equal(t, uint64(1), selector, "unexpected selector")
		case "Arbitrum":
			require.NoError(t, err, "expected configured chain to map")
			require.Equal(t, uint64(2), selector, "unexpected selector")
		default:
			require.Error(t, err, "expected unconfigured chain to fail")
			require.Zero(t, selector, "expected zero selector")
			require.ErrorContains(t, err, fmt.Sprintf("no chain selector for DefiLlama chain %q", chain))
		}
	})
}
