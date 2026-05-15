package onchain

import (
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
}

func newMockRuntime(t *testing.T) *mockRuntime {
	t.Helper()

	return &mockRuntime{
		report:          validReport(t),
		capabilityReply: writeReportReply(evm.TxStatus_TX_STATUS_SUCCESS, nil, ""),
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
	return time.Unix(0, 0)
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
	evmClient := &evm.Client{ChainSelector: 123}
	workflowRouter := common.HexToAddress("0x0000000000000000000000000000000000000002")
	calldata := []byte{0xde, 0xad, 0xbe, 0xef}
	gasLimit := uint64(500_000)

	err := SubmitReport(runtime, evmClient, workflowRouter, calldata, gasLimit)
	require.NoError(t, err, "expected successful report submission")

	require.NotNil(t, runtime.reportRequest, "expected report request")
	require.Equal(t, calldata, runtime.reportRequest.EncodedPayload, "unexpected report payload")
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

	err := SubmitReport(runtime, &evm.Client{}, common.Address{}, nil, 1)
	require.Error(t, err, "expected generate report error")
	require.ErrorContains(t, err, "generate report: generate failed")
	require.Nil(t, runtime.capabilityRequest, "expected no write when report generation fails")
}

func Test_SubmitReport_writeReportError(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityErr = errors.New("write failed")

	err := SubmitReport(runtime, &evm.Client{}, common.Address{}, nil, 1)
	require.Error(t, err, "expected write report error")
	require.ErrorContains(t, err, "write report: write failed")
}

func Test_SubmitReport_txNotSuccessWithErrorMessage(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_REVERTED, nil, "reverted")

	err := SubmitReport(runtime, &evm.Client{}, common.Address{}, nil, 1)
	require.Error(t, err, "expected reverted tx error")
	require.ErrorContains(t, err, "tx not success: status=TX_STATUS_REVERTED err=reverted")
}

func Test_SubmitReport_txNotSuccessWithoutErrorMessage(t *testing.T) {
	runtime := newMockRuntime(t)
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_FATAL, nil, "")

	err := SubmitReport(runtime, &evm.Client{}, common.Address{}, nil, 1)
	require.Error(t, err, "expected fatal tx error")
	require.ErrorContains(t, err, "tx not success: status=TX_STATUS_FATAL err=unknown error")
}

func Test_SubmitReport_contractExecutionFailed(t *testing.T) {
	runtime := newMockRuntime(t)
	contractStatus := evm.ReceiverContractExecutionStatus_RECEIVER_CONTRACT_EXECUTION_STATUS_REVERTED
	runtime.capabilityReply = writeReportReply(evm.TxStatus_TX_STATUS_SUCCESS, &contractStatus, "")

	err := SubmitReport(runtime, &evm.Client{}, common.Address{}, nil, 1)
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
