package epoch

import (
	"errors"
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
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
		Evms: []helper.EvmConfig{
			{IsParent: true, ChainSelector: 1, VaultAddress: "0x0000000000000000000000000000000000000001"},
			{ChainSelector: 2, VaultAddress: "0x0000000000000000000000000000000000000002"},
			{ChainSelector: 3, VaultAddress: "0x0000000000000000000000000000000000000003"},
		},
	}
}

func newTestEpoch() parent_vault.TypesEpoch {
	return parent_vault.TypesEpoch{
		TotalDepositAmount:           big.NewInt(1_000_000),
		TotalShareBurnAmount:         new(big.Int),
		TotalWithdrawClaimAmount:     new(big.Int),
		RemainingDepositClaimAmount:  big.NewInt(1_000_000),
		RemainingShareMintAmount:     big.NewInt(1_000_000_000_000_000_000),
		RemainingShareBurnAmount:     new(big.Int),
		RemainingWithdrawClaimAmount: new(big.Int),
		OpenedAtTimestamp:            big.NewInt(1),
		Status:                       onchain.EpochOpen,
	}
}

func newTestSnapshot() *onchain.Snapshot {
	previous := newTestEpoch()
	previous.Status = onchain.EpochClaimable
	return &onchain.Snapshot{
		ObservedAt: 10_000,
		Parent: parent_vault.TypesParentOperationalState{
			CurrentEpochNonce: big.NewInt(2),
			CurrentEpoch:      newTestEpoch(),
			PreviousEpoch:     previous,
			TotalShares:       big.NewInt(1_000_000_000_000_000_000),
			Tvl:               big.NewInt(8_000_000),
			Rebalance: parent_vault.TypesRebalance{
				Nonce:          big.NewInt(7),
				ActiveStrategy: parent_vault.TypesStrategy{ChainSelector: 2},
			},
		},
		Children: map[uint64]child_vault.TypesChildOperationalState{
			2: {LastHandledEpochNonce: new(big.Int), Tvl: big.NewInt(1_000_000)},
			3: {LastHandledEpochNonce: new(big.Int), Tvl: big.NewInt(99_000_000)},
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

func newTestEpochLog(config helper.EvmConfig, signature string, nonce, amount int64) *evm.Log {
	return &evm.Log{
		Address: common.HexToAddress(config.VaultAddress).Bytes(),
		Topics: [][]byte{
			crypto.Keccak256([]byte(signature)),
			common.LeftPadBytes(big.NewInt(nonce).Bytes(), 32),
			common.LeftPadBytes(big.NewInt(amount).Bytes(), 32),
		},
	}
}

func TestEpochCloseGuardsAndActiveTVL(t *testing.T) {
	for _, test := range []struct {
		name   string
		change func(*onchain.Snapshot)
		reason string
	}{
		{"remote", func(*onchain.Snapshot) {}, ""},
		{"local", func(s *onchain.Snapshot) { s.Parent.Rebalance.ActiveStrategy.ChainSelector = 1 }, ""},
		{"rebalance", func(s *onchain.Snapshot) { s.Parent.Rebalance.State = onchain.Rebalancing }, "rebalance"},
		{"previous executing", func(s *onchain.Snapshot) { s.Parent.PreviousEpoch.Status = onchain.EpochExecuting }, "previous epoch not claimable"},
		{"previous absent", func(s *onchain.Snapshot) { s.Parent.PreviousEpoch.Status = 0 }, "previous epoch not claimable"},
		{"first epoch", func(s *onchain.Snapshot) {
			s.Parent.CurrentEpochNonce = big.NewInt(1)
			s.Parent.PreviousEpoch.Status = 0
		}, ""},
		{"closed", func(s *onchain.Snapshot) { s.Parent.CurrentEpoch.Status = onchain.EpochClaimable }, "epoch not open"},
		{"too young", func(s *onchain.Snapshot) { s.Parent.CurrentEpoch.OpenedAtTimestamp = big.NewInt(6401) }, "too young"},
		{"exactly one hour", func(s *onchain.Snapshot) { s.Parent.CurrentEpoch.OpenedAtTimestamp = big.NewInt(6400) }, ""},
		{"empty", func(s *onchain.Snapshot) { s.Parent.CurrentEpoch.TotalDepositAmount = new(big.Int) }, "no epoch activity"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			test.change(snapshot)
			recorder := &testReportRecorder{}
			result, err := onEpochCronTriggerWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), nil, snapshot, recorder.submit)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				return
			}
			require.Equal(t, 1, recorder.calls)
			require.Equal(t, uint64(1), recorder.target.ChainSelector)
			require.Equal(t, snapshot.ObservedAt, recorder.observedAt)
			tvl := snapshot.Children[2].Tvl
			if snapshot.Parent.Rebalance.ActiveStrategy.ChainSelector == 1 {
				tvl = snapshot.Parent.Tvl
			}
			codec, err := parent_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeCloseEpochMethodCall(parent_vault.CloseEpochInput{
				ExpectedEpochNonce: snapshot.Parent.CurrentEpochNonce, Tvl: tvl,
			})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
		})
	}
}

func TestEpochWithdrawEventChecksAndRecovery(t *testing.T) {
	for _, test := range []struct {
		name                        string
		nonce, amount, handled, tvl int64
		reason                      string
	}{
		{"success", 1, 1_000_000, 0, 1_000_000, ""},
		{"insufficient TVL still submits", 1, 1_000_000, 0, 0, ""},
		{"duplicate", 1, 1_000_000, 1, 1_000_000, "already handled"},
		{"stale nonce", 9, 1_000_000, 0, 1_000_000, "stale epoch"},
		{"wrong amount", 1, 999_999, 0, 1_000_000, "amount mismatch"},
		{"zero amount", 1, 0, 0, 1_000_000, "amount mismatch"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			snapshot.Parent.PreviousEpoch.Status = onchain.EpochExecuting
			snapshot.Parent.PreviousEpoch.TotalWithdrawClaimAmount = big.NewInt(2_000_000)
			snapshot.Children[2] = child_vault.TypesChildOperationalState{LastHandledEpochNonce: big.NewInt(test.handled), Tvl: big.NewInt(test.tvl)}
			log := newTestEpochLog(config.Evms[0], "EpochWithdrawExecuting(uint256,uint256)", test.nonce, test.amount)
			recorder := &testReportRecorder{}
			result, err := onEpochWithdrawExecutingWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, 1, recorder.submit)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				return
			}
			codec, err := child_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeExecuteEpochWithdrawMethodCall(child_vault.ExecuteEpochWithdrawInput{EpochNonce: big.NewInt(1), Amount: big.NewInt(1_000_000)})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
			require.Equal(t, uint64(2), recorder.target.ChainSelector)
		})
	}
}

func TestEpochDepositCompletionUsesActualEventAmount(t *testing.T) {
	for _, test := range []struct {
		name          string
		nonce, amount int64
		source        uint64
		reason        string
	}{
		{"exact delivery", 1, 1_000_000, 2, ""},
		{"short delivery", 1, 500_000, 2, ""},
		{"one asset unit", 1, 1, 2, ""},
		{"stale nonce", 2, 1_000_000, 2, "stale epoch"},
		{"zero delivery", 1, 0, 2, "invalid actual"},
		{"excess delivery", 1, 1_000_001, 2, "invalid actual"},
		{"wrong chain same address", 1, 1_000_000, 3, "wrong epoch deposit destination"},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			config.Evms[2].VaultAddress = config.Evms[1].VaultAddress
			snapshot.Parent.PreviousEpoch.Status = onchain.EpochExecuting
			log := newTestEpochLog(config.Evms[1], "EpochDepositToStrategySuccess(uint256,uint256)", test.nonce, test.amount)
			recorder := &testReportRecorder{}
			result, err := onEpochDepositToStrategySuccessWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, test.source, recorder.submit)
			require.NoError(t, err)
			if test.reason != "" {
				require.Contains(t, result.Result, test.reason)
				require.Zero(t, recorder.calls)
				return
			}
			codec, err := parent_vault.NewCodec()
			require.NoError(t, err)
			expected, err := codec.EncodeCompleteEpochDepositMethodCall(parent_vault.CompleteEpochDepositInput{
				ExpectedEpochNonce: big.NewInt(1), ActualDepositAmount: big.NewInt(test.amount),
			})
			require.NoError(t, err)
			require.Equal(t, expected, recorder.calldata)
			require.Equal(t, uint64(1), recorder.target.ChainSelector)
		})
	}
}

func TestEpochClosePropagatesSubmissionError(t *testing.T) {
	failure := errors.New("write failed")
	recorder := &testReportRecorder{err: failure}
	_, err := onEpochCronTriggerWithDeps(newTestConfig(), testutils.NewRuntime(t, testutils.Secrets{}), nil, newTestSnapshot(), recorder.submit)
	require.ErrorIs(t, err, failure)
}
