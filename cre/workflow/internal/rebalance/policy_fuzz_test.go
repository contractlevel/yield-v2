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
		if math.IsNaN(optimalApy) || math.IsNaN(currentApy) {
			t.Skip("NaN comparisons are not useful for threshold assertions")
		}

		got := NeedRebalance(&offchain.Pool{Apy: optimalApy}, &offchain.Pool{Apy: currentApy})
		require.Equal(t, optimalApy-currentApy >= DifferentialThreshold, got, "unexpected rebalance decision")
	})
}

func Fuzz_RebalanceCooldownElapsed(f *testing.F) {
	f.Add(int64(0), int64(1))
	f.Add(int64(-1), int64(1))
	f.Add(int64(100), int64(100+minRebalanceIntervalSeconds-1))
	f.Add(int64(100), int64(100+minRebalanceIntervalSeconds))

	f.Fuzz(func(t *testing.T, lastCompletedTimestamp, now int64) {
		got := RebalanceCooldownElapsed(lastCompletedTimestamp, now)
		if lastCompletedTimestamp <= 0 {
			require.True(t, got, "expected unset cooldown timestamp to pass")
			return
		}

		require.Equal(t, now >= lastCompletedTimestamp+minRebalanceIntervalSeconds, got, "unexpected cooldown decision")
	})
}
