// internal/onchain/report.go
package onchain

import (
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

func SubmitReport(
	runtime cre.Runtime,
	evmClient *evm.Client,
	workflowRouter common.Address,
	calldata []byte,
	gasLimit uint64,
) error {
	report, err := runtime.GenerateReport(&cre.ReportRequest{
		EncodedPayload: calldata,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	}).Await()
	if err != nil {
		return fmt.Errorf("generate report: %w", err)
	}

	resp, err := evmClient.WriteReport(runtime, &evm.WriteCreReportRequest{
		Receiver:  workflowRouter.Bytes(),
		Report:    report,
		GasConfig: &evm.GasConfig{GasLimit: gasLimit},
	}).Await()
	if err != nil {
		return fmt.Errorf("write report: %w", err)
	}

	if resp.TxStatus != evm.TxStatus_TX_STATUS_SUCCESS {
		msg := "unknown error"
		if resp.ErrorMessage != nil {
			msg = *resp.ErrorMessage
		}
		return fmt.Errorf("tx not success: status=%s err=%s", resp.TxStatus, msg)
	}

	// Optional but recommended: check contract-level execution
	if resp.ReceiverContractExecutionStatus != nil &&
		*resp.ReceiverContractExecutionStatus != evm.ReceiverContractExecutionStatus_RECEIVER_CONTRACT_EXECUTION_STATUS_SUCCESS {
		return fmt.Errorf("contract execution failed: status=%s", *resp.ReceiverContractExecutionStatus)
	}

	runtime.Logger().Info("CRE write succeeded",
		"txHash", fmt.Sprintf("0x%x", resp.TxHash),
		"fee", resp.TransactionFee,
	)
	return nil
}
