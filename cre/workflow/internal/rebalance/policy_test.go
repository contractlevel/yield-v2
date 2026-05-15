package rebalance

import (
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
		{name: "no current", optimal: &offchain.Pool{Apy: 1}, want: true},
		{name: "below threshold", optimal: &offchain.Pool{Apy: 1.009}, current: &offchain.Pool{Apy: 1}, want: false},
		{name: "at threshold", optimal: &offchain.Pool{Apy: 1.01}, current: &offchain.Pool{Apy: 1}, want: true},
		{name: "above threshold", optimal: &offchain.Pool{Apy: 2}, current: &offchain.Pool{Apy: 1}, want: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, NeedRebalance(tt.optimal, tt.current), "unexpected rebalance decision")
		})
	}
}
