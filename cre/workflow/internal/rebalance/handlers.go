package rebalance

import (
	"fmt"
	"log/slog"
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/helper"
	"cre/workflow/internal/offchain"
	"cre/workflow/internal/onchain"
	"cre/workflow/internal/workflowtypes"
)

type parentCodec interface {
	EncodeInitiateRebalanceMethodCall(parent_vault.InitiateRebalanceInput) ([]byte, error)
	DecodeRebalanceInitiated(*evm.Log) (*parent_vault.RebalanceInitiatedDecoded, error)
	DecodeRebalanceDepositSuccess(*evm.Log) (*parent_vault.RebalanceDepositSuccessDecoded, error)
	EncodeCompleteRebalanceMethodCall(parent_vault.CompleteRebalanceInput) ([]byte, error)
}

type childCodec interface {
	EncodeExecuteRebalanceMethodCall(child_vault.ExecuteRebalanceInput) ([]byte, error)
}

var (
	newParentCodec = func() (parentCodec, error) {
		return parent_vault.NewCodec()
	}
	newChildCodec = func() (childCodec, error) {
		return child_vault.NewCodec()
	}
)

// CronDeps holds the injectable dependencies for the RebalanceInitiator handler.
type CronDeps struct {
	FetchAndSelectPools func(runtime cre.Runtime, cfg offchain.Config, activeProtocolId [32]byte, activeChainSelector uint64) (*offchain.Pool, *offchain.Pool, error)
	SubmitReport        onchain.Submitter
}

var defaultCronDeps = CronDeps{
	FetchAndSelectPools: offchain.FetchAndSelectPools,
	SubmitReport:        onchain.SubmitReport,
}

func OnRebalanceCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload, snapshot *onchain.Snapshot) (*workflowtypes.ExecutionResult, error) {
	return onRebalanceCronTriggerWithDeps(config, runtime, trigger, snapshot, defaultCronDeps)
}

func onRebalanceCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, _ *cron.Payload, snapshot *onchain.Snapshot, deps CronDeps) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	parent := snapshot.Parent
	rebalance := parent.Rebalance
	if rebalance.State != onchain.RebalanceNone {
		return workflowtypes.Noop(runtime, "rebalance in progress")
	}
	if parent.CurrentEpochNonce.Cmp(big.NewInt(1)) <= 0 {
		return workflowtypes.Noop(runtime, "no completed epoch")
	}
	if parent.PreviousEpoch.Status == onchain.EpochExecuting {
		return workflowtypes.Noop(runtime, "epoch executing")
	}
	if !onchain.PeriodElapsed(rebalance.LastRebalanceCompletedTimestamp, snapshot.ObservedAt, minRebalanceIntervalSeconds) {
		return workflowtypes.Noop(runtime, "rebalance cooldown active")
	}
	// @review will this block the first rebalance? an epoch should happen first, and that would deposit so tvl would be > 0. confirm this
	if rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector && parent.Tvl.Sign() == 0 {
		return workflowtypes.Noop(runtime, "zero local strategy TVL")
	}

	activeStrategy := rebalance.ActiveStrategy
	defiLlamaConfig := newDefiLlamaConfig(config)

	// Query DefiLlama for the best and current approved pools.
	bestPool, currentPool, err := deps.FetchAndSelectPools(runtime, defiLlamaConfig, activeStrategy.ProtocolId, activeStrategy.ChainSelector)
	if err != nil {
		// Surface fetch failures to CRE monitoring; the next cron run can try again.
		return nil, fmt.Errorf("fetch pools: %w", err)
	}

	if bestPool == nil {
		return workflowtypes.Noop(runtime, "no approved pool")
	}

	// If the best pool matches the active strategy exactly, nothing to do.
	bestProtocolId := offchain.PoolToProtocolId(bestPool.Project)
	bestChainSelector, err := offchain.PoolToChainSelector(defiLlamaConfig, bestPool.Chain)
	if err != nil {
		return nil, fmt.Errorf("map best pool chain: %w", err)
	}

	if activeStrategy.ProtocolId == bestProtocolId && activeStrategy.ChainSelector == bestChainSelector {
		logger.Info("Already on optimal strategy; skipping rebalance",
			slog.String("project", bestPool.Project),
			slog.String("chain", bestPool.Chain),
		)
		// @review should this be noop?
		return &workflowtypes.ExecutionResult{Result: "no-op: already optimal"}, nil
	}

	if currentPool == nil {
		return workflowtypes.Noop(runtime, "current pool missing")
	}

	// Check that the APY improvement exceeds the differential threshold.
	if !NeedRebalance(bestPool, currentPool) {
		delta := bestPool.Apy - currentPool.Apy
		logger.Info("APY delta below threshold; skipping rebalance",
			slog.Float64("delta", delta),
			slog.Float64("threshold", DifferentialThreshold),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: below threshold"}, nil
	}

	// Encode and submit initiateRebalance to ParentVault.
	calldata, err := pvCodec.EncodeInitiateRebalanceMethodCall(
		parent_vault.InitiateRebalanceInput{
			ExpectedRebalanceNonce: rebalance.Nonce,
			NewStrategy: parent_vault.TypesStrategy{
				ProtocolId:    bestProtocolId,
				ChainSelector: bestChainSelector,
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("encode initiateRebalance: %w", err)
	}

	if err := deps.SubmitReport(runtime, parentCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit initiateRebalance: %w", err)
	}

	logger.Info("Initiated rebalance",
		slog.String("toProject", bestPool.Project),
		slog.String("toChain", bestPool.Chain),
		slog.Float64("apyBase", bestPool.Apy),
	)
	return &workflowtypes.ExecutionResult{Result: "initiated rebalance"}, nil
}

func newDefiLlamaConfig(config *helper.Config) offchain.Config {
	chains := make([]offchain.ChainConfig, 0, len(config.Evms))
	for _, evmCfg := range config.Evms {
		chains = append(chains, offchain.ChainConfig{
			ChainSelector:      evmCfg.ChainSelector,
			DefiLlamaChainName: evmCfg.DefiLlamaChainName,
		})
	}

	return offchain.Config{
		PoolIDs:  config.DefiLlama.PoolIDs,
		Chains:   chains,
		Projects: config.DefiLlama.Projects,
		Symbols:  config.DefiLlama.Symbols,
	}
}

func OnRebalanceInitiated(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64) (*workflowtypes.ExecutionResult, error) {
	return onRebalanceInitiatedWithDeps(config, runtime, log, snapshot, sourceChain, onchain.SubmitReport)
}

func onRebalanceInitiatedWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64, submit onchain.Submitter) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}
	cvCodec, err := newChildCodec()
	if err != nil {
		return nil, fmt.Errorf("init child vault codec: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	evt, err := pvCodec.DecodeRebalanceInitiated(log)
	if err != nil {
		return nil, fmt.Errorf("decode RebalanceInitiated: %w", err)
	}

	if !onchain.MatchSource(config, log, sourceChain, parentCfg.ChainSelector) {
		return workflowtypes.Noop(runtime, "wrong rebalance event source")
	}
	rebalance := snapshot.Parent.Rebalance
	if rebalance.State != onchain.Rebalancing || rebalance.Nonce.Cmp(evt.RebalanceNonce) != 0 {
		return workflowtypes.Noop(runtime, "stale rebalance event")
	}
	if rebalance.PendingStrategy.ProtocolId != evt.ProtocolId || rebalance.PendingStrategy.ChainSelector != evt.ChainSelector {
		return workflowtypes.Noop(runtime, "rebalance destination mismatch")
	}
	// Guard: active strategy on parent chain - no remote ChildVault to drive for this step.
	if rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector {
		logger.Info("RebalanceInitiated: active strategy on parent; no action required",
			slog.Any("nonce", evt.RebalanceNonce),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: active strategy on parent"}, nil
	}

	prevChainCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, rebalance.ActiveStrategy.ChainSelector)
	if err != nil {
		return nil, fmt.Errorf("find prev strategy chain: %w", err)
	}

	child := snapshot.Children[prevChainCfg.ChainSelector]
	if evt.RebalanceNonce.Cmp(child.LastHandledRebalanceNonce) <= 0 {
		return workflowtypes.Noop(runtime, "rebalance already handled")
	}
	if _, err := helper.FindEvmConfigByChainSelector(config.Evms, evt.ChainSelector); err != nil {
		return nil, err
	}

	// Encode executeRebalance for the previous strategy's ChildVault.
	calldata, err := cvCodec.EncodeExecuteRebalanceMethodCall(
		child_vault.ExecuteRebalanceInput{
			RebalanceNonce: evt.RebalanceNonce,
			NewStrategy: child_vault.TypesStrategy{
				ProtocolId:    evt.ProtocolId,
				ChainSelector: evt.ChainSelector,
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("encode executeRebalance: %w", err)
	}

	if err := submit(runtime, *prevChainCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit executeRebalance: %w", err)
	}

	logger.Info("Submitted executeRebalance",
		slog.Any("nonce", evt.RebalanceNonce),
		slog.String("prevChain", prevChainCfg.ChainName),
	)
	return &workflowtypes.ExecutionResult{Result: "submitted executeRebalance"}, nil
}

func OnRebalanceDepositSuccess(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64) (*workflowtypes.ExecutionResult, error) {
	return onRebalanceDepositSuccessWithDeps(config, runtime, log, snapshot, sourceChain, onchain.SubmitReport)
}

func onRebalanceDepositSuccessWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64, submit onchain.Submitter) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	evt, err := pvCodec.DecodeRebalanceDepositSuccess(log)
	if err != nil {
		return nil, fmt.Errorf("decode RebalanceDepositSuccess: %w", err)
	}

	rebalance := snapshot.Parent.Rebalance
	if rebalance.State != onchain.Rebalancing || rebalance.Nonce.Cmp(evt.RebalanceNonce) != 0 {
		return workflowtypes.Noop(runtime, "stale rebalance event")
	}
	if rebalance.PendingStrategy.ChainSelector == parentCfg.ChainSelector ||
		!onchain.MatchSource(config, log, sourceChain, rebalance.PendingStrategy.ChainSelector) {
		return workflowtypes.Noop(runtime, "wrong rebalance destination")
	}

	// Encode and submit completeRebalance to ParentVault.
	calldata, err := pvCodec.EncodeCompleteRebalanceMethodCall(parent_vault.CompleteRebalanceInput{ExpectedRebalanceNonce: evt.RebalanceNonce})
	if err != nil {
		return nil, fmt.Errorf("encode completeRebalance: %w", err)
	}

	if err := submit(runtime, parentCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit completeRebalance: %w", err)
	}

	logger.Info("Submitted completeRebalance", slog.Any("nonce", evt.RebalanceNonce))
	return &workflowtypes.ExecutionResult{Result: "submitted completeRebalance"}, nil
}
