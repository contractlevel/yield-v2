package rebalance

import (
	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/offchain"
	"cre/workflow/internal/onchain"
	"errors"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
	"math/big"
	"testing"
)

var errTestCodec = errors.New("codec failed")

type failingParentEncoder struct{ parentCodec }

func (f failingParentEncoder) EncodeInitiateRebalanceMethodCall(parent_vault.InitiateRebalanceInput) ([]byte, error) {
	return nil, errTestCodec
}
func (f failingParentEncoder) EncodeCompleteRebalanceMethodCall(parent_vault.CompleteRebalanceInput) ([]byte, error) {
	return nil, errTestCodec
}

type failingChildEncoder struct{ childCodec }

func (f failingChildEncoder) EncodeExecuteRebalanceMethodCall(child_vault.ExecuteRebalanceInput) ([]byte, error) {
	return nil, errTestCodec
}

func TestRebalanceHandlerErrors(t *testing.T) {
	for _, handler := range []string{"cron", "execute", "complete"} {
		for _, scenario := range []string{"parent codec", "child codec", "missing parent", "decode", "encode", "submit"} {
			if scenario == "child codec" && handler != "execute" || scenario == "decode" && handler == "cron" {
				continue
			}
			t.Run(handler+"/"+scenario, func(t *testing.T) {
				config, snapshot := newTestConfig(), newTestSnapshot()
				snapshot.Parent.Rebalance.State = onchain.Rebalancing
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
				case "cron":
					snapshot.Parent.Rebalance.State = onchain.RebalanceNone
					deps := CronDeps{SubmitReport: recorder.submit, FetchAndSelectPools: func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
						return &offchain.Pool{Project: "compound-v3", Chain: "Arbitrum", Apy: 6}, &offchain.Pool{Project: "aave-v3", Chain: "Ethereum", Apy: 4}, nil
					}}
					_, err = onRebalanceCronTriggerWithDeps(config, runtime, nil, snapshot, deps)
				case "execute":
					pending := snapshot.Parent.Rebalance.PendingStrategy
					log := newTestRebalanceLog(config.Evms[0], "RebalanceInitiated(uint256,bytes32,uint64)", big.NewInt(7).Bytes(), pending.ProtocolId[:], big.NewInt(3).Bytes())
					if scenario == "decode" {
						log = &evm.Log{Topics: [][]byte{make([]byte, 32)}}
					}
					_, err = onRebalanceInitiatedWithDeps(config, runtime, log, snapshot, 1, recorder.submit)
				case "complete":
					log := newTestRebalanceLog(config.Evms[2], "RebalanceDepositSuccess(uint256,uint256)", big.NewInt(7).Bytes(), big.NewInt(100).Bytes())
					if scenario == "decode" {
						log = &evm.Log{Topics: [][]byte{make([]byte, 32)}}
					}
					_, err = onRebalanceDepositSuccessWithDeps(config, runtime, log, snapshot, 3, recorder.submit)
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

func TestRebalanceInitiatedAdditionalGuards(t *testing.T) {
	for _, test := range []struct {
		name                           string
		source, active, pending, event uint64
		reason                         string
		fails                          bool
	}{
		{"wrong source", 2, 2, 3, 3, "wrong rebalance event source", false},
		{"destination mismatch", 1, 2, 3, 2, "destination mismatch", false},
		{"unknown source strategy", 1, 99, 3, 3, "find prev strategy chain", true},
		{"zero destination", 1, 2, 0, 0, "no evm config found for chainSelector 0", true},
		{"unknown destination", 1, 2, 99, 99, "no evm config", true},
	} {
		t.Run(test.name, func(t *testing.T) {
			config, snapshot := newTestConfig(), newTestSnapshot()
			snapshot.Parent.Rebalance.State = onchain.Rebalancing
			snapshot.Parent.Rebalance.ActiveStrategy.ChainSelector = test.active
			snapshot.Parent.Rebalance.PendingStrategy.ChainSelector = test.pending
			pending := snapshot.Parent.Rebalance.PendingStrategy
			log := newTestRebalanceLog(config.Evms[0], "RebalanceInitiated(uint256,bytes32,uint64)", big.NewInt(7).Bytes(), pending.ProtocolId[:], new(big.Int).SetUint64(test.event).Bytes())
			recorder := &testReportRecorder{}
			result, err := onRebalanceInitiatedWithDeps(config, testutils.NewRuntime(t, testutils.Secrets{}), log, snapshot, test.source, recorder.submit)
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

func TestRebalanceCronPublicEntrypoint(t *testing.T) {
	config, snapshot := newTestConfig(), newTestSnapshot()
	snapshot.Parent.Rebalance.State = onchain.Rebalancing
	result, err := OnRebalanceCronTrigger(config, testutils.NewRuntime(t, testutils.Secrets{}), nil, snapshot)
	require.NoError(t, err)
	require.Contains(t, result.Result, "rebalance in progress")
}

func TestRebalanceRejectsUnknownPoolChain(t *testing.T) {
	recorder := &testReportRecorder{}
	deps := CronDeps{SubmitReport: recorder.submit, FetchAndSelectPools: func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
		return &offchain.Pool{Project: "compound-v3", Chain: "unknown", Apy: 6}, &offchain.Pool{Apy: 4}, nil
	}}
	_, err := onRebalanceCronTriggerWithDeps(newTestConfig(), testutils.NewRuntime(t, testutils.Secrets{}), nil, newTestSnapshot(), deps)
	require.ErrorContains(t, err, "map best pool chain")
	require.Zero(t, recorder.calls)
}

func TestRebalanceEventEntrypointsRejectStaleEvents(t *testing.T) {
	config, snapshot := newTestConfig(), newTestSnapshot()
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	pending := snapshot.Parent.Rebalance.PendingStrategy
	log := newTestRebalanceLog(config.Evms[0], "RebalanceInitiated(uint256,bytes32,uint64)", big.NewInt(99).Bytes(), pending.ProtocolId[:], big.NewInt(3).Bytes())
	result, err := OnRebalanceInitiated(config, runtime, log, snapshot, 1)
	require.NoError(t, err)
	require.Contains(t, result.Result, "stale rebalance")
	log = newTestRebalanceLog(config.Evms[2], "RebalanceDepositSuccess(uint256,uint256)", big.NewInt(99).Bytes(), big.NewInt(100).Bytes())
	result, err = OnRebalanceDepositSuccess(config, runtime, log, snapshot, 3)
	require.NoError(t, err)
	require.Contains(t, result.Result, "stale rebalance")
}
