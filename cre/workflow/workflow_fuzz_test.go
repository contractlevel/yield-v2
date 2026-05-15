package main

import (
	"fmt"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"

	"cre/workflow/internal/helper"
)

func Fuzz_InitWorkflow_ConfigShape(f *testing.F) {
	f.Add(uint64(1), uint64(2), uint64(3), true, false, false)
	f.Add(uint64(1), uint64(2), uint64(3), false, true, false)
	f.Add(uint64(1), uint64(1), uint64(3), true, false, false)
	f.Add(uint64(0), uint64(2), uint64(3), true, false, false)
	f.Add(uint64(1), uint64(2), uint64(3), true, true, false)

	f.Fuzz(func(t *testing.T, a, b, c uint64, parentA, parentB, parentC bool) {
		runtime := testutils.NewRuntime(t, testutils.Secrets{})
		config := workflowTestConfig(
			fuzzWorkflowEvmConfig("a", a, parentA),
			fuzzWorkflowEvmConfig("b", b, parentB),
			fuzzWorkflowEvmConfig("c", c, parentC),
		)

		workflow, err := InitWorkflow(config, runtime.Logger(), nil)
		validateErr := helper.ValidateConfig(config)
		if validateErr != nil {
			require.Error(t, err, "expected InitWorkflow to reject invalid config")
			require.Nil(t, workflow, "expected no workflow for invalid config")
			return
		}

		require.NoError(t, err, "expected InitWorkflow to accept valid config")
		require.NotNil(t, workflow, "expected workflow for valid config")

		childCount := 0
		for _, evmCfg := range config.Evms {
			if !evmCfg.IsParent {
				childCount++
			}
		}
		require.Len(t, workflow, 4+childCount, "unexpected handler count")
	})
}

func fuzzWorkflowEvmConfig(name string, chainSelector uint64, isParent bool) helper.EvmConfig {
	return helper.EvmConfig{
		IsParent:              isParent,
		ChainName:             "chain-" + name,
		ChainSelector:         chainSelector,
		VaultAddress:          fuzzWorkflowAddress(chainSelector, 1),
		WorkflowRouterAddress: fuzzWorkflowAddress(chainSelector, 2),
		GasLimit:              500_000,
	}
}

func fuzzWorkflowAddress(chainSelector uint64, offset uint64) string {
	return fmt.Sprintf("0x%040x", chainSelector*10+offset)
}
