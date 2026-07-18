package main

import (
	"fmt"
	"log/slog"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/epoch"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/rebalance"
	"cre/workflow/internal/workflowtypes"
)

var newWorkflowParentCodec = parent_vault.NewCodec

// Config and ExecutionResult are the top-level types used by all handlers.
type Config = helper.Config

type ExecutionResult = workflowtypes.ExecutionResult

// ---- INIT WORKFLOW ----

// InitWorkflow registers five handlers:
//  1. Cron → RebalanceInitiator
//  2. ParentVault.RebalanceInitiated log → RebalanceExecutor
//  3. Per-child vault RebalanceDepositSuccess log → RebalanceCompleter
//  4. Cron → EpochInitiator
//  5. ParentVault.EpochExecuting log → EpochExecutor
func InitWorkflow(config *Config, logger *slog.Logger, _ cre.SecretsProvider) (cre.Workflow[*Config], error) {
	if err := helper.ValidateConfig(config); err != nil {
		return nil, err
	}

	// ValidateConfig has already guaranteed exactly one parent chain.
	parentCfg, _ := helper.FindParent(config.Evms)

	var handlers []cre.ExecutionHandler[*Config, cre.Runtime]

	pvCodec, err := newWorkflowParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}

	parentVaultAddr := common.HexToAddress(parentCfg.VaultAddress)

	// Handler 1: cron → RebalanceInitiator
	handlers = append(handlers, cre.Handler(
		cron.Trigger(&cron.Config{Schedule: config.RebalanceSchedule}),
		rebalance.OnCronTrigger,
	))

	// Handler 2: ParentVault.RebalanceInitiated → RebalanceExecutor
	handlers = append(handlers, cre.Handler(
		evm.LogTrigger(parentCfg.ChainSelector, &evm.FilterLogTriggerRequest{
			Addresses:  [][]byte{parentVaultAddr.Bytes()},
			Topics:     []*evm.TopicValues{{Values: [][]byte{pvCodec.RebalanceInitiatedLogHash()}}},
			Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
		}),
		rebalance.OnRebalanceInitiated,
	))

	// Handler 3: per-chain vault RebalanceDepositSuccess → RebalanceCompleter
	for _, evmCfg := range config.Evms {
		evmCfg := evmCfg // capture loop variable
		if evmCfg.IsParent {
			continue // skip parent chain
		}
		vaultAddr := common.HexToAddress(evmCfg.VaultAddress)
		handlers = append(handlers, cre.Handler(
			evm.LogTrigger(evmCfg.ChainSelector, &evm.FilterLogTriggerRequest{
				Addresses:  [][]byte{vaultAddr.Bytes()},
				Topics:     []*evm.TopicValues{{Values: [][]byte{pvCodec.RebalanceDepositSuccessLogHash()}}},
				Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
			}),
			func(cfg *Config, runtime cre.Runtime, log *evm.Log) (*ExecutionResult, error) {
				return rebalance.OnRebalanceDepositSuccess(cfg, runtime, log)
			},
		))
	}

	// Handler 4: cron → EpochInitiator
	handlers = append(handlers, cre.Handler(
		cron.Trigger(&cron.Config{Schedule: config.EpochSchedule}),
		epoch.OnEpochCronTrigger,
	))

	// Handler 5: ParentVault.EpochExecuting → EpochExecutor
	handlers = append(handlers, cre.Handler(
		evm.LogTrigger(parentCfg.ChainSelector, &evm.FilterLogTriggerRequest{
			Addresses:  [][]byte{parentVaultAddr.Bytes()},
			Topics:     []*evm.TopicValues{{Values: [][]byte{pvCodec.EpochExecutingLogHash()}}},
			Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
		}),
		epoch.OnEpochExecuting,
	))

	return cre.Workflow[*Config](handlers), nil
}

// @review if recovery mode exists; cancel workflow?
// expose GetRecoveryMode to CRE, require NONE before reading/submitting TVL, test every nonzero recovery mode, and take recovery/TVL reads at the same finalized block reference.