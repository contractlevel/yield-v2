package onchain

import (
	"fmt"
	"math/big"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

const (
	RebalanceNone  uint8 = 0
	Rebalancing    uint8 = 1
	EpochOpen      uint8 = 1
	EpochExecuting uint8 = 2
	EpochClaimable uint8 = 3
)

// Snapshot is read once per execution. Observations across chains are
// not simultaneous; ObservedAt is DON time, not the timestamp of those blocks.
type Snapshot struct {
	ObservedAt int64
	Parent     parent_vault.TypesParentOperationalState
	Children   map[uint64]child_vault.TypesChildOperationalState
}

type SnapshotReader func(*helper.Config, cre.Runtime) (*Snapshot, error)
type parentFactory func(*evm.Client, string) (ParentVaultInterface, error)
type childFactory func(*evm.Client, string) (ChildVaultInterface, error)

func ReadSnapshot(config *helper.Config, runtime cre.Runtime) (*Snapshot, error) {
	return readSnapshot(config, runtime, NewParentVaultBinding, NewChildVaultBinding)
}

func readSnapshot(config *helper.Config, runtime cre.Runtime, newParent parentFactory, newChild childFactory) (*Snapshot, error) {
	snapshot := &Snapshot{ObservedAt: runtime.Now().Unix(), Children: make(map[uint64]child_vault.TypesChildOperationalState)}
	if snapshot.ObservedAt < 0 {
		return nil, fmt.Errorf("negative observation timestamp")
	}
	// Read every configured chain, including when an earlier chain is blocked.
	for _, cfg := range config.Evms {
		client := &evm.Client{ChainSelector: cfg.ChainSelector}
		block := big.NewInt(*config.BlockNumber)
		if cfg.IsParent {
			vault, err := newParent(client, cfg.VaultAddress)
			if err != nil {
				return nil, fmt.Errorf("bind parent on %s: %w", cfg.ChainName, err)
			}
			state, err := vault.GetParentOperationalState(runtime, block).Await()
			if err != nil {
				return nil, fmt.Errorf("read parent on %s: %w", cfg.ChainName, err)
			}
			snapshot.Parent = state
		} else {
			vault, err := newChild(client, cfg.VaultAddress)
			if err != nil {
				return nil, fmt.Errorf("bind child on %s: %w", cfg.ChainName, err)
			}
			state, err := vault.GetChildOperationalState(runtime, block).Await()
			if err != nil {
				return nil, fmt.Errorf("read child on %s: %w", cfg.ChainName, err)
			}
			snapshot.Children[cfg.ChainSelector] = state
		}
	}
	if err := snapshot.Validate(config); err != nil {
		return nil, err
	}
	return snapshot, nil
}

func (s *Snapshot) Validate(config *helper.Config) error {
	if s == nil || s.ObservedAt < 0 {
		return fmt.Errorf("invalid operational snapshot")
	}
	p := s.Parent
	if !Uint256(p.CurrentEpochNonce) || p.CurrentEpochNonce.Sign() == 0 {
		return fmt.Errorf("invalid parent epoch nonce")
	}
	if !Uint256(p.Rebalance.Nonce) || p.Rebalance.Nonce.Sign() == 0 ||
		!Uint256(p.Rebalance.LastRebalanceCompletedTimestamp) ||
		p.Rebalance.State > Rebalancing || p.RecoveryMode > 5 {
		return fmt.Errorf("invalid parent rebalance or recovery state")
	}
	if !Uint256(p.TotalShares) || !Uint256(p.Tvl) {
		return fmt.Errorf("invalid parent total shares or TVL")
	}
	for _, e := range []parent_vault.TypesEpoch{p.CurrentEpoch, p.PreviousEpoch} {
		for _, v := range []*big.Int{
			e.TotalDepositAmount, e.TotalShareBurnAmount, e.TotalWithdrawClaimAmount,
			e.RemainingDepositClaimAmount, e.RemainingShareMintAmount,
			e.RemainingShareBurnAmount, e.RemainingWithdrawClaimAmount, e.OpenedAtTimestamp,
		} {
			if !Uint256(v) {
				return fmt.Errorf("invalid epoch integer")
			}
		}
		if e.Status > EpochClaimable {
			return fmt.Errorf("invalid epoch status")
		}
	}
	for _, cfg := range config.Evms {
		if cfg.IsParent {
			continue
		}
		c, ok := s.Children[cfg.ChainSelector]
		if !ok || !Uint256(c.LastHandledEpochNonce) ||
			!Uint256(c.LastHandledRebalanceNonce) || !Uint256(c.Tvl) || c.RecoveryMode > 5 {
			return fmt.Errorf("invalid child operational state on %s", cfg.ChainName)
		}
	}
	return nil
}

func (s *Snapshot) BlockedReason(config *helper.Config) string {
	for _, cfg := range config.Evms {
		// @review is this parent/child overwrite the most efficient?
		paused, recovery := s.Parent.Paused, s.Parent.RecoveryMode
		if !cfg.IsParent {
			c := s.Children[cfg.ChainSelector]
			paused, recovery = c.Paused, c.RecoveryMode
		}
		if paused {
			return fmt.Sprintf("vault paused on %s", cfg.ChainName)
		}
		if recovery != 0 {
			return fmt.Sprintf("recovery active on %s (mode %d)", cfg.ChainName, recovery)
		}
	}
	return ""
}

func (s *Snapshot) ActiveTVL(parentChain uint64) (*big.Int, error) {
	chain := s.Parent.Rebalance.ActiveStrategy.ChainSelector
	if chain == parentChain {
		return s.Parent.Tvl, nil
	}
	child, ok := s.Children[chain]
	if !ok {
		return nil, fmt.Errorf("active strategy chain %d is not configured", chain)
	}
	return child.Tvl, nil
}

// MatchSource uses the chain captured by the subscription, never address alone.
func MatchSource(config *helper.Config, log *evm.Log, source, expected uint64) bool {
	cfg, err := helper.FindEvmConfigByChainSelector(config.Evms, source)
	return err == nil && source == expected && log != nil && len(log.Address) == common.AddressLength && common.BytesToAddress(log.Address) == common.HexToAddress(cfg.VaultAddress)
}

func Uint256(v *big.Int) bool { return v != nil && v.Sign() >= 0 && v.BitLen() <= 256 }

func PeriodElapsed(openedAt *big.Int, now int64, period int64) bool {
	return Uint256(openedAt) && now >= 0 && big.NewInt(now).Cmp(new(big.Int).Add(openedAt, big.NewInt(period))) >= 0
}
