package rebalance

import "cre/workflow/internal/offchain"

const (
	DifferentialThreshold       = 1.0         // 1 percentage point
	minRebalanceIntervalSeconds = 1 * 60 * 60 // every hour
)

// NeedRebalance returns true when a rebalance to the optimal pool is warranted.
// If current is nil, the DefiLlama response is incomplete and we fail closed.
func NeedRebalance(optimal, current *offchain.Pool) bool {
	if optimal == nil {
		return false
	}
	if current == nil {
		return false
	}
	if !offchain.ValidPoolAPY(optimal.Apy) || !offchain.ValidPoolAPY(current.Apy) {
		return false
	}
	return optimal.Apy-current.Apy >= DifferentialThreshold
}

func RebalanceCooldownElapsed(lastCompletedTimestamp, now int64) bool {
	if lastCompletedTimestamp <= 0 {
		return true
	}
	return now >= lastCompletedTimestamp+minRebalanceIntervalSeconds
}
