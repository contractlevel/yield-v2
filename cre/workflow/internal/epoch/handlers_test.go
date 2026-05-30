package epoch

import (
	"errors"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/onchain"
)

const (
	parentChainSelector uint64 = 1
	childChainSelector  uint64 = 2
)

var aaveProtocolID = [32]byte{1}

type fakeParentCodec struct {
	closeErr           error
	closeCalldata      []byte
	closeInput         parent_vault.CloseEpochInput
	epochExecuting     *parent_vault.EpochExecutingDecoded
	decodeExecutingErr error
}

func (f *fakeParentCodec) EncodeCloseEpochMethodCall(in parent_vault.CloseEpochInput) ([]byte, error) {
	f.closeInput = in
	if f.closeErr != nil {
		return nil, f.closeErr
	}
	return f.closeCalldata, nil
}

func (f *fakeParentCodec) DecodeEpochExecuting(*evm.Log) (*parent_vault.EpochExecutingDecoded, error) {
	if f.decodeExecutingErr != nil {
		return nil, f.decodeExecutingErr
	}
	return f.epochExecuting, nil
}

type fakeChildCodec struct {
	withdrawErr      error
	withdrawCalldata []byte
	withdrawInput    child_vault.ExecuteEpochWithdrawInput
}

func (f *fakeChildCodec) EncodeExecuteEpochWithdrawMethodCall(in child_vault.ExecuteEpochWithdrawInput) ([]byte, error) {
	f.withdrawInput = in
	if f.withdrawErr != nil {
		return nil, f.withdrawErr
	}
	return f.withdrawCalldata, nil
}

type fakeParentVault struct{}

func (fakeParentVault) GetTVL(cre.Runtime, *big.Int) cre.Promise[*big.Int] {
	return cre.PromiseFromResult(big.NewInt(0), nil)
}

func (fakeParentVault) GetRebalance(cre.Runtime, *big.Int) cre.Promise[parent_vault.TypesRebalance] {
	return cre.PromiseFromResult(parent_vault.TypesRebalance{}, nil)
}

func (fakeParentVault) GetEpochNonce(cre.Runtime, *big.Int) cre.Promise[*big.Int] {
	return cre.PromiseFromResult(big.NewInt(0), nil)
}

func (fakeParentVault) GetEpoch(cre.Runtime, parent_vault.GetEpochInput, *big.Int) cre.Promise[parent_vault.TypesEpoch] {
	return cre.PromiseFromResult(parent_vault.TypesEpoch{}, nil)
}

type fakeChildVault struct{}

func (fakeChildVault) GetTVL(cre.Runtime, *big.Int) cre.Promise[*big.Int] {
	return cre.PromiseFromResult(big.NewInt(0), nil)
}

func testConfig() *helper.Config {
	return &helper.Config{
		BlockNumber: -2,
		Evms: []helper.EvmConfig{
			{
				IsParent:              true,
				ChainName:             "ethereum-mainnet-arbitrum-1",
				ChainSelector:         parentChainSelector,
				VaultAddress:          "0x0000000000000000000000000000000000000003",
				WorkflowRouterAddress: "0x0000000000000000000000000000000000000004",
				GasLimit:              600_000,
			},
			{
				ChainName:             "ethereum-mainnet",
				ChainSelector:         childChainSelector,
				VaultAddress:          "0x0000000000000000000000000000000000000001",
				WorkflowRouterAddress: "0x0000000000000000000000000000000000000002",
				GasLimit:              500_000,
			},
		},
	}
}

func resetSeams(t *testing.T) {
	t.Helper()

	origParentCodec := newParentCodec
	origChildCodec := newChildCodec
	origParentBinding := newParentVaultBinding
	origChildBinding := newChildVaultBinding
	origInitiatorDeps := defaultInitiatorDeps
	origExecutorDeps := defaultExecutorDeps
	t.Cleanup(func() {
		newParentCodec = origParentCodec
		newChildCodec = origChildCodec
		newParentVaultBinding = origParentBinding
		newChildVaultBinding = origChildBinding
		defaultInitiatorDeps = origInitiatorDeps
		defaultExecutorDeps = origExecutorDeps
	})
}

func installParentCodec(t *testing.T, codec parentCodec) {
	t.Helper()
	newParentCodec = func() (parentCodec, error) { return codec, nil }
}

func installChildCodec(t *testing.T, codec childCodec) {
	t.Helper()
	newChildCodec = func() (childCodec, error) { return codec, nil }
}

func installBindings(t *testing.T) {
	t.Helper()
	newParentVaultBinding = func(*evm.Client, string) (onchain.ParentVaultInterface, error) {
		return fakeParentVault{}, nil
	}
	newChildVaultBinding = func(*evm.Client, string) (onchain.ChildVaultInterface, error) {
		return fakeChildVault{}, nil
	}
}

func testRuntime(t *testing.T) *testutils.TestRuntime {
	t.Helper()
	runtime := testutils.NewRuntime(t, nil)
	runtime.SetTimeProvider(func() time.Time { return time.Unix(10_000, 0) })
	return runtime
}

func openEpoch(openedAt int64) parent_vault.TypesEpoch {
	return parent_vault.TypesEpoch{
		Status:               1,
		TotalDepositAmount:   big.NewInt(1),
		TotalShareBurnAmount: big.NewInt(0),
		OpenedAtTimestamp:    big.NewInt(openedAt),
	}
}

func rebalanceState(chainSelector uint64) parent_vault.TypesRebalance {
	return parent_vault.TypesRebalance{
		ActiveStrategy: parent_vault.TypesStrategy{
			ProtocolId:    aaveProtocolID,
			ChainSelector: chainSelector,
		},
	}
}

func baseInitiatorDeps() InitiatorDeps {
	return InitiatorDeps{
		GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
			return rebalanceState(parentChainSelector), nil
		},
		GetEpochNonce: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (*big.Int, error) {
			return big.NewInt(1), nil
		},
		GetEpoch: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
			return openEpoch(0), nil
		},
		ReadTVL: func(cre.Runtime, onchain.BaseVaultInterface, *big.Int) (*big.Int, error) {
			return big.NewInt(100), nil
		},
		SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
			return nil
		},
	}
}

func Test_OnEpochCronTrigger_wrapper(t *testing.T) {
	resetSeams(t)
	installParentCodec(t, &fakeParentCodec{closeCalldata: []byte{1}})
	installBindings(t)
	defaultInitiatorDeps = baseInitiatorDeps()

	result, err := OnEpochCronTrigger(testConfig(), testRuntime(t), nil)
	require.NoError(t, err, "expected wrapper to use default deps")
	require.Equal(t, "closed epoch", result.Result)
}

func Test_DefaultSeams(t *testing.T) {
	resetSeams(t)

	parentCodec, err := newParentCodec()
	require.NoError(t, err, "expected default parent codec constructor to succeed")
	require.NotNil(t, parentCodec, "expected parent codec")

	childCodec, err := newChildCodec()
	require.NoError(t, err, "expected default child codec constructor to succeed")
	require.NotNil(t, childCodec, "expected child codec")

	parentBinding, err := newParentVaultBinding(nil, "0x0000000000000000000000000000000000000001")
	require.NoError(t, err, "expected default parent binding constructor to succeed")
	require.NotNil(t, parentBinding, "expected parent binding")

	childBinding, err := newChildVaultBinding(nil, "0x0000000000000000000000000000000000000002")
	require.NoError(t, err, "expected default child binding constructor to succeed")
	require.NotNil(t, childBinding, "expected child binding")
}

func Test_OnEpochCronTrigger_withDeps(t *testing.T) {
	tests := []struct {
		name          string
		config        *helper.Config
		codec         *fakeParentCodec
		codecErr      error
		parentBindErr error
		childBindErr  error
		deps          InitiatorDeps
		wantResult    string
		wantErr       string
	}{
		{name: "codec error", codecErr: errors.New("codec failed"), deps: baseInitiatorDeps(), wantErr: "init parent vault codec: codec failed"},
		{name: "no parent", config: &helper.Config{Evms: []helper.EvmConfig{{ChainSelector: childChainSelector}}}, codec: &fakeParentCodec{}, deps: baseInitiatorDeps(), wantErr: "no parent chain configured"},
		{name: "bind parent error", codec: &fakeParentCodec{}, parentBindErr: errors.New("bind failed"), deps: baseInitiatorDeps(), wantErr: "bind parent vault: bind failed"},
		{
			name:  "get rebalance error",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return parent_vault.TypesRebalance{}, errors.New("read failed")
				}
				return deps
			}(),
			wantErr: "get rebalance: read failed",
		},
		{
			name:  "rebalance in progress",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return parent_vault.TypesRebalance{State: 1}, nil
				}
				return deps
			}(),
			wantResult: "no-op: rebalance in progress",
		},
		{
			name:  "get epoch nonce error",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpochNonce = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (*big.Int, error) {
					return nil, errors.New("nonce failed")
				}
				return deps
			}(),
			wantErr: "get epoch nonce: nonce failed",
		},
		{
			name:  "nil epoch nonce",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpochNonce = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (*big.Int, error) {
					return nil, nil
				}
				return deps
			}(),
			wantErr: "get epoch nonce: nil epoch nonce",
		},
		{
			name:  "get epoch error",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					return parent_vault.TypesEpoch{}, errors.New("epoch failed")
				}
				return deps
			}(),
			wantErr: "get epoch: epoch failed",
		},
		{
			name:  "nil epoch total deposit amount",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					epoch := openEpoch(0)
					epoch.TotalDepositAmount = nil
					return epoch, nil
				}
				return deps
			}(),
			wantErr: "get epoch: nil total deposit amount",
		},
		{
			name:  "nil epoch total share burn amount",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					epoch := openEpoch(0)
					epoch.TotalShareBurnAmount = nil
					return epoch, nil
				}
				return deps
			}(),
			wantErr: "get epoch: nil total share burn amount",
		},
		{
			name:  "nil epoch opened at timestamp",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					epoch := openEpoch(0)
					epoch.OpenedAtTimestamp = nil
					return epoch, nil
				}
				return deps
			}(),
			wantErr: "get epoch: nil opened at timestamp",
		},
		{
			name:  "epoch not open",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					return parent_vault.TypesEpoch{Status: 2}, nil
				}
				return deps
			}(),
			wantResult: "no-op: epoch not open",
		},
		{
			name:  "no activity",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					return parent_vault.TypesEpoch{Status: 1, TotalDepositAmount: big.NewInt(0), TotalShareBurnAmount: big.NewInt(0), OpenedAtTimestamp: big.NewInt(0)}, nil
				}
				return deps
			}(),
			wantResult: "no-op: no activity",
		},
		{
			name:  "too young",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
					return openEpoch(9_999), nil
				}
				return deps
			}(),
			wantResult: "no-op: epoch too young",
		},
		{
			name:  "remote strategy missing",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(999), nil
				}
				return deps
			}(),
			wantErr: "find strategy chain: no evm config found for chainSelector 999",
		},
		{
			name:         "bind child error",
			codec:        &fakeParentCodec{},
			childBindErr: errors.New("child bind failed"),
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(childChainSelector), nil
				}
				return deps
			}(),
			wantErr: "bind child vault: child bind failed",
		},
		{
			name:  "read tvl error",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.ReadTVL = func(cre.Runtime, onchain.BaseVaultInterface, *big.Int) (*big.Int, error) {
					return nil, errors.New("tvl failed")
				}
				return deps
			}(),
			wantErr: "read tvl: tvl failed",
		},
		{
			name:  "nil tvl",
			codec: &fakeParentCodec{},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.ReadTVL = func(cre.Runtime, onchain.BaseVaultInterface, *big.Int) (*big.Int, error) {
					return nil, nil
				}
				return deps
			}(),
			wantErr: "read tvl: nil tvl",
		},
		{name: "encode close error", codec: &fakeParentCodec{closeErr: errors.New("encode failed")}, deps: baseInitiatorDeps(), wantErr: "encode closeEpoch: encode failed"},
		{
			name:  "submit error",
			codec: &fakeParentCodec{closeCalldata: []byte{1}},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.SubmitReport = func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
					return errors.New("submit failed")
				}
				return deps
			}(),
			wantErr: "submit closeEpoch: submit failed",
		},
		{name: "local success", codec: &fakeParentCodec{closeCalldata: []byte{1}}, deps: baseInitiatorDeps(), wantResult: "closed epoch"},
		{
			name:  "remote success",
			codec: &fakeParentCodec{closeCalldata: []byte{1}},
			deps: func() InitiatorDeps {
				deps := baseInitiatorDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(childChainSelector), nil
				}
				return deps
			}(),
			wantResult: "closed epoch",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			resetSeams(t)
			cfg := tt.config
			if cfg == nil {
				cfg = testConfig()
			}
			if tt.codecErr != nil {
				newParentCodec = func() (parentCodec, error) { return nil, tt.codecErr }
			} else {
				installParentCodec(t, tt.codec)
			}
			newParentVaultBinding = func(*evm.Client, string) (onchain.ParentVaultInterface, error) {
				if tt.parentBindErr != nil {
					return nil, tt.parentBindErr
				}
				return fakeParentVault{}, nil
			}
			newChildVaultBinding = func(*evm.Client, string) (onchain.ChildVaultInterface, error) {
				if tt.childBindErr != nil {
					return nil, tt.childBindErr
				}
				return fakeChildVault{}, nil
			}

			result, err := onEpochCronTriggerWithDeps(cfg, testRuntime(t), nil, tt.deps)
			if tt.wantErr != "" {
				require.Error(t, err, "expected error")
				require.Nil(t, result, "expected nil result on error")
				require.ErrorContains(t, err, tt.wantErr)
				return
			}
			require.NoError(t, err, "expected no error")
			require.Equal(t, tt.wantResult, result.Result)
		})
	}
}

func baseExecutorDeps() ExecutorDeps {
	return ExecutorDeps{
		GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
			return rebalanceState(childChainSelector), nil
		},
		SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
			return nil
		},
	}
}

func Test_OnEpochExecuting_wrapper(t *testing.T) {
	resetSeams(t)
	installParentCodec(t, &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{EpochNonce: big.NewInt(1), Amount: big.NewInt(2)}})
	installChildCodec(t, &fakeChildCodec{withdrawCalldata: []byte{1}})
	installBindings(t)
	defaultExecutorDeps = baseExecutorDeps()

	result, err := OnEpochExecuting(testConfig(), testRuntime(t), &evm.Log{})
	require.NoError(t, err, "expected wrapper to use default deps")
	require.Equal(t, "submitted executeEpochWithdraw", result.Result)
}

func Test_OnEpochExecuting_withDeps(t *testing.T) {
	tests := []struct {
		name        string
		config      *helper.Config
		parentCodec *fakeParentCodec
		childCodec  *fakeChildCodec
		parentErr   error
		childErr    error
		bindingErr  error
		deps        ExecutorDeps
		wantResult  string
		wantErr     string
	}{
		{name: "parent codec error", parentErr: errors.New("codec failed"), deps: baseExecutorDeps(), wantErr: "init parent vault codec: codec failed"},
		{name: "child codec error", parentCodec: &fakeParentCodec{}, childErr: errors.New("child failed"), deps: baseExecutorDeps(), wantErr: "init child vault codec: child failed"},
		{name: "decode error", parentCodec: &fakeParentCodec{decodeExecutingErr: errors.New("decode failed")}, childCodec: &fakeChildCodec{}, deps: baseExecutorDeps(), wantErr: "decode EpochExecuting: decode failed"},
		{name: "no parent", config: &helper.Config{Evms: []helper.EvmConfig{{ChainSelector: childChainSelector}}}, parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}}, childCodec: &fakeChildCodec{}, deps: baseExecutorDeps(), wantErr: "no parent chain configured"},
		{name: "bind error", parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}}, childCodec: &fakeChildCodec{}, bindingErr: errors.New("bind failed"), deps: baseExecutorDeps(), wantErr: "bind parent vault: bind failed"},
		{
			name:        "get rebalance error",
			parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}},
			childCodec:  &fakeChildCodec{},
			deps: ExecutorDeps{
				GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return parent_vault.TypesRebalance{}, errors.New("read failed")
				},
				SubmitReport: baseExecutorDeps().SubmitReport,
			},
			wantErr: "get rebalance: read failed",
		},
		{
			name:        "strategy missing",
			parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}},
			childCodec:  &fakeChildCodec{},
			deps: ExecutorDeps{
				GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(999), nil
				},
				SubmitReport: baseExecutorDeps().SubmitReport,
			},
			wantErr: "find strategy chain: no evm config found for chainSelector 999",
		},
		{
			name:        "active strategy on parent",
			parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{EpochNonce: big.NewInt(1)}},
			childCodec:  &fakeChildCodec{},
			deps: ExecutorDeps{
				GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(parentChainSelector), nil
				},
				SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
					t.Fatal("SubmitReport must not be called when active strategy is on parent")
					return nil
				},
			},
			wantResult: "no-op: active strategy on parent",
		},
		{name: "encode error", parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}}, childCodec: &fakeChildCodec{withdrawErr: errors.New("encode failed")}, deps: baseExecutorDeps(), wantErr: "encode executeEpochWithdraw: encode failed"},
		{
			name:        "submit error",
			parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{}},
			childCodec:  &fakeChildCodec{withdrawCalldata: []byte{1}},
			deps: ExecutorDeps{
				GetRebalance: baseExecutorDeps().GetRebalance,
				SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
					return errors.New("submit failed")
				},
			},
			wantErr: "submit executeEpochWithdraw: submit failed",
		},
		{name: "success", parentCodec: &fakeParentCodec{epochExecuting: &parent_vault.EpochExecutingDecoded{EpochNonce: big.NewInt(1), Amount: big.NewInt(2)}}, childCodec: &fakeChildCodec{withdrawCalldata: []byte{1}}, deps: baseExecutorDeps(), wantResult: "submitted executeEpochWithdraw"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			resetSeams(t)
			cfg := tt.config
			if cfg == nil {
				cfg = testConfig()
			}
			if tt.parentErr != nil {
				newParentCodec = func() (parentCodec, error) { return nil, tt.parentErr }
			} else {
				installParentCodec(t, tt.parentCodec)
			}
			if tt.childErr != nil {
				newChildCodec = func() (childCodec, error) { return nil, tt.childErr }
			} else {
				installChildCodec(t, tt.childCodec)
			}
			newParentVaultBinding = func(*evm.Client, string) (onchain.ParentVaultInterface, error) {
				if tt.bindingErr != nil {
					return nil, tt.bindingErr
				}
				return fakeParentVault{}, nil
			}

			result, err := onEpochExecutingWithDeps(cfg, testRuntime(t), &evm.Log{}, tt.deps)
			if tt.wantErr != "" {
				require.Error(t, err, "expected error")
				require.Nil(t, result, "expected nil result on error")
				require.ErrorContains(t, err, tt.wantErr)
				return
			}
			require.NoError(t, err, "expected no error")
			require.Equal(t, tt.wantResult, result.Result)
		})
	}
}
