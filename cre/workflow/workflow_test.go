package main

import (
	"errors"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"math/big"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/onchain"
)

func workflowTestAddress(n uint64) string {
	return fmt.Sprintf("0x%040x", n)
}

func workflowTestEvmConfig(chainSelector uint64, isParent bool) helper.EvmConfig {
	return helper.EvmConfig{
		IsParent:              isParent,
		ChainName:             fmt.Sprintf("chain-%d", chainSelector),
		ChainSelector:         chainSelector,
		VaultAddress:          workflowTestAddress(chainSelector*2 + 1),
		WorkflowRouterAddress: workflowTestAddress(chainSelector*2 + 2),
		GasLimit:              500_000,
	}
}

func workflowTestConfig(evms ...helper.EvmConfig) *Config {
	return &Config{
		BlockNumber:       new(int64),
		RebalanceSchedule: "0 0 */6 * * *",
		EpochSchedule:     "0 30 * * * *",
		AssetDecimals:     newTestAssetDecimals(),
		DefiLlama: helper.DefiLlama{
			PoolIDs:  []string{"aa70268e-4b52-42bf-a116-608b370f9501", "d9c395b9-00d0-4426-a6b3-572a6dd68e54"},
			Projects: []string{"aave-v3", "compound-v3"},
			Symbols:  []string{"USDC"},
		},
		Evms: evms,
	}
}

func withWorkflowParentCodecError(t *testing.T, err error) {
	t.Helper()

	original := newWorkflowParentCodec
	newWorkflowParentCodec = func() (parent_vault.ParentVaultCodec, error) {
		return nil, err
	}
	t.Cleanup(func() {
		newWorkflowParentCodec = original
	})
}

func withWorkflowChildCodecError(t *testing.T, err error) {
	t.Helper()

	original := newWorkflowChildCodec
	newWorkflowChildCodec = func() (child_vault.ChildVaultCodec, error) {
		return nil, err
	}
	t.Cleanup(func() {
		newWorkflowChildCodec = original
	})
}

func TestInitWorkflow_PropagatesValidationError(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})

	workflow, err := InitWorkflow(&Config{BlockNumber: new(int64)}, runtime.Logger(), nil)
	require.Error(t, err, "expected invalid config to fail")
	require.Nil(t, workflow, "expected no workflow when config validation fails")
	require.ErrorContains(t, err, "no EVM configs provided")
}

func TestInitWorkflow_ParentCodecError(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true))
	withWorkflowParentCodecError(t, errors.New("codec failed"))

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.Error(t, err, "expected codec error")
	require.Nil(t, workflow, "expected no workflow when codec init fails")
	require.ErrorContains(t, err, "init parent vault codec: codec failed")
}

func TestInitWorkflow_ChildCodecError(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true))
	withWorkflowChildCodecError(t, errors.New("codec failed"))

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.Error(t, err)
	require.Nil(t, workflow)
	require.ErrorContains(t, err, "init child vault codec: codec failed")
}

func newTestAssetDecimals() *uint8 {
	value := uint8(6)
	return &value
}

func TestInitWorkflowCombinedSubscriptions(t *testing.T) {
	for _, chains := range []int{1, 5, 6, 8, 9} {
		t.Run(fmt.Sprint(chains), func(t *testing.T) {
			configs := make([]helper.EvmConfig, chains)
			for i := range configs {
				configs[i] = workflowTestEvmConfig(uint64(i+1), i == 0)
			}
			config := workflowTestConfig(configs...)
			runtime := testutils.NewRuntime(t, testutils.Secrets{})
			workflow, err := InitWorkflow(config, runtime.Logger(), nil)
			if chains == 9 {
				require.ErrorContains(t, err, "11 triggers")
				return
			}
			require.NoError(t, err)
			require.Len(t, workflow, chains+2)
			for i := 0; i < 2; i++ {
				require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[i].CapabilityID())
			}
			parentCodec, err := parent_vault.NewCodec()
			require.NoError(t, err)
			childCodec, err := child_vault.NewCodec()
			require.NoError(t, err)
			for i, cfg := range configs {
				filter := &evm.FilterLogTriggerRequest{}
				require.NoError(t, workflow[i+2].TriggerCfg().UnmarshalTo(filter))
				require.Equal(t, [][]byte{common.HexToAddress(cfg.VaultAddress).Bytes()}, filter.Addresses)
				require.Equal(t, evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED, filter.Confidence)
				expected := [][]byte{childCodec.RebalanceDepositSuccessLogHash(), childCodec.EpochDepositToStrategySuccessLogHash()}
				if cfg.IsParent {
					expected = [][]byte{parentCodec.RebalanceInitiatedLogHash(), parentCodec.EpochWithdrawExecutingLogHash()}
				}
				require.Equal(t, expected, filter.Topics[0].Values)
			}
		})
	}
}

func TestOperationalGuardUsesOneSnapshot(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true))
	snapshot := &onchain.Snapshot{}
	calls := 0
	handler := withOperationalGuard(
		func(*Config, cre.Runtime) (*onchain.Snapshot, error) {
			calls++
			return snapshot, nil
		},
		func(_ *Config, _ cre.Runtime, _ *cron.Payload, got *onchain.Snapshot) (*ExecutionResult, error) {
			require.Same(t, snapshot, got)
			return &ExecutionResult{Result: "handled"}, nil
		},
	)
	result, err := handler(config, runtime, &cron.Payload{})
	require.NoError(t, err)
	require.Equal(t, "handled", result.Result)
	require.Equal(t, 1, calls)
}

func TestOperationalGuardErrors(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true))
	for _, readErr := range []error{nil, errors.New("RPC failed")} {
		handler := withOperationalGuard(
			func(*Config, cre.Runtime) (*onchain.Snapshot, error) { return nil, readErr },
			func(*Config, cre.Runtime, *cron.Payload, *onchain.Snapshot) (*ExecutionResult, error) {
				t.Fatal("must not reach handler")
				return nil, nil
			},
		)
		_, err := handler(config, runtime, &cron.Payload{})
		require.Error(t, err)
	}
}

func TestEverySubscriptionAppliesOperationalGuard(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true), workflowTestEvmConfig(2, false))
	for _, paused := range []bool{true, false} {
		snapshot := &onchain.Snapshot{}
		snapshot.Parent.Paused = paused
		if !paused {
			snapshot.Parent.RecoveryMode = 1
		}
		reads := 0
		workflow, err := initWorkflow(config, runtime.Logger(), func(*Config, cre.Runtime) (*onchain.Snapshot, error) {
			reads++
			return snapshot, nil
		})
		require.NoError(t, err)
		for i, handler := range workflow {
			payload, err := anypb.New(&cron.Payload{})
			if i >= 2 {
				payload, err = anypb.New(&evm.Log{})
			}
			require.NoError(t, err)
			result, err := handler.Callback()(config, runtime, payload)
			require.NoError(t, err)
			require.Contains(t, result.(*ExecutionResult).Result, "no-op:")
		}
		require.Equal(t, len(workflow), reads)
	}
}

func TestCombinedLogSubscriptionsDispatchAllFourEvents(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true), workflowTestEvmConfig(2, false), workflowTestEvmConfig(3, false))
	// Equal addresses on different chains must still be distinguished.
	config.Evms[2].VaultAddress = config.Evms[1].VaultAddress
	snapshot := &onchain.Snapshot{Parent: parent_vault.TypesParentOperationalState{
		CurrentEpochNonce: big.NewInt(2),
		Rebalance: parent_vault.TypesRebalance{
			Nonce:          big.NewInt(7),
			ActiveStrategy: parent_vault.TypesStrategy{ChainSelector: 3},
		},
	}}
	workflow, err := initWorkflow(config, runtime.Logger(), func(*Config, cre.Runtime) (*onchain.Snapshot, error) { return snapshot, nil })
	require.NoError(t, err)
	for _, test := range []struct {
		subscription int
		signature    string
		topics       [][]byte
		reason       string
	}{
		{2, "RebalanceInitiated(uint256,bytes32,uint64)", [][]byte{big.NewInt(6).Bytes(), make([]byte, 32), big.NewInt(3).Bytes()}, "stale rebalance"},
		{2, "EpochWithdrawExecuting(uint256,uint256)", [][]byte{big.NewInt(1).Bytes(), big.NewInt(100).Bytes()}, "stale epoch"},
		{3, "RebalanceDepositSuccess(uint256,uint256)", [][]byte{big.NewInt(6).Bytes(), big.NewInt(100).Bytes()}, "stale rebalance"},
		{3, "EpochDepositToStrategySuccess(uint256,uint256)", [][]byte{big.NewInt(1).Bytes(), big.NewInt(100).Bytes()}, "wrong epoch deposit destination"},
		{4, "EpochDepositToStrategySuccess(uint256,uint256)", [][]byte{big.NewInt(1).Bytes(), big.NewInt(100).Bytes()}, "stale epoch"},
	} {
		log := &evm.Log{Address: common.HexToAddress(config.Evms[test.subscription-2].VaultAddress).Bytes(), Topics: [][]byte{crypto.Keccak256([]byte(test.signature))}}
		for _, topic := range test.topics {
			log.Topics = append(log.Topics, common.LeftPadBytes(topic, 32))
		}
		payload, err := anypb.New(log)
		require.NoError(t, err)
		result, err := workflow[test.subscription].Callback()(config, runtime, payload)
		require.NoError(t, err)
		require.Contains(t, result.(*ExecutionResult).Result, test.reason)
	}
}

func TestLogSubscriptionsRejectUnknownEvents(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true), workflowTestEvmConfig(2, false))
	workflow, err := initWorkflow(config, runtime.Logger(), func(*Config, cre.Runtime) (*onchain.Snapshot, error) { return &onchain.Snapshot{}, nil })
	require.NoError(t, err)
	for _, handler := range workflow[2:] {
		for _, log := range []*evm.Log{{}, {Topics: [][]byte{make([]byte, 32)}}} {
			payload, err := anypb.New(log)
			require.NoError(t, err)
			result, err := handler.Callback()(config, runtime, payload)
			require.Error(t, err)
			require.Nil(t, result)
		}
	}
}
