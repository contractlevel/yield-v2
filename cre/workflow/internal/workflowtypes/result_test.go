package workflowtypes

import (
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

func TestNoopReportsReason(t *testing.T) {
	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	result, err := Noop(runtime, "vault paused on Base")
	require.NoError(t, err)
	require.Equal(t, "no-op: vault paused on Base", result.Result)
	logs := runtime.GetLogs()
	require.Len(t, logs, 1)
	require.Contains(t, string(logs[0]), "vault paused on Base")
}
