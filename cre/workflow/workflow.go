package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/epoch"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/onchain"
	"cre/workflow/internal/rebalance"
	"cre/workflow/internal/workflowtypes"
)

var newWorkflowParentCodec = parent_vault.NewCodec

// Config and ExecutionResult are the top-level types used by all handlers.
type Config = helper.Config

type ExecutionResult = workflowtypes.ExecutionResult

type recoveryFinder func(cre.Runtime, []helper.EvmConfig, *big.Int) (*onchain.ActiveRecovery, error)

// ---- INIT WORKFLOW ----

// InitWorkflow registers five handlers:
//  1. Cron → RebalanceInitiator
//  2. ParentVault.RebalanceInitiated log → RebalanceExecutor
//  3. Per-child vault RebalanceDepositSuccess log → RebalanceCompleter
//  4. Cron → EpochInitiator
//  5. ParentVault.EpochExecuting log → EpochExecutor
func InitWorkflow(config *Config, logger *slog.Logger, _ cre.SecretsProvider) (cre.Workflow[*Config], error) {
	return initWorkflow(config, logger, onchain.FindActiveRecovery)
}

func initWorkflow(config *Config, logger *slog.Logger, findRecovery recoveryFinder) (cre.Workflow[*Config], error) {
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
		withRecoveryGuard(findRecovery, rebalance.OnCronTrigger),
	))

	// Handler 2: ParentVault.RebalanceInitiated → RebalanceExecutor
	handlers = append(handlers, cre.Handler(
		evm.LogTrigger(parentCfg.ChainSelector, &evm.FilterLogTriggerRequest{
			Addresses:  [][]byte{parentVaultAddr.Bytes()},
			Topics:     []*evm.TopicValues{{Values: [][]byte{pvCodec.RebalanceInitiatedLogHash()}}},
			Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
		}),
		withRecoveryGuard(findRecovery, rebalance.OnRebalanceInitiated),
	))

	// Handler 3: per-chain vault RebalanceDepositSuccess → RebalanceCompleter
	for _, evmCfg := range config.Evms {
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
			withRecoveryGuard(findRecovery, rebalance.OnRebalanceDepositSuccess),
		))
	}

	// Handler 4: cron → EpochInitiator
	handlers = append(handlers, cre.Handler(
		cron.Trigger(&cron.Config{Schedule: config.EpochSchedule}),
		withRecoveryGuard(findRecovery, epoch.OnEpochCronTrigger),
	))

	// Handler 5: ParentVault.EpochExecuting → EpochExecutor
	handlers = append(handlers, cre.Handler(
		evm.LogTrigger(parentCfg.ChainSelector, &evm.FilterLogTriggerRequest{
			Addresses:  [][]byte{parentVaultAddr.Bytes()},
			Topics:     []*evm.TopicValues{{Values: [][]byte{pvCodec.EpochExecutingLogHash()}}},
			Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
		}),
		withRecoveryGuard(findRecovery, epoch.OnEpochExecuting),
	))

	return cre.Workflow[*Config](handlers), nil
}

func withRecoveryGuard[T any](
	findRecovery recoveryFinder,
	handler func(*Config, cre.Runtime, *T) (*ExecutionResult, error),
) func(*Config, cre.Runtime, *T) (*ExecutionResult, error) {
	return func(config *Config, runtime cre.Runtime, payload *T) (*ExecutionResult, error) {
		recovery, err := findRecovery(runtime, config.Evms, big.NewInt(config.BlockNumber))
		if err != nil {
			return nil, fmt.Errorf("check recovery mode: %w", err)
		}
		if recovery != nil {
			runtime.Logger().Info("Recovery active; skipping workflow handler",
				slog.String("chain", recovery.ChainName),
				slog.Uint64("mode", uint64(recovery.Mode)),
			)
			return &ExecutionResult{Result: "no-op: recovery active"}, nil
		}

		return handler(config, runtime, payload)
	}
}
