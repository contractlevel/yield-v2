package rebalance

import (
	"math"
	"testing"

	"cre/workflow/internal/offchain"

	"github.com/stretchr/testify/require"
)

func Fuzz_NeedRebalance_threshold(f *testing.F) {
	f.Add(2.0, 1.0)
	f.Add(1.99, 1.0)
	f.Add(0.0, 0.0)

	f.Fuzz(func(t *testing.T, optimalApy, currentApy float64) {
		got := NeedRebalance(&offchain.Pool{Apy: optimalApy}, &offchain.Pool{Apy: currentApy})
		if math.IsNaN(optimalApy) || math.IsNaN(currentApy) || optimalApy < 0 || currentApy < 0 || optimalApy > 1000 || currentApy > 1000 {
			require.False(t, got, "invalid APY must not trigger a rebalance")
			return
		}
		require.Equal(t, optimalApy-currentApy >= DifferentialThreshold, got, "unexpected rebalance decision")
	})
}
