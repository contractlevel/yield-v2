package workflowtypes

import "github.com/smartcontractkit/cre-sdk-go/cre"

type ExecutionResult struct {
	Result string
}

func Noop(runtime cre.Runtime, reason string, args ...any) (*ExecutionResult, error) {
	args = append([]any{"reason", reason}, args...)
	runtime.Logger().Info("Workflow skipped", args...)
	return &ExecutionResult{Result: "no-op: " + reason}, nil
}
