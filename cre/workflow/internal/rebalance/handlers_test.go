package rebalance

import (
	"errors"
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/offchain"
	"cre/workflow/internal/onchain"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

func newTestConfig() *helper.Config {
	decimals := uint8(6)
	return &helper.Config{
		AssetDecimals: &decimals,
		DefiLlama:     helper.DefiLlama{PoolIDs: []string{"a", "b"}, Projects: []string{"aave-v3", "compound-v3"}, Symbols: []string{"USDC"}},
		Evms: []helper.EvmConfig{
			{IsParent: true, ChainSelector: 1, VaultAddress: "0x0000000000000000000000000000000000000001", DefiLlamaChainName: "Base"},
			{ChainSelector: 2, VaultAddress: "0x0000000000000000000000000000000000000002", DefiLlamaChainName: "Ethereum"},
			{ChainSelector: 3, VaultAddress: "0x0000000000000000000000000000000000000003", DefiLlamaChainName: "Arbitrum"},
		},
	}
}

func newTestSnapshot() *onchain.Snapshot {
	return &onchain.Snapshot{
		ObservedAt: 10_000,
		Parent: parent_vault.TypesParentOperationalState{
			CurrentEpochNonce: big.NewInt(2),
			PreviousEpoch:     parent_vault.TypesEpoch{Status: onchain.EpochClaimable},
			Tvl:               big.NewInt(100),
			Rebalance: parent_vault.TypesRebalance{
				Nonce:                           big.NewInt(7),
				LastRebalanceCompletedTimestamp: big.NewInt(1),
				ActiveStrategy:                  parent_vault.TypesStrategy{ProtocolId: offchain.PoolToProtocolId("aave-v3"), ChainSelector: 2},
				PendingStrategy:                 parent_vault.TypesStrategy{ProtocolId: offchain.PoolToProtocolId("compound-v3"), ChainSelector: 3},
			},
		},
		Children: map[uint64]child_vault.TypesChildOperationalState{
			2: {LastHandledRebalanceNonce: big.NewInt(2)},
			3: {LastHandledRebalanceNonce: big.NewInt(0)},
		},
	}
}

type testReportRecorder struct {
	calls      int
	target     helper.EvmConfig
	observedAt int64
	calldata   []byte
	err        error
}

func (r *testReportRecorder) submit(_ cre.Runtime, target helper.EvmConfig, observedAt int64, calldata []byte) error {
	r.calls++
	r.target, r.observedAt, r.calldata = target, observedAt, calldata
	return r.err
}

func newTestRebalanceLog(config helper.EvmConfig, signature string, topics ...[]byte) *evm.Log {
	log := &evm.Log{Address: common.HexToAddress(config.VaultAddress).Bytes(), Topics: [][]byte{crypto.Keccak256([]byte(signature))}}
	for _, topic := range topics {
		log.Topics = append(log.Topics, common.LeftPadBytes(topic, 32))
	}
	return log
}

func TestRebalanceCronChecksAndCalldata(t *testing.T) {
	for _, test := range []struct {
		name   string
		change func(*onchain.Snapshot)
		reason string
	}{
		{"success", func(*onchain.Snapshot) {}, ""},
		{"rebalance", func(s *onchain.Snapshot) { s.Parent.Rebalance.State = onchain.Rebalancing }, "rebalance in progress"},
		{"no completed epoch", func(s *onchain.Snapshot) { s.Parent.CurrentEpochNonce = big.NewInt(1) }, "no completed epoch"},
		{"executing epoch", func(s *onchain.Snapshot) { s.Parent.PreviousEpoch.Status = onchain.EpochExecuting }, "epoch executing"},
		{"cooldown", func(s *onchain.Snapshot) { s.Parent.Rebalance.LastRebalanceCompletedTimestamp = big.NewInt(9999) }, "cooldown"},
		{"empty local position", func(s *onchain.Snapshot) {
			s.Parent.Rebalance.ActiveStrategy.ChainSelector = 1
			s.Parent.Tvl = big.NewInt(0)
		}, "zero local"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			test.change(snapshot)
			recorder := &testReportRecorder{}
			fetches := 0
			deps := CronDeps{SubmitReport: recorder.submit, FetchAndSelectPools: func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
				fetches++
				return &offchain.Pool{Project: "compound-v3", Chain: "Arbitrum", Apy: 6}, &offchain.Pool{Project: "aave-v3", Chain: "Ethereum", Apy: 4}, nil
			}}
			result, err := onRebalanceCronTriggerWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), nil, snapshot, deps)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				require.Zero(t, fetches)
				return
			}
			require.Equal(t, 1, recorder.calls)
			require.Equal(t, uint64(1), recorder.target.ChainSelector)
			require.Equal(t, snapshot.ObservedAt, recorder.observedAt)
			codec, err := parent_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeInitiateRebalanceMethodCall(parent_vault.InitiateRebalanceInput{
				ExpectedRebalanceNonce: big.NewInt(7), NewStrategy: snapshot.Parent.Rebalance.PendingStrategy,
			})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
		})
	}
}

func TestRebalancePoolSelectionNoopsAndErrors(t *testing.T) {
	for _, test := range []struct {
		name          string
		best, current *offchain.Pool
		fetchErr      error
		reason        string
	}{
		{"no best", nil, nil, nil, "no approved pool"},
		{"missing current", &offchain.Pool{Project: "compound-v3", Chain: "Arbitrum", Apy: 6}, nil, nil, "current pool missing"},
		{"already optimal", &offchain.Pool{Project: "aave-v3", Chain: "Ethereum", Apy: 6}, nil, nil, "already optimal"},
		{"below threshold", &offchain.Pool{Project: "compound-v3", Chain: "Arbitrum", Apy: 4.5}, &offchain.Pool{Apy: 4}, nil, "below threshold"},
		{"fetch failure", nil, nil, errors.New("relay failed"), ""},
	} {
		t.Run(test.name, func(t *testing.T) {
			recorder := &testReportRecorder{}
			deps := CronDeps{SubmitReport: recorder.submit, FetchAndSelectPools: func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
				return test.best, test.current, test.fetchErr
			}}
			result, err := onRebalanceCronTriggerWithDeps(newTestConfig(), testutils.NewRuntime(t, testutils.Secrets{}), nil, newTestSnapshot(), deps)
			if test.fetchErr != nil {
				require.ErrorIs(t, err, test.fetchErr)
			} else {
				require.NoError(t, err)
				require.Contains(t, result.Result, test.reason)
			}
			require.Zero(t, recorder.calls)
		})
	}
}

func TestRebalanceInitiatedUsesEventAndSourceChild(t *testing.T) {
	for _, test := range []struct {
		name        string
		nonce       int64
		lastHandled int64
		activeChain uint64
		state       uint8
		reason      string
	}{
		{"success with skipped child nonces", 7, 2, 2, onchain.Rebalancing, ""},
		{"stale event", 6, 2, 2, onchain.Rebalancing, "stale"},
		{"duplicate", 7, 7, 2, onchain.Rebalancing, "already handled"},
		{"newer handled", 7, 8, 2, onchain.Rebalancing, "already handled"},
		{"parent active", 7, 2, 1, onchain.Rebalancing, "active strategy on parent"},
		{"completed", 7, 2, 2, onchain.RebalanceNone, "stale"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			snapshot.Parent.Rebalance.State = test.state
			snapshot.Parent.Rebalance.ActiveStrategy.ChainSelector = test.activeChain
			snapshot.Children[2] = child_vault.TypesChildOperationalState{LastHandledRebalanceNonce: big.NewInt(test.lastHandled)}
			pending := snapshot.Parent.Rebalance.PendingStrategy
			log := newTestRebalanceLog(config.Evms[0], "RebalanceInitiated(uint256,bytes32,uint64)", big.NewInt(test.nonce).Bytes(), pending.ProtocolId[:], big.NewInt(3).Bytes())
			recorder := &testReportRecorder{}
			result, err := onRebalanceInitiatedWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, 1, recorder.submit)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				return
			}
			require.Equal(t, uint64(2), recorder.target.ChainSelector)
			codec, err := child_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeExecuteRebalanceMethodCall(child_vault.ExecuteRebalanceInput{
				RebalanceNonce: big.NewInt(7), NewStrategy: child_vault.TypesStrategy{ProtocolId: pending.ProtocolId, ChainSelector: 3},
			})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
		})
	}
}

func TestRebalanceCompletionChecksSourceAndNonce(t *testing.T) {
	for _, test := range []struct {
		name   string
		source uint64
		nonce  int64
		reason string
	}{
		{"success", 3, 7, ""},
		{"stale", 3, 6, "stale"},
		{"wrong child", 2, 7, "wrong rebalance destination"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			config.Evms[1].VaultAddress = config.Evms[2].VaultAddress
			snapshot.Parent.Rebalance.State = onchain.Rebalancing
			log := newTestRebalanceLog(config.Evms[2], "RebalanceDepositSuccess(uint256,uint256)", big.NewInt(test.nonce).Bytes(), big.NewInt(100).Bytes())
			recorder := &testReportRecorder{}
			result, err := onRebalanceDepositSuccessWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, test.source, recorder.submit)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				return
			}
			require.Equal(t, uint64(1), recorder.target.ChainSelector)
			codec, err := parent_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeCompleteRebalanceMethodCall(parent_vault.CompleteRebalanceInput{ExpectedRebalanceNonce: big.NewInt(7)})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
		})
	}
}
