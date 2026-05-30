package rebalance

import (
	"math"
	"testing"

	"cre/workflow/internal/offchain"

	"github.com/stretchr/testify/require"
)

func Test_NeedRebalance(t *testing.T) {
	tests := []struct {
		name    string
		optimal *offchain.Pool
		current *offchain.Pool
		want    bool
	}{
		{name: "no optimal", want: false},
		{name: "no current", optimal: &offchain.Pool{Apy: 1}, want: false},
		{name: "below threshold", optimal: &offchain.Pool{Apy: 1.99}, current: &offchain.Pool{Apy: 1}, want: false},
		{name: "at threshold", optimal: &offchain.Pool{Apy: 2}, current: &offchain.Pool{Apy: 1}, want: true},
		{name: "above threshold", optimal: &offchain.Pool{Apy: 2.01}, current: &offchain.Pool{Apy: 1}, want: true},
		{name: "negative optimal APY", optimal: &offchain.Pool{Apy: -0.01}, current: &offchain.Pool{Apy: 1}, want: false},
		{name: "negative current APY", optimal: &offchain.Pool{Apy: 2}, current: &offchain.Pool{Apy: -0.01}, want: false},
		{name: "excessive optimal APY", optimal: &offchain.Pool{Apy: 1000.01}, current: &offchain.Pool{Apy: 1}, want: false},
		{name: "excessive current APY", optimal: &offchain.Pool{Apy: 2}, current: &offchain.Pool{Apy: 1000.01}, want: false},
		{name: "NaN optimal APY", optimal: &offchain.Pool{Apy: math.NaN()}, current: &offchain.Pool{Apy: 1}, want: false},
		{name: "infinite optimal APY", optimal: &offchain.Pool{Apy: math.Inf(1)}, current: &offchain.Pool{Apy: 1}, want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, NeedRebalance(tt.optimal, tt.current), "unexpected rebalance decision")
		})
	}
}

func Test_RebalanceCooldownElapsed(t *testing.T) {
	tests := []struct {
		name          string
		lastCompleted int64
		now           int64
		want          bool
	}{
		{name: "never completed", now: 1, want: true},
		{name: "negative timestamp", lastCompleted: -1, now: 1, want: true},
		{name: "before interval", lastCompleted: 100, now: 100 + minRebalanceIntervalSeconds - 1, want: false},
		{name: "at interval", lastCompleted: 100, now: 100 + minRebalanceIntervalSeconds, want: true},
		{name: "after interval", lastCompleted: 100, now: 100 + minRebalanceIntervalSeconds + 1, want: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, RebalanceCooldownElapsed(tt.lastCompleted, tt.now), "unexpected cooldown decision")
		})
	}
}
