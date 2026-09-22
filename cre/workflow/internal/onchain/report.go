package onchain

import (
	"encoding/binary"
	"fmt"
	"math/big"

	"cre/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type reportWriter interface {
	WriteReport(cre.Runtime, *evm.WriteCreReportRequest) cre.Promise[*evm.WriteReportReply]
}

type Submitter func(cre.Runtime, helper.EvmConfig, int64, []byte) error

func SubmitReport(runtime cre.Runtime, target helper.EvmConfig, observedAt int64, calldata []byte) error {
	return submitReport(runtime, &evm.Client{ChainSelector: target.ChainSelector}, target, observedAt, calldata)
}

func EncodeReport(target helper.EvmConfig, observedAt int64, calldata []byte) ([]byte, error) {
	if target.ChainSelector == 0 || !common.IsHexAddress(target.WorkflowRouterAddress) || common.HexToAddress(target.WorkflowRouterAddress) == (common.Address{}) {
		return nil, fmt.Errorf("invalid report destination")
	}
	if observedAt < 0 {
		return nil, fmt.Errorf("negative observation timestamp")
	}
	if len(calldata) < 4 || len(calldata)+60 > 5*1024 {
		return nil, fmt.Errorf("invalid report calldata length")
	}
	payload := make([]byte, 60+len(calldata))
	binary.BigEndian.PutUint64(payload[:8], target.ChainSelector)
	copy(payload[8:28], common.HexToAddress(target.WorkflowRouterAddress).Bytes())
	big.NewInt(observedAt).FillBytes(payload[28:60])
	copy(payload[60:], calldata)
	return payload, nil
}

func submitReport(runtime cre.Runtime, evmClient reportWriter, target helper.EvmConfig, observedAt int64, calldata []byte) error {
	payload, err := EncodeReport(target, observedAt, calldata)
	if err != nil {
		return err
	}
	if target.GasLimit == 0 || target.GasLimit > 5_000_000 {
		return fmt.Errorf("invalid report gas limit")
	}
	now := runtime.Now().Unix()
	if observedAt > now || now-observedAt > 1800 {
		return fmt.Errorf("report observation outside 30-minute window")
	}
	// Await() blocks on a host call, not a real goroutine; the DON host enforces
	// capability/workflow timeouts. Do not wrap these in a goroutine+context.Context
	// timeout - CRE workflows are single-threaded and goroutines break DON consensus
	// determinism.
	report, err := runtime.GenerateReport(&cre.ReportRequest{
		EncodedPayload: payload,
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
		Receiver:  common.HexToAddress(target.WorkflowRouterAddress).Bytes(),
		Report:    report,
		GasConfig: &evm.GasConfig{GasLimit: target.GasLimit},
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
