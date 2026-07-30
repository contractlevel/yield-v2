package rebalance

import (
	"fmt"
	"log/slog"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
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

const epochStatusExecuting uint8 = 2

type parentCodec interface {
	EncodeInitiateRebalanceMethodCall(parent_vault.InitiateRebalanceInput) ([]byte, error)
	DecodeRebalanceInitiated(*evm.Log) (*parent_vault.RebalanceInitiatedDecoded, error)
	DecodeRebalanceDepositSuccess(*evm.Log) (*parent_vault.RebalanceDepositSuccessDecoded, error)
	EncodeCompleteRebalanceMethodCall() ([]byte, error)
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
	newParentVaultBinding = onchain.NewParentVaultBinding
)

// CronDeps holds the injectable dependencies for the RebalanceInitiator handler.
type CronDeps struct {
	FetchAndSelectPools func(runtime cre.Runtime, cfg offchain.Config, activeProtocolId [32]byte, activeChainSelector uint64) (*offchain.Pool, *offchain.Pool, error)
	GetRebalance        func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (parent_vault.TypesRebalance, error)
	GetEpochNonce       func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (*big.Int, error)
	GetEpoch            func(runtime cre.Runtime, vault onchain.ParentVaultInterface, epochNonce *big.Int, blockNumber *big.Int) (parent_vault.TypesEpoch, error)
	SubmitReport        func(runtime cre.Runtime, client *evm.Client, router common.Address, calldata []byte, gasLimit uint64) error
}

// ExecutorDeps holds the injectable dependencies for the RebalanceExecutor handler.
type ExecutorDeps struct {
	GetRebalance func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (parent_vault.TypesRebalance, error)
	SubmitReport func(runtime cre.Runtime, client *evm.Client, router common.Address, calldata []byte, gasLimit uint64) error
}

// CompleterDeps holds the injectable dependencies for the RebalanceCompleter handler.
type CompleterDeps struct {
	SubmitReport func(runtime cre.Runtime, client *evm.Client, router common.Address, calldata []byte, gasLimit uint64) error
}

var defaultCronDeps = CronDeps{
	FetchAndSelectPools: offchain.FetchAndSelectPools,
	GetRebalance:        onchain.GetRebalance,
	GetEpochNonce:       onchain.GetEpochNonce,
	GetEpoch:            onchain.GetEpoch,
	SubmitReport:        onchain.SubmitReport,
}

var defaultExecutorDeps = ExecutorDeps{
	GetRebalance: onchain.GetRebalance,
	SubmitReport: onchain.SubmitReport,
}

var defaultCompleterDeps = CompleterDeps{
	SubmitReport: onchain.SubmitReport,
}

func OnCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload) (*workflowtypes.ExecutionResult, error) {
	return onCronTriggerWithDeps(config, runtime, trigger, defaultCronDeps)
}

func onCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, _ *cron.Payload, deps CronDeps) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	// Read the active rebalance state from ParentVault.
	parentVault, err := newParentVaultBinding(
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		parentCfg.VaultAddress,
	)
	if err != nil {
		return nil, fmt.Errorf("bind parent vault: %w", err)
	}

	blockNumber := big.NewInt(config.BlockNumber)
	rebalance, err := deps.GetRebalance(runtime, parentVault, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get rebalance: %w", err)
	}

	// Guard: skip if a rebalance is already in progress.
	if rebalance.State != 0 {
		logger.Info("Rebalance already in progress; skipping")
		return &workflowtypes.ExecutionResult{Result: "no-op: rebalance in progress"}, nil
	}

	epochNonce, err := deps.GetEpochNonce(runtime, parentVault, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get epoch nonce: %w", err)
	}
	if epochNonce == nil {
		return nil, fmt.Errorf("get epoch nonce: nil epoch nonce")
	}
	if epochNonce.Cmp(big.NewInt(1)) <= 0 {
		logger.Info("No completed epoch; skipping rebalance")
		return &workflowtypes.ExecutionResult{Result: "no-op: no completed epoch"}, nil
	}

	previousEpochNonce := new(big.Int).Sub(epochNonce, big.NewInt(1))
	previousEpoch, err := deps.GetEpoch(runtime, parentVault, previousEpochNonce, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get previous epoch: %w", err)
	}
	if previousEpoch.Status == epochStatusExecuting {
		logger.Info("Epoch executing; skipping rebalance", slog.Any("epochNonce", previousEpochNonce))
		return &workflowtypes.ExecutionResult{Result: "no-op: epoch executing"}, nil
	}

	if rebalance.LastRebalanceCompletedTimestamp != nil && !RebalanceCooldownElapsed(rebalance.LastRebalanceCompletedTimestamp.Int64(), runtime.Now().Unix()) {
		logger.Info("Rebalance cooldown active; skipping",
			slog.Int64("lastCompletedAt", rebalance.LastRebalanceCompletedTimestamp.Int64()),
			slog.Int64("minNextRebalanceAt", rebalance.LastRebalanceCompletedTimestamp.Int64()+minRebalanceIntervalSeconds),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: rebalance cooldown active"}, nil
	}

	activeStrategy := rebalance.ActiveStrategy
	defiLlamaConfig := newDefiLlamaConfig(config)

	// Query DefiLlama for the best and current approved pools.
	bestPool, currentPool, err := deps.FetchAndSelectPools(runtime, defiLlamaConfig, activeStrategy.ProtocolId, activeStrategy.ChainSelector)
	if err != nil {
		return nil, fmt.Errorf("fetch pools: %w", err)
	}

	if bestPool == nil {
		logger.Info("No approved pool found; skipping rebalance")
		return &workflowtypes.ExecutionResult{Result: "no-op: no approved pool"}, nil
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
		return &workflowtypes.ExecutionResult{Result: "no-op: already optimal"}, nil
	}

	// @review this is where we would read the TVL of the active strategy and pass it to onchain helper to calculate APY impact

	if currentPool == nil {
		logger.Info("Current pool missing from DefiLlama response; skipping rebalance")
		return &workflowtypes.ExecutionResult{Result: "no-op: current pool missing"}, nil
	}

	// Check that the APY improvement exceeds the differential threshold.
	if !NeedRebalance(bestPool, currentPool) {
		delta := bestPool.Apy
		delta -= currentPool.Apy
		logger.Info("APY delta below threshold; skipping rebalance",
			slog.Float64("delta", delta),
			slog.Float64("threshold", DifferentialThreshold),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: below threshold"}, nil
	}

	// Encode and submit initiateRebalance to ParentVault.
	calldata, err := pvCodec.EncodeInitiateRebalanceMethodCall(
		parent_vault.InitiateRebalanceInput{
			NewStrategy: parent_vault.TypesStrategy{
				ProtocolId:    bestProtocolId,
				ChainSelector: bestChainSelector,
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("encode initiateRebalance: %w", err)
	}

	if err := deps.SubmitReport(
		runtime,
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		common.HexToAddress(parentCfg.WorkflowRouterAddress),
		calldata,
		parentCfg.GasLimit,
	); err != nil {
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

func OnRebalanceInitiated(config *helper.Config, runtime cre.Runtime, log *evm.Log) (*workflowtypes.ExecutionResult, error) {
	return onRebalanceInitiatedWithDeps(config, runtime, log, defaultExecutorDeps)
}

func onRebalanceInitiatedWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, deps ExecutorDeps) (*workflowtypes.ExecutionResult, error) {
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

	// Read current rebalance to find the PREVIOUS (active) strategy chain.
	// At this point ActiveStrategy is still the old strategy; PendingStrategy is the new one.
	parentVaultBinding, err := newParentVaultBinding(
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		parentCfg.VaultAddress,
	)
	if err != nil {
		return nil, fmt.Errorf("bind parent vault: %w", err)
	}

	rebalance, err := deps.GetRebalance(runtime, parentVaultBinding, big.NewInt(config.BlockNumber))
	if err != nil {
		return nil, fmt.Errorf("get rebalance: %w", err)
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

	if err := deps.SubmitReport(
		runtime,
		&evm.Client{ChainSelector: prevChainCfg.ChainSelector},
		common.HexToAddress(prevChainCfg.WorkflowRouterAddress),
		calldata,
		prevChainCfg.GasLimit,
	); err != nil {
		return nil, fmt.Errorf("submit executeRebalance: %w", err)
	}

	logger.Info("Submitted executeRebalance",
		slog.Any("nonce", evt.RebalanceNonce),
		slog.String("prevChain", prevChainCfg.ChainName),
	)
	return &workflowtypes.ExecutionResult{Result: "submitted executeRebalance"}, nil
}

func OnRebalanceDepositSuccess(config *helper.Config, runtime cre.Runtime, log *evm.Log) (*workflowtypes.ExecutionResult, error) {
	return onRebalanceDepositSuccessWithDeps(config, runtime, log, defaultCompleterDeps)
}

func onRebalanceDepositSuccessWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, deps CompleterDeps) (*workflowtypes.ExecutionResult, error) {
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

	// Encode and submit completeRebalance to ParentVault.
	calldata, err := pvCodec.EncodeCompleteRebalanceMethodCall()
	if err != nil {
		return nil, fmt.Errorf("encode completeRebalance: %w", err)
	}

	if err := deps.SubmitReport(
		runtime,
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		common.HexToAddress(parentCfg.WorkflowRouterAddress),
		calldata,
		parentCfg.GasLimit,
	); err != nil {
		return nil, fmt.Errorf("submit completeRebalance: %w", err)
	}

	logger.Info("Submitted completeRebalance", slog.Any("nonce", evt.RebalanceNonce))
	return &workflowtypes.ExecutionResult{Result: "submitted completeRebalance"}, nil
}
