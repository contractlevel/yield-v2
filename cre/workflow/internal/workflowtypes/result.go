package workflowtypes

import "github.com/smartcontractkit/cre-sdk-go/cre"

type ExecutionResult struct {
	Result string
}

func Noop(runtime cre.Runtime, reason string) (*ExecutionResult, error) {
	runtime.Logger().Info("Workflow skipped", "reason", reason)
	return &ExecutionResult{Result: "no-op: " + reason}, nil
}
