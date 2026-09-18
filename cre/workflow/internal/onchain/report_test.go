package onchain

import (
	"cre/workflow/internal/helper"
	"encoding/binary"
	"errors"
	"io"
	"log/slog"
	"math/rand"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	sdkpb "github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/chainlink-protos/cre/go/values"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"
)

var errNotImplemented = errors.New("not implemented")

type mockRuntime struct {
	reportRequest     *cre.ReportRequest
	report            *cre.Report
	reportErr         error
	capabilityRequest *sdkpb.CapabilityRequest
	capabilityReply   *evm.WriteReportReply
	capabilityErr     error
	logger            *slog.Logger
	now               int64
}

type nilResponseReportWriter struct{}

func (nilResponseReportWriter) WriteReport(
	cre.Runtime,
	*evm.WriteCreReportRequest,
) cre.Promise[*evm.WriteReportReply] {
	return cre.PromiseFromResult[*evm.WriteReportReply](nil, nil)
}

func newMockRuntime(t *testing.T) *mockRuntime {
	t.Helper()

	contractStatus := evm.ReceiverContractExecutionStatus_RECEIVER_CONTRACT_EXECUTION_STATUS_SUCCESS
	return &mockRuntime{
		report:          validReport(t),
		capabilityReply: writeReportReply(evm.TxStatus_TX_STATUS_SUCCESS, &contractStatus, ""),
		logger:          slog.New(slog.NewTextHandler(io.Discard, nil)),
	}
}

func (m *mockRuntime) CallCapability(request *sdkpb.CapabilityRequest) cre.Promise[*sdkpb.CapabilityResponse] {
	m.capabilityRequest = request
	if m.capabilityErr != nil {
		return cre.PromiseFromResult[*sdkpb.CapabilityResponse](nil, m.capabilityErr)
	}

	payload, err := anypb.New(m.capabilityReply)
	if err != nil {
		return cre.PromiseFromResult[*sdkpb.CapabilityResponse](nil, err)
	}

	return cre.PromiseFromResult(&sdkpb.CapabilityResponse{
		Response: &sdkpb.CapabilityResponse_Payload{Payload: payload},
	}, nil)
}

func (m *mockRuntime) Rand() (*rand.Rand, error) {
	return rand.New(rand.NewSource(1)), nil
}

func (m *mockRuntime) Now() time.Time {
	return time.Unix(m.now, 0)
}

func (m *mockRuntime) Logger() *slog.Logger {
	return m.logger
}

func (m *mockRuntime) RunInNodeMode(func(cre.NodeRuntime) *sdkpb.SimpleConsensusInputs) cre.Promise[values.Value] {
	return cre.PromiseFromResult[values.Value](nil, errNotImplemented)
}

func (m *mockRuntime) GenerateReport(request *cre.ReportRequest) cre.Promise[*cre.Report] {
	m.reportRequest = request
	return cre.PromiseFromResult(m.report, m.reportErr)
}

func (m *mockRuntime) GetSecret(*cre.SecretRequest) cre.Promise[*cre.Secret] {
	return cre.PromiseFromResult[*cre.Secret](nil, errNotImplemented)
}

func (m *mockRuntime) GetSecrets([]*cre.SecretRequest) cre.Promise[[]*cre.Secret] {
	return cre.PromiseFromResult[[]*cre.Secret](nil, errNotImplemented)
}

func validReport(t *testing.T) *cre.Report {
	t.Helper()

	report, err := cre.X_GeneratedCodeOnly_WrapReport(&sdkpb.ReportResponse{
		RawReport: make([]byte, cre.ReportMetadataHeaderLength),
	})
	require.NoError(t, err, "expected valid report fixture")
	return report
}

func writeReportReply(
	txStatus evm.TxStatus,
	contractStatus *evm.ReceiverContractExecutionStatus,
	errorMessage string,
) *evm.WriteReportReply {
	reply := &evm.WriteReportReply{
		TxStatus:                        txStatus,
		ReceiverContractExecutionStatus: contractStatus,
		TxHash:                          []byte{0x12, 0x34},
	}
	if errorMessage != "" {
		reply.ErrorMessage = &errorMessage
	}
	return reply
}

func Test_SubmitReport_success(t *testing.T) {
	runtime := newMockRuntime(t)
	workflowRouter := common.HexToAddress("0x0000000000000000000000000000000000000002")
	calldata := []byte{0xde, 0xad, 0xbe, 0xef}
	gasLimit := uint64(500_000)

	err := SubmitReport(runtime, helper.EvmConfig{ChainSelector: 123, WorkflowRouterAddress: workflowRouter.Hex(), GasLimit: gasLimit}, 0, calldata)
	require.NoError(t, err, "expected successful report submission")

	require.NotNil(t, runtime.reportRequest, "expected report request")
	require.Equal(t, calldata, runtime.reportRequest.EncodedPayload[60:], "unexpected vault calldata")
	require.Equal(t, uint64(123), binary.BigEndian.Uint64(runtime.reportRequest.EncodedPayload[:8]))
	require.Equal(t, workflowRouter.Bytes(), runtime.reportRequest.EncodedPayload[8:28])
	require.Equal(t, make([]byte, 32), runtime.reportRequest.EncodedPayload[28:60])
	require.Equal(t, "evm", runtime.reportRequest.EncoderName, "unexpected encoder")
	require.Equal(t, "ecdsa", runtime.reportRequest.SigningAlgo, "unexpected signing algorithm")
	require.Equal(t, "keccak256", runtime.reportRequest.HashingAlgo, "unexpected hashing algorithm")

	request := decodeWriteReportRequest(t, runtime.capabilityRequest)
	require.Equal(t, workflowRouter.Bytes(), request.Receiver, "unexpected receiver")
	require.Equal(t, gasLimit, request.GasConfig.GasLimit, "unexpected gas limit")
	require.True(t, proto.Equal(runtime.report.X_GeneratedCodeOnly_Unwrap(), request.Report), "unexpected report")
}

func Test_SubmitReport_generateReportError(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.reportErr = errors.New("generate failed")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected generate report error")
	require.ErrorContains(t, err, "generate report: generate failed")
	require.Nil(t, runtime.capabilityRequest, "expected no write when report generation fails")
}

func Test_SubmitReport_nilReport(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.report = nil

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected error when report is nil")
	require.ErrorContains(t, err, "generate report: nil report")
	require.Nil(t, runtime.capabilityRequest, "expected no write when report is nil")
}

func Test_SubmitReport_writeReportError(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityErr = errors.New("write failed")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected write report error")
	require.ErrorContains(t, err, "write report: write failed")
}

func Test_SubmitReport_nilWriteReportResponse(t *testing.T) {
	runtime := newMockRuntime(t)

	err := submitReport(runtime, nilResponseReportWriter{}, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected error when write report response is nil")
	require.ErrorContains(t, err, "write report: nil response")
}

func Test_SubmitReport_txNotSuccessWithErrorMessage(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_REVERTED, nil, "reverted")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected reverted tx error")
	require.ErrorContains(t, err, "tx not success: status=TX_STATUS_REVERTED err=reverted")
}

func Test_SubmitReport_txNotSuccessWithoutErrorMessage(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_FATAL, nil, "")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected fatal tx error")
	require.ErrorContains(t, err, "tx not success: status=TX_STATUS_FATAL err=unknown error")
}

func Test_SubmitReport_contractExecutionStatusMissing(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_SUCCESS, nil, "")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected missing contract execution status error")
	require.ErrorContains(t, err, "contract execution status missing")
}

func Test_SubmitReport_contractExecutionFailed(t *testing.T) {
	runtime := newMockRuntime(t)
	contractStatus := evm.ReceiverContractExecutionStatus_RECEIVER_CONTRACT_EXECUTION_STATUS_REVERTED
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_SUCCESS, &contractStatus, "")

	err := SubmitReport(runtime, newTestReportTarget(), 0, []byte{1, 2, 3, 4})
	require.Error(t, err, "expected contract execution error")
	require.ErrorContains(t, err, "contract execution failed: status=RECEIVER_CONTRACT_EXECUTION_STATUS_REVERTED")
}

func decodeWriteReportRequest(t *testing.T, capabilityRequest *sdkpb.CapabilityRequest) *evm.WriteReportRequest {
	t.Helper()

	require.NotNil(t, capabilityRequest, "expected capability request")
	require.Equal(t, "WriteReport", capabilityRequest.Method, "unexpected capability method")

	request := &evm.WriteReportRequest{}
	require.NoError(t, capabilityRequest.Payload.UnmarshalTo(request), "expected valid write report payload")
	return request
}

func newTestReportTarget() helper.EvmConfig {
	return helper.EvmConfig{ChainSelector: 123, WorkflowRouterAddress: "0x0000000000000000000000000000000000000002", GasLimit: 500_000}
}

func TestReportObservationWindow(t *testing.T) {
	for _, test := range []struct {
		name       string
		observedAt int64
		valid      bool
	}{
		{"now", 2000, true},
		{"exactly thirty minutes", 200, true},
		{"expired", 199, false},
		{"future", 2001, false},
		{"negative", -1, false},
	} {
		t.Run(test.name, func(t *testing.T) {
			runtime := newMockRuntime(t)
			runtime.now = 2000
			err := SubmitReport(runtime, newTestReportTarget(), test.observedAt, []byte{1, 2, 3, 4})
			if test.valid {
				require.NoError(t, err)
			} else {
				require.Error(t, err)
				require.Nil(t, runtime.reportRequest)
			}
		})
	}
}

func TestReportQuotaBoundaries(t *testing.T) {
	for _, size := range []int{0, 3, 4, 5060, 5061} {
		runtime := newMockRuntime(t)
		err := SubmitReport(runtime, newTestReportTarget(), 0, make([]byte, size))
		if size >= 4 && size <= 5060 {
			require.NoError(t, err)
		} else {
			require.ErrorContains(t, err, "calldata length")
			require.Nil(t, runtime.reportRequest)
		}
	}
	for _, gas := range []uint64{0, 5_000_000, 5_000_001} {
		runtime := newMockRuntime(t)
		target := newTestReportTarget()
		target.GasLimit = gas
		err := SubmitReport(runtime, target, 0, make([]byte, 4))
		if gas == 5_000_000 {
			require.NoError(t, err)
		} else {
			require.ErrorContains(t, err, "gas limit")
			require.Nil(t, runtime.reportRequest)
		}
	}
}
