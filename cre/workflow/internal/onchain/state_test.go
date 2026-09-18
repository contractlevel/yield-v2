package onchain

import (
	"errors"
	"fmt"
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/stretchr/testify/require"
)

type testParentReader struct {
	state  parent_vault.TypesParentOperationalState
	err    error
	onRead func(*big.Int)
}

func (v testParentReader) GetParentOperationalState(_ cre.Runtime, block *big.Int) cre.Promise[parent_vault.TypesParentOperationalState] {
	v.onRead(block)
	return cre.PromiseFromResult(v.state, v.err)
}

type testChildReader struct {
	state  child_vault.TypesChildOperationalState
	err    error
	onRead func(*big.Int)
}

func (v testChildReader) GetChildOperationalState(_ cre.Runtime, block *big.Int) cre.Promise[child_vault.TypesChildOperationalState] {
	v.onRead(block)
	return cre.PromiseFromResult(v.state, v.err)
}

func newTestEpoch() parent_vault.TypesEpoch {
	return parent_vault.TypesEpoch{
		TotalDepositAmount: new(big.Int), TotalShareBurnAmount: new(big.Int),
		TotalWithdrawClaimAmount: new(big.Int), RemainingDepositClaimAmount: new(big.Int),
		RemainingShareMintAmount: new(big.Int), RemainingShareBurnAmount: new(big.Int),
		RemainingWithdrawClaimAmount: new(big.Int), OpenedAtTimestamp: new(big.Int),
	}
}

func newTestParentState() parent_vault.TypesParentOperationalState {
	return parent_vault.TypesParentOperationalState{
		CurrentEpochNonce: big.NewInt(2), CurrentEpoch: newTestEpoch(), PreviousEpoch: newTestEpoch(),
		TotalShares: big.NewInt(100), Tvl: big.NewInt(100),
		Rebalance: parent_vault.TypesRebalance{
			Nonce: big.NewInt(7), LastRebalanceCompletedTimestamp: new(big.Int),
			ActiveStrategy: parent_vault.TypesStrategy{ChainSelector: 2},
		},
	}
}

func newTestChildState() child_vault.TypesChildOperationalState {
	return child_vault.TypesChildOperationalState{
		LastHandledEpochNonce: new(big.Int), LastHandledRebalanceNonce: new(big.Int), Tvl: big.NewInt(200),
	}
}

func TestSnapshotRejectsMalformedState(t *testing.T) {
	config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{IsParent: true, ChainSelector: 1}}}
	for _, test := range []struct {
		name   string
		change func(*Snapshot)
		reason string
	}{
		{"negative time", func(s *Snapshot) { s.ObservedAt = -1 }, "invalid operational snapshot"},
		{"zero epoch nonce", func(s *Snapshot) { s.Parent.CurrentEpochNonce = new(big.Int) }, "invalid parent epoch nonce"},
		{"missing epoch nonce", func(s *Snapshot) { s.Parent.CurrentEpochNonce = nil }, "invalid parent epoch nonce"},
		{"invalid rebalance", func(s *Snapshot) { s.Parent.Rebalance.State = 2 }, "invalid parent rebalance or recovery state"},
		{"zero rebalance nonce", func(s *Snapshot) { s.Parent.Rebalance.Nonce = new(big.Int) }, "invalid parent rebalance or recovery state"},
		{"missing rebalance timestamp", func(s *Snapshot) { s.Parent.Rebalance.LastRebalanceCompletedTimestamp = nil }, "invalid parent rebalance or recovery state"},
		{"invalid recovery", func(s *Snapshot) { s.Parent.RecoveryMode = 6 }, "invalid parent rebalance or recovery state"},
		{"missing total shares", func(s *Snapshot) { s.Parent.TotalShares = nil }, "invalid parent total shares or TVL"},
		{"negative TVL", func(s *Snapshot) { s.Parent.Tvl = big.NewInt(-1) }, "invalid parent total shares or TVL"},
		{"invalid epoch status", func(s *Snapshot) { s.Parent.CurrentEpoch.Status = 4 }, "invalid epoch status"},
	} {
		t.Run(test.name, func(t *testing.T) {
			snapshot := &Snapshot{Parent: newTestParentState()}
			test.change(snapshot)
			require.ErrorContains(t, snapshot.Validate(config), test.reason)
		})
	}
	var snapshot *Snapshot
	require.ErrorContains(t, snapshot.Validate(config), "invalid operational snapshot")
	_, err := ReadSnapshot(&helper.Config{BlockNumber: new(int64)}, newMockRuntime(t))
	require.ErrorContains(t, err, "invalid parent epoch nonce")
	runtime := newMockRuntime(t)
	runtime.now = -1
	_, err = ReadSnapshot(config, runtime)
	require.ErrorContains(t, err, "negative observation timestamp")
}

func TestUnblockedParentStrategy(t *testing.T) {
	config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{IsParent: true, ChainSelector: 1}}}
	snapshot := &Snapshot{Parent: newTestParentState()}
	snapshot.Parent.Rebalance.ActiveStrategy.ChainSelector = 1
	require.Empty(t, snapshot.BlockedReason(config))
	tvl, err := snapshot.ActiveTVL(1)
	require.NoError(t, err)
	require.Same(t, snapshot.Parent.Tvl, tvl)
}

func TestReadSnapshotReadsEveryChainOnceAtConfiguredBlock(t *testing.T) {
	for _, test := range []struct {
		chains int
		block  int64
	}{
		{5, rpc.FinalizedBlockNumber.Int64()},
		{6, rpc.FinalizedBlockNumber.Int64()},
		{8, rpc.FinalizedBlockNumber.Int64()},
		{5, rpc.PendingBlockNumber.Int64()},
		{5, rpc.LatestBlockNumber.Int64()},
		{5, 12345},
	} {
		t.Run(fmt.Sprintf("%d chains/block %d", test.chains, test.block), func(t *testing.T) {
			chains := test.chains
			config := &helper.Config{BlockNumber: &test.block}
			for i := 1; i <= chains; i++ {
				config.Evms = append(config.Evms, helper.EvmConfig{IsParent: i == 1, ChainSelector: uint64(i), ChainName: fmt.Sprint(i), VaultAddress: validVaultAddress})
			}
			reads := make(map[uint64]int)
			checkRead := func(chain uint64) func(*big.Int) {
				return func(block *big.Int) {
					require.Equal(t, test.block, block.Int64())
					reads[chain]++
				}
			}
			parent := newTestParentState()
			parent.Paused = true // A blocker must not prevent checking later chains.
			snapshot, err := readSnapshot(config, newMockRuntime(t),
				func(client *evm.Client, address string) (ParentVaultInterface, error) {
					require.Equal(t, validVaultAddress, address)
					return testParentReader{state: parent, onRead: checkRead(client.ChainSelector)}, nil
				},
				func(client *evm.Client, address string) (ChildVaultInterface, error) {
					require.Equal(t, validVaultAddress, address)
					return testChildReader{state: newTestChildState(), onRead: checkRead(client.ChainSelector)}, nil
				},
			)
			require.NoError(t, err)
			require.Len(t, reads, chains)
			for _, count := range reads {
				require.Equal(t, 1, count)
			}
			require.Equal(t, int64(0), snapshot.ObservedAt)
			require.Contains(t, snapshot.BlockedReason(config), "paused")
			tvl, err := snapshot.ActiveTVL(1)
			require.NoError(t, err)
			require.Equal(t, int64(200), tvl.Int64())
			require.Len(t, reads, chains, "snapshot access must not perform reads")
		})
	}
}

func TestSnapshotBlocksEachChainAndRecoveryMode(t *testing.T) {
	config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{IsParent: true, ChainSelector: 1, ChainName: "parent"}, {ChainSelector: 2, ChainName: "child"}}}
	for _, parentBlocked := range []bool{true, false} {
		for mode := uint8(0); mode <= 5; mode++ {
			snapshot := &Snapshot{Parent: newTestParentState(), Children: map[uint64]child_vault.TypesChildOperationalState{2: newTestChildState()}}
			if parentBlocked {
				snapshot.Parent.Paused = mode == 0
				snapshot.Parent.RecoveryMode = mode
			} else {
				child := snapshot.Children[2]
				child.Paused = mode == 0
				child.RecoveryMode = mode
				snapshot.Children[2] = child
			}
			require.NotEmpty(t, snapshot.BlockedReason(config))
		}
	}
}

func TestReadSnapshotErrors(t *testing.T) {
	for _, parent := range []bool{true, false} {
		for _, bindingFailure := range []bool{true, false} {
			config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{IsParent: parent, ChainSelector: 1}}}
			failure := errors.New("RPC unavailable")
			snapshot, err := readSnapshot(config, newMockRuntime(t),
				func(*evm.Client, string) (ParentVaultInterface, error) {
					if bindingFailure {
						return nil, failure
					}
					return testParentReader{err: failure, onRead: func(*big.Int) {}}, nil
				},
				func(*evm.Client, string) (ChildVaultInterface, error) {
					if bindingFailure {
						return nil, failure
					}
					return testChildReader{err: failure, onRead: func(*big.Int) {}}, nil
				},
			)
			require.ErrorIs(t, err, failure)
			require.Nil(t, snapshot)
		}
	}
}

func TestSnapshotRejectsMissingOrMalformedState(t *testing.T) {
	config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{IsParent: true, ChainSelector: 1}, {ChainSelector: 2}}}
	snapshot := &Snapshot{Parent: newTestParentState(), Children: map[uint64]child_vault.TypesChildOperationalState{2: newTestChildState()}}
	require.NoError(t, snapshot.Validate(config))
	snapshot.Parent.CurrentEpoch.TotalDepositAmount = nil
	require.Error(t, snapshot.Validate(config))
	snapshot.Parent = newTestParentState()
	delete(snapshot.Children, 2)
	require.Error(t, snapshot.Validate(config))
	_, err := snapshot.ActiveTVL(1)
	require.Error(t, err)
}

func TestMatchSourceDistinguishesIdenticalAddressesAcrossChains(t *testing.T) {
	config := &helper.Config{BlockNumber: new(int64), Evms: []helper.EvmConfig{{ChainSelector: 2, VaultAddress: validVaultAddress}, {ChainSelector: 3, VaultAddress: validVaultAddress}}}
	log := &evm.Log{Address: common.HexToAddress(validVaultAddress).Bytes()}
	require.True(t, MatchSource(config, log, 2, 2))
	require.False(t, MatchSource(config, log, 3, 2))
	require.False(t, MatchSource(config, nil, 2, 2))
}

func FuzzPeriodElapsed(f *testing.F) {
	f.Add(uint64(100), int64(3700))
	f.Add(^uint64(0), int64(0))
	f.Fuzz(func(t *testing.T, opened uint64, now int64) {
		openedAt := new(big.Int).SetUint64(opened)
		deadline := new(big.Int).Add(openedAt, big.NewInt(3600))
		require.Equal(t, now >= 0 && big.NewInt(now).Cmp(deadline) >= 0, PeriodElapsed(openedAt, now, 3600))
	})
}
