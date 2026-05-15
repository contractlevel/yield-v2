package rebalance

import "cre/workflow/internal/offchain"

const DifferentialThreshold = 0.01 // 1 percentage point

// NeedRebalance returns true when a rebalance to the optimal pool is warranted.
// If current is nil (active strategy not in the approved set), we always rebalance.
func NeedRebalance(optimal, current *offchain.Pool) bool {
	if optimal == nil {
		return false
	}
	if current == nil {
		return true
	}
	return optimal.Apy-current.Apy >= DifferentialThreshold
}
