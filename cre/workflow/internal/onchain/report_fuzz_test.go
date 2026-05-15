package onchain

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
)

func Fuzz_SubmitReport_propagatesWriteInputs(f *testing.F) {
	f.Add([]byte{0xde, 0xad, 0xbe, 0xef}, uint64(500_000), "0x0000000000000000000000000000000000000002")
	f.Add([]byte{}, uint64(0), "0x0000000000000000000000000000000000000000")

	f.Fuzz(func(t *testing.T, calldata []byte, gasLimit uint64, router string) {
		if !common.IsHexAddress(router) {
			t.Skip("router must be a valid EVM address")
		}

		runtime := newMockRuntime(t)
		evmClient := &evm.Client{ChainSelector: 123}
		workflowRouter := common.HexToAddress(router)

		err := SubmitReport(runtime, evmClient, workflowRouter, calldata, gasLimit)
		require.NoError(t, err, "expected successful report submission")

		require.NotNil(t, runtime.reportRequest, "expected report request")
		require.Equal(t, calldata, runtime.reportRequest.EncodedPayload, "unexpected report payload")

		request := decodeWriteReportRequest(t, runtime.capabilityRequest)
		require.Equal(t, workflowRouter.Bytes(), request.Receiver, "unexpected receiver")
		require.Equal(t, gasLimit, request.GasConfig.GasLimit, "unexpected gas limit")
		require.True(t, proto.Equal(runtime.report.X_GeneratedCodeOnly_Unwrap(), request.Report), "unexpected report")
	})
}
