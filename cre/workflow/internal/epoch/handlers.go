package epoch

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
	"cre/workflow/internal/onchain"
	"cre/workflow/internal/workflowtypes"
)

const minEpochPeriod = int64(3600) // matches MIN_EPOCH_PERIOD in ParentVault.sol

type parentCodec interface {
	EncodeCloseEpochMethodCall(parent_vault.CloseEpochInput) ([]byte, error)
	DecodeEpochExecuting(*evm.Log) (*parent_vault.EpochExecutingDecoded, error)
}

type childCodec interface {
	EncodeExecuteEpochWithdrawMethodCall(child_vault.ExecuteEpochWithdrawInput) ([]byte, error)
}

var (
	newParentCodec = func() (parentCodec, error) {
		return parent_vault.NewCodec()
	}
	newChildCodec = func() (childCodec, error) {
		return child_vault.NewCodec()
	}
	newParentVaultBinding = onchain.NewParentVaultBinding
	newChildVaultBinding  = onchain.NewChildVaultBinding
)

// InitiatorDeps holds the injectable dependencies for the EpochInitiator handler.
type InitiatorDeps struct {
	GetRebalance  func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (parent_vault.TypesRebalance, error)
	GetEpochNonce func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (*big.Int, error)
	GetEpoch      func(runtime cre.Runtime, vault onchain.ParentVaultInterface, epochNonce *big.Int, blockNumber *big.Int) (parent_vault.TypesEpoch, error)
	ReadTVL       func(runtime cre.Runtime, vault onchain.BaseVaultInterface, blockNumber *big.Int) (*big.Int, error)
	SubmitReport  func(runtime cre.Runtime, client *evm.Client, router common.Address, calldata []byte, gasLimit uint64) error
}

// ExecutorDeps holds the injectable dependencies for the EpochExecutor handler.
type ExecutorDeps struct {
	GetRebalance func(runtime cre.Runtime, vault onchain.ParentVaultInterface, blockNumber *big.Int) (parent_vault.TypesRebalance, error)
	SubmitReport func(runtime cre.Runtime, client *evm.Client, router common.Address, calldata []byte, gasLimit uint64) error
}

var defaultInitiatorDeps = InitiatorDeps{
	GetRebalance:  onchain.GetRebalance,
	GetEpochNonce: onchain.GetEpochNonce,
	GetEpoch:      onchain.GetEpoch,
	ReadTVL:       onchain.ReadTVL,
	SubmitReport:  onchain.SubmitReport,
}

var defaultExecutorDeps = ExecutorDeps{
	GetRebalance: onchain.GetRebalance,
	SubmitReport: onchain.SubmitReport,
}

func OnEpochCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload) (*workflowtypes.ExecutionResult, error) {
	return onEpochCronTriggerWithDeps(config, runtime, trigger, defaultInitiatorDeps)
}

func onEpochCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, _ *cron.Payload, deps InitiatorDeps) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	parentVaultBinding, err := newParentVaultBinding(
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		parentCfg.VaultAddress,
	)
	if err != nil {
		return nil, fmt.Errorf("bind parent vault: %w", err)
	}

	blockNumber := big.NewInt(config.BlockNumber)

	// Guard 1: skip if a rebalance is in progress (avoids conflicting state).
	rebalance, err := deps.GetRebalance(runtime, parentVaultBinding, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get rebalance: %w", err)
	}
	if rebalance.State != 0 {
		logger.Info("Rebalance in progress; skipping epoch close")
		return &workflowtypes.ExecutionResult{Result: "no-op: rebalance in progress"}, nil
	}

	// Guard 2: read the current epoch.
	epochNonce, err := deps.GetEpochNonce(runtime, parentVaultBinding, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get epoch nonce: %w", err)
	}
	if epochNonce == nil {
		return nil, fmt.Errorf("get epoch nonce: nil epoch nonce")
	}
	epoch, err := deps.GetEpoch(runtime, parentVaultBinding, epochNonce, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("get epoch: %w", err)
	}

	// Guard 3: epoch must be OPEN (status 1).
	if epoch.Status != 1 {
		logger.Info("Epoch not open; skipping", slog.Uint64("status", uint64(epoch.Status)))
		return &workflowtypes.ExecutionResult{Result: "no-op: epoch not open"}, nil
	}
	if err := validateEpochCloseFields(epoch); err != nil {
		return nil, fmt.Errorf("get epoch: %w", err)
	}

	// Guard 4: skip if there is no activity to settle.
	zero := big.NewInt(0)
	if epoch.TotalDepositAmount.Cmp(zero) == 0 && epoch.TotalShareBurnAmount.Cmp(zero) == 0 {
		logger.Info("No epoch activity; skipping")
		return &workflowtypes.ExecutionResult{Result: "no-op: no activity"}, nil
	}

	// Guard 5: skip if the epoch hasn't been open long enough.
	if runtime.Now().Unix() < epoch.OpenedAtTimestamp.Int64()+minEpochPeriod {
		logger.Info("Epoch too young; skipping",
			slog.Int64("openedAt", epoch.OpenedAtTimestamp.Int64()),
			slog.Int64("minCloseAt", epoch.OpenedAtTimestamp.Int64()+minEpochPeriod),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: epoch too young"}, nil
	}

	// Read TVL from whichever vault holds the active strategy.
	var tvlVault onchain.BaseVaultInterface
	if rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector {
		tvlVault = parentVaultBinding
	} else {
		stratCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, rebalance.ActiveStrategy.ChainSelector)
		if err != nil {
			return nil, fmt.Errorf("find strategy chain: %w", err)
		}
		tvlVault, err = newChildVaultBinding(
			&evm.Client{ChainSelector: stratCfg.ChainSelector},
			stratCfg.VaultAddress,
		)
		if err != nil {
			return nil, fmt.Errorf("bind child vault: %w", err)
		}
	}

	tvl, err := deps.ReadTVL(runtime, tvlVault, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("read tvl: %w", err)
	}
	if tvl == nil {
		return nil, fmt.Errorf("read tvl: nil tvl")
	}

	calldata, err := pvCodec.EncodeCloseEpochMethodCall(
		parent_vault.CloseEpochInput{EpochNonce: epochNonce, Tvl: tvl},
	)
	if err != nil {
		return nil, fmt.Errorf("encode closeEpoch: %w", err)
	}

	if err := deps.SubmitReport(
		runtime,
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		common.HexToAddress(parentCfg.WorkflowRouterAddress),
		calldata,
		parentCfg.GasLimit,
	); err != nil {
		return nil, fmt.Errorf("submit closeEpoch: %w", err)
	}

	logger.Info("Closed epoch", slog.Any("nonce", epochNonce), slog.Any("tvl", tvl))
	return &workflowtypes.ExecutionResult{Result: "closed epoch"}, nil
}

func validateEpochCloseFields(epoch parent_vault.TypesEpoch) error {
	if epoch.TotalDepositAmount == nil {
		return fmt.Errorf("nil total deposit amount")
	}
	if epoch.TotalShareBurnAmount == nil {
		return fmt.Errorf("nil total share burn amount")
	}
	if epoch.OpenedAtTimestamp == nil {
		return fmt.Errorf("nil opened at timestamp")
	}
	return nil
}

func OnEpochExecuting(config *helper.Config, runtime cre.Runtime, log *evm.Log) (*workflowtypes.ExecutionResult, error) {
	return onEpochExecutingWithDeps(config, runtime, log, defaultExecutorDeps)
}

func onEpochExecutingWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, deps ExecutorDeps) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}
	cvCodec, err := newChildCodec()
	if err != nil {
		return nil, fmt.Errorf("init child vault codec: %w", err)
	}

	evt, err := pvCodec.DecodeEpochExecuting(log)
	if err != nil {
		return nil, fmt.Errorf("decode EpochExecuting: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	parentVaultBinding, err := newParentVaultBinding(
		&evm.Client{ChainSelector: parentCfg.ChainSelector},
		parentCfg.VaultAddress,
	)
	if err != nil {
		return nil, fmt.Errorf("bind parent vault: %w", err)
	}

	// Read the active strategy to find which child chain to call.
	rebalance, err := deps.GetRebalance(runtime, parentVaultBinding, big.NewInt(config.BlockNumber))
	if err != nil {
		return nil, fmt.Errorf("get rebalance: %w", err)
	}

	if rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector {
		logger.Info("EpochExecuting: active strategy on parent; no action required",
			slog.Any("nonce", evt.EpochNonce),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: active strategy on parent"}, nil
	}

	stratCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, rebalance.ActiveStrategy.ChainSelector)
	if err != nil {
		return nil, fmt.Errorf("find strategy chain: %w", err)
	}

	calldata, err := cvCodec.EncodeExecuteEpochWithdrawMethodCall(
		child_vault.ExecuteEpochWithdrawInput{EpochNonce: evt.EpochNonce, Amount: evt.Amount},
	)
	if err != nil {
		return nil, fmt.Errorf("encode executeEpochWithdraw: %w", err)
	}

	if err := deps.SubmitReport(
		runtime,
		&evm.Client{ChainSelector: stratCfg.ChainSelector},
		common.HexToAddress(stratCfg.WorkflowRouterAddress),
		calldata,
		stratCfg.GasLimit,
	); err != nil {
		return nil, fmt.Errorf("submit executeEpochWithdraw: %w", err)
	}

	logger.Info("Submitted executeEpochWithdraw",
		slog.Any("nonce", evt.EpochNonce),
		slog.Any("amount", evt.Amount),
		slog.String("strategyChain", stratCfg.ChainName),
	)
	return &workflowtypes.ExecutionResult{Result: "submitted executeEpochWithdraw"}, nil
}
