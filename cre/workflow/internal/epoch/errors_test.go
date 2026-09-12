package epoch

import (
	"errors"
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

var errTestCodec = errors.New("codec failed")

type failingParentEncoder struct{ parentCodec }

func (f failingParentEncoder) EncodeCloseEpochMethodCall(parent_vault.CloseEpochInput) ([]byte, error) {
	return nil, errTestCodec
}
func (f failingParentEncoder) EncodeCompleteEpochDepositMethodCall(parent_vault.CompleteEpochDepositInput) ([]byte, error) {
	return nil, errTestCodec
}

type failingChildEncoder struct{ childCodec }

func (f failingChildEncoder) EncodeExecuteEpochWithdrawMethodCall(child_vault.ExecuteEpochWithdrawInput) ([]byte, error) {
	return nil, errTestCodec
}

func TestEpochHandlerErrors(t *testing.T) {
	for _, handler := range []string{"close", "withdraw", "deposit"} {
		for _, scenario := range []string{"parent codec", "child codec", "missing parent", "decode", "encode", "submit"} {
			if handler == "close" && (scenario == "child codec" || scenario == "decode") {
				continue
			}
			t.Run(handler+"/"+scenario, func(t *testing.T) {
				config, snapshot := newTestConfig(), newTestSnapshot()
				snapshot.Parent.PreviousEpoch.Status = onchain.EpochExecuting
				parentFactory, childFactory := newParentCodec, newChildCodec
				t.Cleanup(func() { newParentCodec, newChildCodec = parentFactory, childFactory })
				recorder := &testReportRecorder{}
				switch scenario {
				case "parent codec":
					newParentCodec = func() (parentCodec, error) { return nil, errTestCodec }
				case "child codec":
					newChildCodec = func() (childCodec, error) { return nil, errTestCodec }
				case "missing parent":
					config.Evms[0].IsParent = false
				case "encode":
					newParentCodec = func() (parentCodec, error) { c, e := parentFactory(); return failingParentEncoder{c}, e }
					newChildCodec = func() (childCodec, error) { c, e := childFactory(); return failingChildEncoder{c}, e }
				case "submit":
					recorder.err = errors.New("write failed")
				}
				runtime := testutils.NewRuntime(t, testutils.Secrets{})
				var err error
				switch handler {
				case "close":
					snapshot.Parent.PreviousEpoch.Status = onchain.EpochClaimable
					_, err = onEpochCronTriggerWithDeps(config, runtime, nil, snapshot, recorder.submit)
				case "withdraw":
					snapshot.Parent.PreviousEpoch.TotalWithdrawClaimAmount = big.NewInt(2_000_000)
					log := newTestEpochLog(config.Evms[0], "EpochWithdrawExecuting(uint256,uint256)", 1, 1_000_000)
					if scenario == "decode" {
						log = &evm.Log{Topics: [][]byte{make([]byte, 32)}}
					}
					_, err = onEpochWithdrawExecutingWithDeps(config, runtime, log, snapshot, 1, recorder.submit)
				case "deposit":
					log := newTestEpochLog(config.Evms[1], "EpochDepositToStrategySuccess(uint256,uint256)", 1, 1_000_000)
					if scenario == "decode" {
						log = &evm.Log{Topics: [][]byte{make([]byte, 32)}}
					}
					_, err = onEpochDepositToStrategySuccessWithDeps(config, runtime, log, snapshot, 2, recorder.submit)
				}
				require.Error(t, err)
				switch scenario {
				case "parent codec", "child codec", "encode":
					require.ErrorIs(t, err, errTestCodec)
				case "submit":
					require.ErrorIs(t, err, recorder.err)
				case "missing parent":
					require.ErrorContains(t, err, "no parent")
				case "decode":
					require.ErrorContains(t, err, "decode")
				}
				if scenario != "submit" {
					require.Zero(t, recorder.calls)
				}
			})
		}
	}
}

func TestEpochWithdrawAdditionalGuards(t *testing.T) {
	for _, test := range []struct {
		name   string
		change func(*onchain.Snapshot)
		source uint64
		reason string
		fails  bool
	}{
		{"wrong source", func(*onchain.Snapshot) {}, 2, "wrong epoch event source", false},
		{"rebalance", func(s *onchain.Snapshot) { s.Parent.Rebalance.State = onchain.Rebalancing }, 1, "rebalance in progress", false},
		{"local", func(s *onchain.Snapshot) { s.Parent.Rebalance.ActiveStrategy.ChainSelector = 1 }, 1, "active strategy on parent", false},
		{"unknown strategy", func(s *onchain.Snapshot) { s.Parent.Rebalance.ActiveStrategy.ChainSelector = 99 }, 1, "find strategy chain", true},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			snapshot.Parent.PreviousEpoch.Status = onchain.EpochExecuting
			snapshot.Parent.PreviousEpoch.TotalWithdrawClaimAmount = big.NewInt(2_000_000)
			test.change(snapshot)
			recorder := &testReportRecorder{}
			log := newTestEpochLog(config.Evms[0], "EpochWithdrawExecuting(uint256,uint256)", 1, 1_000_000)
			result, err := onEpochWithdrawExecutingWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, test.source, recorder.submit)
			if test.fails {
				require.ErrorContains(t, err, test.reason)
			} else {
				require.NoError(t, err)
				require.Contains(t, result.Result, test.reason)
			}
			require.Zero(t, recorder.calls)
		})
	}
}

func TestEpochCronPublicEntrypoint(t *testing.T) {
	config, snapshot := newTestConfig(), newTestSnapshot()
	snapshot.Parent.Rebalance.State = onchain.Rebalancing
	result, err := OnEpochCronTrigger(config, testutils.NewRuntime(t, testutils.Secrets{}), nil, snapshot)
	require.NoError(t, err)
	require.Contains(t, result.Result, "rebalance in progress")
	snapshot.Parent.Rebalance.State = onchain.RebalanceNone
	snapshot.Parent.Rebalance.ActiveStrategy.ChainSelector = 99
	recorder := &testReportRecorder{}
	_, err = onEpochCronTriggerWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), nil, snapshot, recorder.submit)
	require.ErrorContains(t, err, "not configured")
	require.Zero(t, recorder.calls)
}

func TestEpochEventEntrypointsRejectStaleEvents(t *testing.T) {
	config, snapshot := newTestConfig(), newTestSnapshot()
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	log := newTestEpochLog(config.Evms[0], "EpochWithdrawExecuting(uint256,uint256)", 99, 1_000_000)
	result, err := OnEpochWithdrawExecuting(config, runtime, log, snapshot, 1)
	require.NoError(t, err)
	require.Contains(t, result.Result, "stale epoch")
	log = newTestEpochLog(config.Evms[1], "EpochDepositToStrategySuccess(uint256,uint256)", 99, 1_000_000)
	result, err = OnEpochDepositToStrategySuccess(config, runtime, log, snapshot, 2)
	require.NoError(t, err)
	require.Contains(t, result.Result, "stale epoch")
}
