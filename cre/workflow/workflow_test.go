package main

import (
	"errors"
	"fmt"
	"math/big"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"

	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
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
		RebalanceSchedule: "0 0 */6 * * *",
		EpochSchedule:     "0 30 * * * *",
		BlockNumber:       -2,
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

func TestInitWorkflow_PropagatesValidationError(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})

	workflow, err := InitWorkflow(&Config{}, runtime.Logger(), nil)
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

func TestInitWorkflow_ParentOnly(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(workflowTestEvmConfig(1, true))

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.NoError(t, err, "expected parent-only config to initialize")
	require.Len(t, workflow, 4, "expected two cron handlers and two parent log handlers")
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[0].CapabilityID())
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[2].CapabilityID())
}

func TestInitWorkflow_MultipleChildren(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(
		workflowTestEvmConfig(1, true),
		workflowTestEvmConfig(2, false),
		workflowTestEvmConfig(3, false),
		workflowTestEvmConfig(4, false),
	)

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.NoError(t, err, "expected multi-child config to initialize")
	require.Len(t, workflow, 7, "expected base handlers plus one rebalance-completer per child")
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[0].CapabilityID())
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[5].CapabilityID())
}

func TestInitWorkflow_ParentDoesNotNeedToBeFirst(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(
		workflowTestEvmConfig(10, false),
		workflowTestEvmConfig(20, true),
		workflowTestEvmConfig(30, false),
	)

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.NoError(t, err, "expected parent lookup to use IsParent, not slice position")
	require.Len(t, workflow, 6, "expected two child handlers when parent is in the middle")
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[0].CapabilityID())
	require.Equal(t, cron.Trigger(&cron.Config{}).CapabilityID(), workflow[4].CapabilityID())
}

func TestInitWorkflow_ChildHandlerClosure(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	config := workflowTestConfig(
		workflowTestEvmConfig(1, true),
		workflowTestEvmConfig(2, false),
	)

	workflow, err := InitWorkflow(config, runtime.Logger(), nil)
	require.NoError(t, err, "expected workflow to initialize")

	codec, err := parent_vault.NewCodec()
	require.NoError(t, err, "expected parent codec")

	nonceTopic := make([]byte, 32)
	big.NewInt(1).FillBytes(nonceTopic)
	amountTopic := make([]byte, 32)
	big.NewInt(100).FillBytes(amountTopic)
	payload, err := anypb.New(&evm.Log{
		Topics: [][]byte{
			codec.RebalanceDepositSuccessLogHash(),
			nonceTopic,
			amountTopic,
		},
	})
	require.NoError(t, err, "expected log payload to marshal")

	result, err := workflow[2].Callback()(config, runtime, payload)
	require.Error(t, err, "expected child completion handler to run and fail on empty log")
	require.Nil(t, result, "expected nil result on handler error")
	require.ErrorContains(t, err, "submit completeRebalance")
}
