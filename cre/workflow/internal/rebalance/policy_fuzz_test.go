package rebalance

import (
	"math"
	"testing"

	"cre/workflow/internal/offchain"

	"github.com/stretchr/testify/require"
)

func Fuzz_NeedRebalance_threshold(f *testing.F) {
	f.Add(1.01, 1.0)
	f.Add(1.009, 1.0)
	f.Add(0.0, 0.0)

	f.Fuzz(func(t *testing.T, optimalApy, currentApy float64) {
		if math.IsNaN(optimalApy) || math.IsNaN(currentApy) {
			t.Skip("NaN comparisons are not useful for threshold assertions")
		}

		got := NeedRebalance(&offchain.Pool{Apy: optimalApy}, &offchain.Pool{Apy: currentApy})
		require.Equal(t, optimalApy-currentApy >= DifferentialThreshold, got, "unexpected rebalance decision")
	})
}
