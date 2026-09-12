package epoch

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
	"cre/workflow/internal/onchain"
	"cre/workflow/internal/workflowtypes"
)

const minEpochPeriod = int64(3600) // matches MIN_EPOCH_PERIOD in ParentVault.sol

type parentCodec interface {
	EncodeCloseEpochMethodCall(parent_vault.CloseEpochInput) ([]byte, error)
	EncodeCompleteEpochDepositMethodCall(parent_vault.CompleteEpochDepositInput) ([]byte, error)
	DecodeEpochWithdrawExecuting(*evm.Log) (*parent_vault.EpochWithdrawExecutingDecoded, error)
}

type childCodec interface {
	EncodeExecuteEpochWithdrawMethodCall(child_vault.ExecuteEpochWithdrawInput) ([]byte, error)
	DecodeEpochDepositToStrategySuccess(*evm.Log) (*child_vault.EpochDepositToStrategySuccessDecoded, error)
}

var (
	newParentCodec = func() (parentCodec, error) {
		return parent_vault.NewCodec()
	}
	newChildCodec = func() (childCodec, error) {
		return child_vault.NewCodec()
	}
)

func OnEpochCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload, snapshot *onchain.Snapshot) (*workflowtypes.ExecutionResult, error) {
	return onEpochCronTriggerWithDeps(config, runtime, trigger, snapshot, onchain.SubmitReport)
}

func onEpochCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, _ *cron.Payload, snapshot *onchain.Snapshot, submit onchain.Submitter) (*workflowtypes.ExecutionResult, error) {
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
	epoch := parent.CurrentEpoch
	epochNonce := parent.CurrentEpochNonce
	if parent.Rebalance.State != onchain.RebalanceNone {
		return workflowtypes.Noop(runtime, "rebalance in progress")
	}
	if epochNonce.Cmp(big.NewInt(1)) > 0 && parent.PreviousEpoch.Status != onchain.EpochClaimable {
		return workflowtypes.Noop(runtime, "previous epoch not claimable")
	}
	if epoch.Status != onchain.EpochOpen {
		return workflowtypes.Noop(runtime, "epoch not open")
	}
	if !onchain.PeriodElapsed(epoch.OpenedAtTimestamp, snapshot.ObservedAt, minEpochPeriod) {
		return workflowtypes.Noop(runtime, "epoch too young")
	}
	tvl, err := snapshot.ActiveTVL(parentCfg.ChainSelector)
	if err != nil {
		return nil, err
	}
	isLocal := parent.Rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector
	if _, err := calculateEpochClose(epoch, parent.TotalShares, tvl, *config.AssetDecimals, isLocal); err != nil {
		return workflowtypes.Noop(runtime, err.Error())
	}

	calldata, err := pvCodec.EncodeCloseEpochMethodCall(
		parent_vault.CloseEpochInput{ExpectedEpochNonce: epochNonce, Tvl: tvl},
	)
	if err != nil {
		return nil, fmt.Errorf("encode closeEpoch: %w", err)
	}

	if err := submit(runtime, parentCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit closeEpoch: %w", err)
	}

	logger.Info("Closed epoch", slog.Any("nonce", epochNonce), slog.Any("tvl", tvl))
	return &workflowtypes.ExecutionResult{Result: "closed epoch"}, nil
}

func OnEpochWithdrawExecuting(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64) (*workflowtypes.ExecutionResult, error) {
	return onEpochWithdrawExecutingWithDeps(config, runtime, log, snapshot, sourceChain, onchain.SubmitReport)
}

func onEpochWithdrawExecutingWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64, submit onchain.Submitter) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}
	cvCodec, err := newChildCodec()
	if err != nil {
		return nil, fmt.Errorf("init child vault codec: %w", err)
	}

	evt, err := pvCodec.DecodeEpochWithdrawExecuting(log)
	if err != nil {
		return nil, fmt.Errorf("decode EpochWithdrawExecuting: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}

	if !onchain.MatchSource(config, log, sourceChain, parentCfg.ChainSelector) {
		return workflowtypes.Noop(runtime, "wrong epoch event source")
	}
	parent := snapshot.Parent
	rebalance := parent.Rebalance
	if rebalance.State != onchain.RebalanceNone {
		return workflowtypes.Noop(runtime, "rebalance in progress")
	}
	if !matchesExecutingEpoch(parent, evt.EpochNonce) {
		return workflowtypes.Noop(runtime, "stale epoch event")
	}
	expectedAmount := new(big.Int).Sub(parent.PreviousEpoch.TotalWithdrawClaimAmount, parent.PreviousEpoch.TotalDepositAmount)
	if expectedAmount.Sign() <= 0 || evt.Amount.Sign() <= 0 || expectedAmount.Cmp(evt.Amount) != 0 {
		return workflowtypes.Noop(runtime, "epoch withdrawal amount mismatch")
	}

	if rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector {
		logger.Info("EpochWithdrawExecuting: active strategy on parent; no action required",
			slog.Any("nonce", evt.EpochNonce),
		)
		return &workflowtypes.ExecutionResult{Result: "no-op: active strategy on parent"}, nil
	}

	stratCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, rebalance.ActiveStrategy.ChainSelector)
	if err != nil {
		return nil, fmt.Errorf("find strategy chain: %w", err)
	}

	child := snapshot.Children[stratCfg.ChainSelector]
	if evt.EpochNonce.Cmp(child.LastHandledEpochNonce) <= 0 {
		return workflowtypes.Noop(runtime, "epoch already handled")
	}
	// Submit the original amount even if observed TVL is insufficient.
	// ChildVault catches adapter failure and records epoch-withdraw recovery.

	calldata, err := cvCodec.EncodeExecuteEpochWithdrawMethodCall(
		child_vault.ExecuteEpochWithdrawInput{EpochNonce: evt.EpochNonce, Amount: evt.Amount},
	)
	if err != nil {
		return nil, fmt.Errorf("encode executeEpochWithdraw: %w", err)
	}

	if err := submit(runtime, *stratCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit executeEpochWithdraw: %w", err)
	}

	logger.Info("Submitted executeEpochWithdraw",
		slog.Any("nonce", evt.EpochNonce),
		slog.Any("amount", evt.Amount),
		slog.String("strategyChain", stratCfg.ChainName),
	)
	return &workflowtypes.ExecutionResult{Result: "submitted executeEpochWithdraw"}, nil
}

func OnEpochDepositToStrategySuccess(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64) (*workflowtypes.ExecutionResult, error) {
	return onEpochDepositToStrategySuccessWithDeps(config, runtime, log, snapshot, sourceChain, onchain.SubmitReport)
}

func onEpochDepositToStrategySuccessWithDeps(config *helper.Config, runtime cre.Runtime, log *evm.Log, snapshot *onchain.Snapshot, sourceChain uint64, submit onchain.Submitter) (*workflowtypes.ExecutionResult, error) {
	logger := runtime.Logger()

	cvCodec, err := newChildCodec()
	if err != nil {
		return nil, fmt.Errorf("init child vault codec: %w", err)
	}
	evt, err := cvCodec.DecodeEpochDepositToStrategySuccess(log)
	if err != nil {
		return nil, fmt.Errorf("decode EpochDepositToStrategySuccess: %w", err)
	}

	parentCfg, err := helper.FindParent(config.Evms)
	if err != nil {
		return nil, err
	}
	parent := snapshot.Parent
	if parent.Rebalance.ActiveStrategy.ChainSelector == parentCfg.ChainSelector ||
		!onchain.MatchSource(config, log, sourceChain, parent.Rebalance.ActiveStrategy.ChainSelector) {
		return workflowtypes.Noop(runtime, "wrong epoch deposit destination")
	}
	if !matchesExecutingEpoch(parent, evt.EpochNonce) {
		return workflowtypes.Noop(runtime, "stale epoch event")
	}
	if _, err := reconcileEpochDeposit(parent.PreviousEpoch, parent.TotalShares, evt.Amount); err != nil {
		return workflowtypes.Noop(runtime, err.Error())
	}

	pvCodec, err := newParentCodec()
	if err != nil {
		return nil, fmt.Errorf("init parent vault codec: %w", err)
	}
	calldata, err := pvCodec.EncodeCompleteEpochDepositMethodCall(parent_vault.CompleteEpochDepositInput{ExpectedEpochNonce: evt.EpochNonce, ActualDepositAmount: evt.Amount})
	if err != nil {
		return nil, fmt.Errorf("encode completeEpochDeposit: %w", err)
	}

	if err := submit(runtime, parentCfg, snapshot.ObservedAt, calldata); err != nil {
		return nil, fmt.Errorf("submit completeEpochDeposit: %w", err)
	}

	logger.Info("Completed epoch deposit",
		slog.Any("nonce", evt.EpochNonce),
		slog.Any("amount", evt.Amount),
	)
	return &workflowtypes.ExecutionResult{Result: "completed epoch deposit"}, nil
}

func matchesExecutingEpoch(parent parent_vault.TypesParentOperationalState, eventNonce *big.Int) bool {
	previousNonce := new(big.Int).Sub(parent.CurrentEpochNonce, big.NewInt(1))
	return parent.CurrentEpochNonce.Cmp(big.NewInt(1)) > 0 &&
		previousNonce.Cmp(eventNonce) == 0 &&
		parent.PreviousEpoch.Status == onchain.EpochExecuting
}
