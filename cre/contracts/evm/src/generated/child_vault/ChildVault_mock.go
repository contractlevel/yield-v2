// Code generated — DO NOT EDIT.

//go:build !wasip1

package child_vault

import (
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	evmmock "github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/mock"
)

var (
	_ = errors.New
	_ = fmt.Errorf
	_ = big.NewInt
	_ = common.Big1
)

// ChildVaultMock is a mock implementation of ChildVault for testing.
type ChildVaultMock struct {
	DEFAULTADMINROLE              func() ([32]byte, error)
	DefaultAdmin                  func() (common.Address, error)
	DefaultAdminDelay             func() (*big.Int, error)
	DefaultAdminDelayIncreaseWait func() (*big.Int, error)
	GetActiveProtocolAdapter      func() (common.Address, error)
	GetAdapterRegistry            func() (common.Address, error)
	GetCCVsAndFinalityConfig      func(GetCCVsAndFinalityConfigInput) (GetCCVsAndFinalityConfigOutput, error)
	GetCcipGasLimit               func(GetCcipGasLimitInput) (*big.Int, error)
	GetCrosschainVault            func(GetCrosschainVaultInput) (common.Address, error)
	GetDefaultCcipGasLimit        func() (*big.Int, error)
	GetEpochDepositRecovery       func(GetEpochDepositRecoveryInput) (TypesAmountRecovery, error)
	GetEpochWithdrawRecovery      func(GetEpochWithdrawRecoveryInput) (TypesAmountRecovery, error)
	GetLink                       func() (common.Address, error)
	GetParentChainSelector        func() (uint64, error)
	GetPausedAt                   func() (*big.Int, error)
	GetRebalanceDepositRecovery   func(GetRebalanceDepositRecoveryInput) (TypesAmountRecovery, error)
	GetRebalanceWithdrawRecovery  func(GetRebalanceWithdrawRecoveryInput) (TypesRebalanceWithdrawRecovery, error)
	GetRoleAdmin                  func(GetRoleAdminInput) ([32]byte, error)
	GetRouter                     func() (common.Address, error)
	GetTVL                        func() (*big.Int, error)
	GetThisChainSelector          func() (uint64, error)
	GetUsdc                       func() (common.Address, error)
	HasRole                       func(HasRoleInput) (bool, error)
	Owner                         func() (common.Address, error)
	Paused                        func() (bool, error)
	PendingDefaultAdmin           func() (PendingDefaultAdminOutput, error)
	PendingDefaultAdminDelay      func() (PendingDefaultAdminDelayOutput, error)
}

// NewChildVaultMock creates a new ChildVaultMock for testing.
func NewChildVaultMock(address common.Address, clientMock *evmmock.ClientCapability) *ChildVaultMock {
	mock := &ChildVaultMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["DEFAULT_ADMIN_ROLE"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DEFAULTADMINROLE == nil {
				return nil, errors.New("DEFAULT_ADMIN_ROLE method not mocked")
			}
			result, err := mock.DEFAULTADMINROLE()
			if err != nil {
				return nil, err
			}
			return abi.Methods["DEFAULT_ADMIN_ROLE"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdmin == nil {
				return nil, errors.New("defaultAdmin method not mocked")
			}
			result, err := mock.DefaultAdmin()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdmin"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdminDelay"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdminDelay == nil {
				return nil, errors.New("defaultAdminDelay method not mocked")
			}
			result, err := mock.DefaultAdminDelay()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdminDelay"].Outputs.Pack(result)
		},
		string(abi.Methods["defaultAdminDelayIncreaseWait"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.DefaultAdminDelayIncreaseWait == nil {
				return nil, errors.New("defaultAdminDelayIncreaseWait method not mocked")
			}
			result, err := mock.DefaultAdminDelayIncreaseWait()
			if err != nil {
				return nil, err
			}
			return abi.Methods["defaultAdminDelayIncreaseWait"].Outputs.Pack(result)
		},
		string(abi.Methods["getActiveProtocolAdapter"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetActiveProtocolAdapter == nil {
				return nil, errors.New("getActiveProtocolAdapter method not mocked")
			}
			result, err := mock.GetActiveProtocolAdapter()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getActiveProtocolAdapter"].Outputs.Pack(result)
		},
		string(abi.Methods["getAdapterRegistry"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAdapterRegistry == nil {
				return nil, errors.New("getAdapterRegistry method not mocked")
			}
			result, err := mock.GetAdapterRegistry()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAdapterRegistry"].Outputs.Pack(result)
		},
		string(abi.Methods["getCCVsAndFinalityConfig"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCCVsAndFinalityConfig == nil {
				return nil, errors.New("getCCVsAndFinalityConfig method not mocked")
			}
			inputs := abi.Methods["getCCVsAndFinalityConfig"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := GetCCVsAndFinalityConfigInput{
				Arg0: values[0].(uint64),
				Arg1: values[1].([]byte),
			}

			result, err := mock.GetCCVsAndFinalityConfig(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCCVsAndFinalityConfig"].Outputs.Pack(
				result.RequiredCCVs,
				result.OptionalCCVs,
				result.OptionalThreshold,
				result.AllowedFinalityConfig,
			)
		},
		string(abi.Methods["getCcipGasLimit"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCcipGasLimit == nil {
				return nil, errors.New("getCcipGasLimit method not mocked")
			}
			inputs := abi.Methods["getCcipGasLimit"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetCcipGasLimitInput{
				ChainSelector: values[0].(uint64),
			}

			result, err := mock.GetCcipGasLimit(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCcipGasLimit"].Outputs.Pack(result)
		},
		string(abi.Methods["getCrosschainVault"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCrosschainVault == nil {
				return nil, errors.New("getCrosschainVault method not mocked")
			}
			inputs := abi.Methods["getCrosschainVault"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetCrosschainVaultInput{
				ChainSelector: values[0].(uint64),
			}

			result, err := mock.GetCrosschainVault(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCrosschainVault"].Outputs.Pack(result)
		},
		string(abi.Methods["getDefaultCcipGasLimit"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetDefaultCcipGasLimit == nil {
				return nil, errors.New("getDefaultCcipGasLimit method not mocked")
			}
			result, err := mock.GetDefaultCcipGasLimit()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getDefaultCcipGasLimit"].Outputs.Pack(result)
		},
		string(abi.Methods["getEpochDepositRecovery"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetEpochDepositRecovery == nil {
				return nil, errors.New("getEpochDepositRecovery method not mocked")
			}
			inputs := abi.Methods["getEpochDepositRecovery"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetEpochDepositRecoveryInput{
				EpochNonce: values[0].(*big.Int),
			}

			result, err := mock.GetEpochDepositRecovery(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getEpochDepositRecovery"].Outputs.Pack(result)
		},
		string(abi.Methods["getEpochWithdrawRecovery"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetEpochWithdrawRecovery == nil {
				return nil, errors.New("getEpochWithdrawRecovery method not mocked")
			}
			inputs := abi.Methods["getEpochWithdrawRecovery"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetEpochWithdrawRecoveryInput{
				EpochNonce: values[0].(*big.Int),
			}

			result, err := mock.GetEpochWithdrawRecovery(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getEpochWithdrawRecovery"].Outputs.Pack(result)
		},
		string(abi.Methods["getLink"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetLink == nil {
				return nil, errors.New("getLink method not mocked")
			}
			result, err := mock.GetLink()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getLink"].Outputs.Pack(result)
		},
		string(abi.Methods["getParentChainSelector"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetParentChainSelector == nil {
				return nil, errors.New("getParentChainSelector method not mocked")
			}
			result, err := mock.GetParentChainSelector()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getParentChainSelector"].Outputs.Pack(result)
		},
		string(abi.Methods["getPausedAt"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPausedAt == nil {
				return nil, errors.New("getPausedAt method not mocked")
			}
			result, err := mock.GetPausedAt()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPausedAt"].Outputs.Pack(result)
		},
		string(abi.Methods["getRebalanceDepositRecovery"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRebalanceDepositRecovery == nil {
				return nil, errors.New("getRebalanceDepositRecovery method not mocked")
			}
			inputs := abi.Methods["getRebalanceDepositRecovery"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRebalanceDepositRecoveryInput{
				RebalanceNonce: values[0].(*big.Int),
			}

			result, err := mock.GetRebalanceDepositRecovery(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRebalanceDepositRecovery"].Outputs.Pack(result)
		},
		string(abi.Methods["getRebalanceWithdrawRecovery"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRebalanceWithdrawRecovery == nil {
				return nil, errors.New("getRebalanceWithdrawRecovery method not mocked")
			}
			inputs := abi.Methods["getRebalanceWithdrawRecovery"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRebalanceWithdrawRecoveryInput{
				RebalanceNonce: values[0].(*big.Int),
			}

			result, err := mock.GetRebalanceWithdrawRecovery(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRebalanceWithdrawRecovery"].Outputs.Pack(result)
		},
		string(abi.Methods["getRoleAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRoleAdmin == nil {
				return nil, errors.New("getRoleAdmin method not mocked")
			}
			inputs := abi.Methods["getRoleAdmin"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetRoleAdminInput{
				Role: values[0].([32]byte),
			}

			result, err := mock.GetRoleAdmin(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRoleAdmin"].Outputs.Pack(result)
		},
		string(abi.Methods["getRouter"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetRouter == nil {
				return nil, errors.New("getRouter method not mocked")
			}
			result, err := mock.GetRouter()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getRouter"].Outputs.Pack(result)
		},
		string(abi.Methods["getTVL"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetTVL == nil {
				return nil, errors.New("getTVL method not mocked")
			}
			result, err := mock.GetTVL()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getTVL"].Outputs.Pack(result)
		},
		string(abi.Methods["getThisChainSelector"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetThisChainSelector == nil {
				return nil, errors.New("getThisChainSelector method not mocked")
			}
			result, err := mock.GetThisChainSelector()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getThisChainSelector"].Outputs.Pack(result)
		},
		string(abi.Methods["getUsdc"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetUsdc == nil {
				return nil, errors.New("getUsdc method not mocked")
			}
			result, err := mock.GetUsdc()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getUsdc"].Outputs.Pack(result)
		},
		string(abi.Methods["hasRole"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.HasRole == nil {
				return nil, errors.New("hasRole method not mocked")
			}
			inputs := abi.Methods["hasRole"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := HasRoleInput{
				Role:    values[0].([32]byte),
				Account: values[1].(common.Address),
			}

			result, err := mock.HasRole(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["hasRole"].Outputs.Pack(result)
		},
		string(abi.Methods["owner"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Owner == nil {
				return nil, errors.New("owner method not mocked")
			}
			result, err := mock.Owner()
			if err != nil {
				return nil, err
			}
			return abi.Methods["owner"].Outputs.Pack(result)
		},
		string(abi.Methods["paused"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Paused == nil {
				return nil, errors.New("paused method not mocked")
			}
			result, err := mock.Paused()
			if err != nil {
				return nil, err
			}
			return abi.Methods["paused"].Outputs.Pack(result)
		},
		string(abi.Methods["pendingDefaultAdmin"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PendingDefaultAdmin == nil {
				return nil, errors.New("pendingDefaultAdmin method not mocked")
			}
			result, err := mock.PendingDefaultAdmin()
			if err != nil {
				return nil, err
			}
			return abi.Methods["pendingDefaultAdmin"].Outputs.Pack(
				result.NewAdmin,
				result.Schedule,
			)
		},
		string(abi.Methods["pendingDefaultAdminDelay"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PendingDefaultAdminDelay == nil {
				return nil, errors.New("pendingDefaultAdminDelay method not mocked")
			}
			result, err := mock.PendingDefaultAdminDelay()
			if err != nil {
				return nil, err
			}
			return abi.Methods["pendingDefaultAdminDelay"].Outputs.Pack(
				result.NewDelay,
				result.Schedule,
			)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
