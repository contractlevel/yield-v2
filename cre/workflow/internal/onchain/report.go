// internal/onchain/report.go
package onchain

import (
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type reportWriter interface {
	WriteReport(cre.Runtime, *evm.WriteCreReportRequest) cre.Promise[*evm.WriteReportReply]
}

func SubmitReport(
	runtime cre.Runtime,
	evmClient *evm.Client,
	workflowRouter common.Address,
	calldata []byte,
	gasLimit uint64,
) error {
	return submitReport(runtime, evmClient, workflowRouter, calldata, gasLimit)
}

func submitReport(
	runtime cre.Runtime,
	evmClient reportWriter,
	workflowRouter common.Address,
	calldata []byte,
	gasLimit uint64,
) error {
	// Await() blocks on a host call, not a real goroutine; the DON host enforces
	// capability/workflow timeouts. Do not wrap these in a goroutine+context.Context
	// timeout - CRE workflows are single-threaded and goroutines break DON consensus
	// determinism.
	report, err := runtime.GenerateReport(&cre.ReportRequest{
		EncodedPayload: calldata,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	}).Await()
	if err != nil {
		return fmt.Errorf("generate report: %w", err)
	}
	if report == nil {
		return fmt.Errorf("generate report: nil report")
	}

	resp, err := evmClient.WriteReport(runtime, &evm.WriteCreReportRequest{
		Receiver:  workflowRouter.Bytes(),
		Report:    report,
		GasConfig: &evm.GasConfig{GasLimit: gasLimit},
	}).Await()
	if err != nil {
		return fmt.Errorf("write report: %w", err)
	}
	if resp == nil {
		return fmt.Errorf("write report: nil response")
	}

	if resp.TxStatus != evm.TxStatus_TX_STATUS_SUCCESS {
		msg := "unknown error"
		if resp.ErrorMessage != nil {
			msg = *resp.ErrorMessage
		}
		return fmt.Errorf("tx not success: status=%s err=%s", resp.TxStatus, msg)
	}

	if resp.ReceiverContractExecutionStatus == nil {
		return fmt.Errorf("contract execution status missing")
	}
	if *resp.ReceiverContractExecutionStatus != evm.ReceiverContractExecutionStatus_RECEIVER_CONTRACT_EXECUTION_STATUS_SUCCESS {
		return fmt.Errorf("contract execution failed: status=%s", *resp.ReceiverContractExecutionStatus)
	}

	runtime.Logger().Info("CRE write succeeded",
		"txHash", fmt.Sprintf("0x%x", resp.TxHash),
		"fee", resp.TransactionFee,
	)
	return nil
}
