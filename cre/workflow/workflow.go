package main

import (
	"bytes"
	"fmt"
	"log/slog"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/epoch"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/onchain"
	"cre/workflow/internal/rebalance"
	"cre/workflow/internal/workflowtypes"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type Config = helper.Config
type ExecutionResult = workflowtypes.ExecutionResult

var (
	newWorkflowParentCodec = parent_vault.NewCodec
	newWorkflowChildCodec  = child_vault.NewCodec
)

// InitWorkflow registers two cron triggers and one log subscription per vault.
// Each log subscription accepts two event signatures and dispatches by topic 0.
//
// The six logical handlers are:
//  1. Cron → EpochInitiator // @review replace these descriptive labels with the actual handler names?
//  2. Cron → RebalanceInitiator
//  3. ParentVault.RebalanceInitiated → RebalanceExecutor
//  4. ParentVault.EpochWithdrawExecuting → EpochWithdrawExecutor
//  5. ChildVault.RebalanceDepositSuccess → RebalanceCompleter
//  6. ChildVault.EpochDepositToStrategySuccess → EpochDepositCompleter
//
// Handlers 3 and 4 share the Parent subscription. Handlers 5 and 6 share one
// subscription per child. Six chains therefore use eight subscriptions. // @review Strictly, there are six log subscriptions and eight total triggers. The last comment uses “subscriptions” somewhat broadly.
func InitWorkflow(config *Config, logger *slog.Logger, _ cre.SecretsProvider) (cre.Workflow[*Config], error) {
	return initWorkflow(config, logger, onchain.ReadSnapshot)
}

func initWorkflow(config *Config, _ *slog.Logger, readSnapshot onchain.SnapshotReader) (cre.Workflow[*Config], error) {
	if err := helper.ValidateConfig(config); err != nil {
		return nil, err
	}
	parentCodec, err := newWorkflowParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}
	childCodec, err := newWorkflowChildCodec()
	if err != nil {
		return nil, fmt.Errorf("init child vault codec: %w", err)
	}

	handlers := cre.Workflow[*Config]{
		// Handler 1: scheduled cron → close the current epoch on Parent.
		cre.Handler(
			cron.Trigger(&cron.Config{Schedule: config.EpochSchedule}),
			withOperationalGuard(readSnapshot, epoch.OnEpochCronTrigger),
		),
		// Handler 2: scheduled cron → initiate a rebalance on Parent.
		cre.Handler(
			cron.Trigger(&cron.Config{Schedule: config.RebalanceSchedule}),
			withOperationalGuard(readSnapshot, rebalance.OnRebalanceCronTrigger),
		),
	}

	for _, chainConfig := range config.Evms {
		sourceChain := chainConfig.ChainSelector
		isParent := chainConfig.IsParent
		var signatures [][]byte
		if isParent {
			// One Parent subscription matches the events for handlers 3 and 4.
			signatures = [][]byte{
				// Trigger for handler 3: ParentVault.RebalanceInitiated.
				parentCodec.RebalanceInitiatedLogHash(),
				// Trigger for handler 4: ParentVault.EpochWithdrawExecuting.
				parentCodec.EpochWithdrawExecutingLogHash(),
			}
		} else {
			// Child trigger: topic 0 matches either event, with OR semantics.
			// Both handlers use this child's chain and vault address as their source.
			signatures = [][]byte{
				// Trigger for handler 5: ChildVault.RebalanceDepositSuccess.
				childCodec.RebalanceDepositSuccessLogHash(),
				// Trigger for handler 6: ChildVault.EpochDepositToStrategySuccess.
				childCodec.EpochDepositToStrategySuccessLogHash(),
			}
		}

		onLog := func(config *Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot) (*ExecutionResult, error) {
			if log == nil || len(log.Topics) == 0 {
				return nil, fmt.Errorf("event has no signature topic")
			}
			if isParent {
				switch {
				case bytes.Equal(log.Topics[0], parentCodec.RebalanceInitiatedLogHash()):
					// Handler 3: execute the rebalance on the source child.
					return rebalance.OnRebalanceInitiated(config, runtime, log, snapshot, sourceChain)
				case bytes.Equal(log.Topics[0], parentCodec.EpochWithdrawExecutingLogHash()):
					// Handler 4: withdraw the epoch's fixed amount on the active child.
					return epoch.OnEpochWithdrawExecuting(config, runtime, log, snapshot, sourceChain)
				}
			} else {
				switch {
				case bytes.Equal(log.Topics[0], childCodec.RebalanceDepositSuccessLogHash()):
					// Handler 5: complete the rebalance on Parent after child deposit success.
					return rebalance.OnRebalanceDepositSuccess(config, runtime, log, snapshot, sourceChain)
				case bytes.Equal(log.Topics[0], childCodec.EpochDepositToStrategySuccessLogHash()):
					// Handler 6: reconcile and complete the remote deposit epoch on Parent.
					return epoch.OnEpochDepositToStrategySuccess(config, runtime, log, snapshot, sourceChain)
				}
			}
			return nil, fmt.Errorf("unexpected event signature on chain %d", sourceChain)
		}

		// Register one finalized log trigger for this vault: handlers 3/4 on
		// Parent, or handlers 5/6 on a child, selected by the signatures above.
		handlers = append(handlers, cre.Handler(
			evm.LogTrigger(sourceChain, &evm.FilterLogTriggerRequest{
				Addresses:  [][]byte{common.HexToAddress(chainConfig.VaultAddress).Bytes()},
				Topics:     []*evm.TopicValues{{Values: signatures}},
				Confidence: evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED,
			}),
			withOperationalGuard(readSnapshot, onLog),
		))
	}
	return handlers, nil
}

// withOperationalGuard reads once and shares that snapshot with the handler.
// It applies to every entrypoint, including epoch deposit completion.
func withOperationalGuard[T any](
	readSnapshot onchain.SnapshotReader,
	handler func(*Config, cre.Runtime, *T, *onchain.Snapshot) (*ExecutionResult, error),
) func(*Config, cre.Runtime, *T) (*ExecutionResult, error) {
	return func(config *Config, runtime cre.Runtime, payload *T) (*ExecutionResult, error) {
		snapshot, err := readSnapshot(config, runtime)
		if err != nil {
			return nil, fmt.Errorf("read operational state: %w", err)
		}
		if snapshot == nil {
			return nil, fmt.Errorf("read operational state: nil snapshot")
		}
		if reason := snapshot.BlockedReason(config); reason != "" {
			return workflowtypes.Noop(runtime, reason)
		}
		return handler(config, runtime, payload, snapshot)
	}
}
