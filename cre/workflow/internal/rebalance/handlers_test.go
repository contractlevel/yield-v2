package rebalance

import (
	"errors"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/offchain"
	"cre/workflow/internal/onchain"
)

const (
	parentChainSelector uint64 = 1
	childChainSelector  uint64 = 2
)

var (
	aaveProtocolID     = offchain.PoolToProtocolId("aave-v3")
	compoundProtocolID = offchain.PoolToProtocolId("compound-v3")

	aaveParentPool = &offchain.Pool{Chain: "Arbitrum", Project: "aave-v3", Symbol: "USDC", Apy: 5.0}
	compChildPool  = &offchain.Pool{Chain: "Ethereum", Project: "compound-v3", Symbol: "USDC", Apy: 7.0}
)

type fakeParentCodec struct {
	initiateErr        error
	initiateCalldata   []byte
	initiateInput      parent_vault.InitiateRebalanceInput
	rebalanceInitiated *parent_vault.RebalanceInitiatedDecoded
	decodeInitiatedErr error
	depositSuccess     *parent_vault.RebalanceDepositSuccessDecoded
	decodeDepositErr   error
	completeErr        error
	completeCalldata   []byte
	completeInput      parent_vault.CompleteRebalanceInput
}

func (f *fakeParentCodec) EncodeInitiateRebalanceMethodCall(in parent_vault.InitiateRebalanceInput) ([]byte, error) {
	f.initiateInput = in
	if f.initiateErr != nil {
		return nil, f.initiateErr
	}
	return f.initiateCalldata, nil
}

func (f *fakeParentCodec) DecodeRebalanceInitiated(*evm.Log) (*parent_vault.RebalanceInitiatedDecoded, error) {
	if f.decodeInitiatedErr != nil {
		return nil, f.decodeInitiatedErr
	}
	return f.rebalanceInitiated, nil
}

func (f *fakeParentCodec) DecodeRebalanceDepositSuccess(*evm.Log) (*parent_vault.RebalanceDepositSuccessDecoded, error) {
	if f.decodeDepositErr != nil {
		return nil, f.decodeDepositErr
	}
	return f.depositSuccess, nil
}

func (f *fakeParentCodec) EncodeCompleteRebalanceMethodCall(in parent_vault.CompleteRebalanceInput) ([]byte, error) {
	f.completeInput = in
	if f.completeErr != nil {
		return nil, f.completeErr
	}
	return f.completeCalldata, nil
}

type fakeChildCodec struct {
	executeErr      error
	executeCalldata []byte
	executeInput    child_vault.ExecuteRebalanceInput
}

func (f *fakeChildCodec) EncodeExecuteRebalanceMethodCall(in child_vault.ExecuteRebalanceInput) ([]byte, error) {
	f.executeInput = in
	if f.executeErr != nil {
		return nil, f.executeErr
	}
	return f.executeCalldata, nil
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

func testConfig() *helper.Config {
	return &helper.Config{
		BlockNumber: -2,
		DefiLlama: helper.DefiLlama{
			PoolIDs:  []string{"aa70268e-4b52-42bf-a116-608b370f9501", "d9c395b9-00d0-4426-a6b3-572a6dd68e54"},
			Projects: []string{"aave-v3", "compound-v3"},
			Symbols:  []string{"USDC"},
		},
		Evms: []helper.EvmConfig{
			{
				IsParent:              true,
				ChainName:             "ethereum-mainnet-arbitrum-1",
				DefiLlamaChainName:    "Arbitrum",
				ChainSelector:         parentChainSelector,
				VaultAddress:          "0x0000000000000000000000000000000000000003",
				WorkflowRouterAddress: "0x0000000000000000000000000000000000000004",
				GasLimit:              600_000,
			},
			{
				ChainName:             "ethereum-mainnet",
				DefiLlamaChainName:    "Ethereum",
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
	origCronDeps := defaultCronDeps
	origExecutorDeps := defaultExecutorDeps
	origCompleterDeps := defaultCompleterDeps
	t.Cleanup(func() {
		newParentCodec = origParentCodec
		newChildCodec = origChildCodec
		newParentVaultBinding = origParentBinding
		defaultCronDeps = origCronDeps
		defaultExecutorDeps = origExecutorDeps
		defaultCompleterDeps = origCompleterDeps
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

func installParentBinding(t *testing.T) {
	t.Helper()
	newParentVaultBinding = func(*evm.Client, string) (onchain.ParentVaultInterface, error) {
		return fakeParentVault{}, nil
	}
}

func rebalanceState(protocolID [32]byte, chainSelector uint64) parent_vault.TypesRebalance {
	return parent_vault.TypesRebalance{
		ActiveStrategy: parent_vault.TypesStrategy{
			ProtocolId:    protocolID,
			ChainSelector: chainSelector,
		},
	}
}

func baseCronDeps() CronDeps {
	return CronDeps{
		FetchAndSelectPools: func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
			return compChildPool, aaveParentPool, nil
		},
		GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
			return rebalanceState(aaveProtocolID, parentChainSelector), nil
		},
		SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
			return nil
		},
	}
}

func Test_OnCronTrigger_wrapper(t *testing.T) {
	resetSeams(t)
	parentCodec := &fakeParentCodec{initiateCalldata: []byte{1}}
	installParentCodec(t, parentCodec)
	installParentBinding(t)
	defaultCronDeps = baseCronDeps()

	result, err := OnCronTrigger(testConfig(), testutils.NewRuntime(t, nil), nil)
	require.NoError(t, err, "expected wrapper to use default deps")
	require.Equal(t, "initiated rebalance", result.Result)
}

func Test_DefaultSeams(t *testing.T) {
	resetSeams(t)

	parentCodec, err := newParentCodec()
	require.NoError(t, err, "expected default parent codec constructor to succeed")
	require.NotNil(t, parentCodec, "expected parent codec")

	childCodec, err := newChildCodec()
	require.NoError(t, err, "expected default child codec constructor to succeed")
	require.NotNil(t, childCodec, "expected child codec")

	binding, err := newParentVaultBinding(nil, "0x0000000000000000000000000000000000000001")
	require.NoError(t, err, "expected default parent binding constructor to succeed")
	require.NotNil(t, binding, "expected parent binding")
}

func Test_OnCronTrigger_withDeps(t *testing.T) {
	tests := []struct {
		name       string
		config     *helper.Config
		codec      *fakeParentCodec
		codecErr   error
		bindingErr error
		deps       CronDeps
		wantResult string
		wantErr    string
	}{
		{
			name:     "parent codec error",
			codecErr: errors.New("codec failed"),
			deps:     baseCronDeps(),
			wantErr:  "init parent vault codec: codec failed",
		},
		{
			name:    "no parent",
			config:  &helper.Config{Evms: []helper.EvmConfig{{ChainSelector: childChainSelector}}},
			codec:   &fakeParentCodec{},
			deps:    baseCronDeps(),
			wantErr: "no parent chain configured",
		},
		{
			name:       "bind parent error",
			codec:      &fakeParentCodec{},
			bindingErr: errors.New("bind failed"),
			deps:       baseCronDeps(),
			wantErr:    "bind parent vault: bind failed",
		},
		{
			name:  "get rebalance error",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
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
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return parent_vault.TypesRebalance{State: 1}, nil
				}
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					t.Fatal("FetchAndSelectPools must not be called")
					return nil, nil, nil
				}
				return deps
			}(),
			wantResult: "no-op: rebalance in progress",
		},
		{
			name:  "fetch error",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return nil, nil, errors.New("fetch failed")
				}
				return deps
			}(),
			wantErr: "fetch pools: fetch failed",
		},
		{
			name:  "rebalance cooldown active",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.GetRebalance = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					rebalance := rebalanceState(aaveProtocolID, parentChainSelector)
					rebalance.LastRebalanceCompletedTimestamp = big.NewInt(1<<62 - minRebalanceIntervalSeconds)
					return rebalance, nil
				}
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					t.Fatal("FetchAndSelectPools must not be called during cooldown")
					return nil, nil, nil
				}
				return deps
			}(),
			wantResult: "no-op: rebalance cooldown active",
		},
		{
			name:  "no approved pool",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return nil, nil, nil
				}
				return deps
			}(),
			wantResult: "no-op: no approved pool",
		},
		{
			name:  "unknown best chain",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return &offchain.Pool{Chain: "Base", Project: "aave-v3", Symbol: "USDC", Apy: 9}, nil, nil
				}
				return deps
			}(),
			wantErr: `map best pool chain: no chain selector for DefiLlama chain "Base"`,
		},
		{
			name:  "already optimal",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return aaveParentPool, aaveParentPool, nil
				}
				return deps
			}(),
			wantResult: "no-op: already optimal",
		},
		{
			name:  "below threshold",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return &offchain.Pool{Chain: "Ethereum", Project: "compound-v3", Symbol: "USDC", Apy: 5.99}, aaveParentPool, nil
				}
				return deps
			}(),
			wantResult: "no-op: below threshold",
		},
		{
			name:  "missing current pool",
			codec: &fakeParentCodec{},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.FetchAndSelectPools = func(cre.Runtime, offchain.Config, [32]byte, uint64) (*offchain.Pool, *offchain.Pool, error) {
					return compChildPool, nil, nil
				}
				return deps
			}(),
			wantResult: "no-op: current pool missing",
		},
		{
			name:    "encode initiate error",
			codec:   &fakeParentCodec{initiateErr: errors.New("encode failed")},
			deps:    baseCronDeps(),
			wantErr: "encode initiateRebalance: encode failed",
		},
		{
			name:  "submit error",
			codec: &fakeParentCodec{initiateCalldata: []byte{1}},
			deps: func() CronDeps {
				deps := baseCronDeps()
				deps.SubmitReport = func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
					return errors.New("submit failed")
				}
				return deps
			}(),
			wantErr: "submit initiateRebalance: submit failed",
		},
		{
			name:       "success",
			codec:      &fakeParentCodec{initiateCalldata: []byte{1}},
			deps:       baseCronDeps(),
			wantResult: "initiated rebalance",
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
				if tt.bindingErr != nil {
					return nil, tt.bindingErr
				}
				return fakeParentVault{}, nil
			}

			result, err := onCronTriggerWithDeps(cfg, testutils.NewRuntime(t, nil), nil, tt.deps)
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

func Test_NewDefiLlamaConfig(t *testing.T) {
	cfg := newDefiLlamaConfig(testConfig())
	require.Equal(t, []offchain.ChainConfig{
		{ChainSelector: parentChainSelector, DefiLlamaChainName: "Arbitrum"},
		{ChainSelector: childChainSelector, DefiLlamaChainName: "Ethereum"},
	}, cfg.Chains)
	require.Equal(t, []string{"aa70268e-4b52-42bf-a116-608b370f9501", "d9c395b9-00d0-4426-a6b3-572a6dd68e54"}, cfg.PoolIDs)
	require.Equal(t, []string{"aave-v3", "compound-v3"}, cfg.Projects)
	require.Equal(t, []string{"USDC"}, cfg.Symbols)
}

func baseExecutorDeps() ExecutorDeps {
	return ExecutorDeps{
		GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
			return rebalanceState(aaveProtocolID, childChainSelector), nil
		},
		SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
			return nil
		},
	}
}

func Test_OnRebalanceInitiated_wrapper(t *testing.T) {
	resetSeams(t)
	parentCodec := &fakeParentCodec{
		rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{
			RebalanceNonce: big.NewInt(1),
			ChainSelector:  parentChainSelector,
			ProtocolId:     compoundProtocolID,
		},
	}
	installParentCodec(t, parentCodec)
	installChildCodec(t, &fakeChildCodec{executeCalldata: []byte{1}})
	installParentBinding(t)
	defaultExecutorDeps = baseExecutorDeps()

	result, err := OnRebalanceInitiated(testConfig(), testutils.NewRuntime(t, nil), &evm.Log{})
	require.NoError(t, err, "expected wrapper to use default deps")
	require.Equal(t, "submitted executeRebalance", result.Result)
}

func Test_OnRebalanceInitiated_withDeps(t *testing.T) {
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
		{name: "no parent", config: &helper.Config{Evms: []helper.EvmConfig{{ChainSelector: childChainSelector}}}, parentCodec: &fakeParentCodec{}, childCodec: &fakeChildCodec{}, deps: baseExecutorDeps(), wantErr: "no parent chain configured"},
		{name: "decode error", parentCodec: &fakeParentCodec{decodeInitiatedErr: errors.New("decode failed")}, childCodec: &fakeChildCodec{}, deps: baseExecutorDeps(), wantErr: "decode RebalanceInitiated: decode failed"},
		{name: "bind error", parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{}}, childCodec: &fakeChildCodec{}, bindingErr: errors.New("bind failed"), deps: baseExecutorDeps(), wantErr: "bind parent vault: bind failed"},
		{
			name:        "get rebalance error",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{}},
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
			name:        "active strategy on parent",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{RebalanceNonce: big.NewInt(1)}},
			childCodec:  &fakeChildCodec{},
			deps: ExecutorDeps{
				GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(aaveProtocolID, parentChainSelector), nil
				},
				SubmitReport: baseExecutorDeps().SubmitReport,
			},
			wantResult: "no-op: active strategy on parent",
		},
		{
			name:        "previous chain missing",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{}},
			childCodec:  &fakeChildCodec{},
			deps: ExecutorDeps{
				GetRebalance: func(cre.Runtime, onchain.ParentVaultInterface, *big.Int) (parent_vault.TypesRebalance, error) {
					return rebalanceState(aaveProtocolID, 999), nil
				},
				SubmitReport: baseExecutorDeps().SubmitReport,
			},
			wantErr: "find prev strategy chain: no evm config found for chainSelector 999",
		},
		{
			name:        "encode error",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{}},
			childCodec:  &fakeChildCodec{executeErr: errors.New("encode failed")},
			deps:        baseExecutorDeps(),
			wantErr:     "encode executeRebalance: encode failed",
		},
		{
			name:        "submit error",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{}},
			childCodec:  &fakeChildCodec{executeCalldata: []byte{1}},
			deps: ExecutorDeps{
				GetRebalance: baseExecutorDeps().GetRebalance,
				SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
					return errors.New("submit failed")
				},
			},
			wantErr: "submit executeRebalance: submit failed",
		},
		{
			name:        "success",
			parentCodec: &fakeParentCodec{rebalanceInitiated: &parent_vault.RebalanceInitiatedDecoded{RebalanceNonce: big.NewInt(2), ChainSelector: parentChainSelector, ProtocolId: compoundProtocolID}},
			childCodec:  &fakeChildCodec{executeCalldata: []byte{1}},
			deps:        baseExecutorDeps(),
			wantResult:  "submitted executeRebalance",
		},
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

			result, err := onRebalanceInitiatedWithDeps(cfg, testutils.NewRuntime(t, nil), &evm.Log{}, tt.deps)
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

func baseCompleterDeps() CompleterDeps {
	return CompleterDeps{
		SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
			return nil
		},
	}
}

func Test_OnRebalanceDepositSuccess_wrapper(t *testing.T) {
	resetSeams(t)
	installParentCodec(t, &fakeParentCodec{
		depositSuccess:   &parent_vault.RebalanceDepositSuccessDecoded{RebalanceNonce: big.NewInt(1)},
		completeCalldata: []byte{1},
	})
	defaultCompleterDeps = baseCompleterDeps()

	result, err := OnRebalanceDepositSuccess(testConfig(), testutils.NewRuntime(t, nil), &evm.Log{})
	require.NoError(t, err, "expected wrapper to use default deps")
	require.Equal(t, "submitted completeRebalance", result.Result)
}

func Test_OnRebalanceDepositSuccess_withDeps(t *testing.T) {
	tests := []struct {
		name       string
		config     *helper.Config
		codec      *fakeParentCodec
		codecErr   error
		deps       CompleterDeps
		wantResult string
		wantErr    string
	}{
		{name: "codec error", codecErr: errors.New("codec failed"), deps: baseCompleterDeps(), wantErr: "init parent vault codec: codec failed"},
		{name: "no parent", config: &helper.Config{Evms: []helper.EvmConfig{{ChainSelector: childChainSelector}}}, codec: &fakeParentCodec{}, deps: baseCompleterDeps(), wantErr: "no parent chain configured"},
		{name: "decode error", codec: &fakeParentCodec{decodeDepositErr: errors.New("decode failed")}, deps: baseCompleterDeps(), wantErr: "decode RebalanceDepositSuccess: decode failed"},
		{name: "encode error", codec: &fakeParentCodec{depositSuccess: &parent_vault.RebalanceDepositSuccessDecoded{}, completeErr: errors.New("encode failed")}, deps: baseCompleterDeps(), wantErr: "encode completeRebalance: encode failed"},
		{
			name:  "submit error",
			codec: &fakeParentCodec{depositSuccess: &parent_vault.RebalanceDepositSuccessDecoded{}, completeCalldata: []byte{1}},
			deps: CompleterDeps{SubmitReport: func(cre.Runtime, *evm.Client, common.Address, []byte, uint64) error {
				return errors.New("submit failed")
			}},
			wantErr: "submit completeRebalance: submit failed",
		},
		{name: "success", codec: &fakeParentCodec{depositSuccess: &parent_vault.RebalanceDepositSuccessDecoded{RebalanceNonce: big.NewInt(1)}, completeCalldata: []byte{1}}, deps: baseCompleterDeps(), wantResult: "submitted completeRebalance"},
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

			result, err := onRebalanceDepositSuccessWithDeps(cfg, testutils.NewRuntime(t, nil), &evm.Log{}, tt.deps)
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
