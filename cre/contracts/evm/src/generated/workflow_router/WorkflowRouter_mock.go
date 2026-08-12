// Code generated — DO NOT EDIT.

//go:build !wasip1

package workflow_router

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

// WorkflowRouterMock is a mock implementation of WorkflowRouter for testing.
type WorkflowRouterMock struct {
	DEFAULTADMINROLE               func() ([32]byte, error)
	DefaultAdmin                   func() (common.Address, error)
	DefaultAdminDelay              func() (*big.Int, error)
	DefaultAdminDelayIncreaseWait  func() (*big.Int, error)
	GetAllowlistedWorkflowSelector func(GetAllowlistedWorkflowSelectorInput) (bool, error)
	GetRoleAdmin                   func(GetRoleAdminInput) ([32]byte, error)
	GetVault                       func() (common.Address, error)
	GetWorkflowGeneration          func(GetWorkflowGenerationInput) (*big.Int, error)
	GetWorkflowMetadata            func(GetWorkflowMetadataInput) (IWorkflowRouterWorkflowMetadata, error)
	HasRole                        func(HasRoleInput) (bool, error)
	Owner                          func() (common.Address, error)
	Paused                         func() (bool, error)
	PendingDefaultAdmin            func() (PendingDefaultAdminOutput, error)
	PendingDefaultAdminDelay       func() (PendingDefaultAdminDelayOutput, error)
	SupportsInterface              func(SupportsInterfaceInput) (bool, error)
}

// NewWorkflowRouterMock creates a new WorkflowRouterMock for testing.
func NewWorkflowRouterMock(address common.Address, clientMock *evmmock.ClientCapability) *WorkflowRouterMock {
	mock := &WorkflowRouterMock{}

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
		string(abi.Methods["getAllowlistedWorkflowSelector"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAllowlistedWorkflowSelector == nil {
				return nil, errors.New("getAllowlistedWorkflowSelector method not mocked")
			}
			inputs := abi.Methods["getAllowlistedWorkflowSelector"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 2 {
				return nil, errors.New("expected 2 input values")
			}

			args := GetAllowlistedWorkflowSelectorInput{
				WorkflowId: values[0].([32]byte),
				Selector:   values[1].([4]byte),
			}

			result, err := mock.GetAllowlistedWorkflowSelector(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAllowlistedWorkflowSelector"].Outputs.Pack(result)
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
		string(abi.Methods["getVault"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetVault == nil {
				return nil, errors.New("getVault method not mocked")
			}
			result, err := mock.GetVault()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getVault"].Outputs.Pack(result)
		},
		string(abi.Methods["getWorkflowGeneration"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetWorkflowGeneration == nil {
				return nil, errors.New("getWorkflowGeneration method not mocked")
			}
			inputs := abi.Methods["getWorkflowGeneration"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetWorkflowGenerationInput{
				WorkflowId: values[0].([32]byte),
			}

			result, err := mock.GetWorkflowGeneration(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getWorkflowGeneration"].Outputs.Pack(result)
		},
		string(abi.Methods["getWorkflowMetadata"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetWorkflowMetadata == nil {
				return nil, errors.New("getWorkflowMetadata method not mocked")
			}
			inputs := abi.Methods["getWorkflowMetadata"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetWorkflowMetadataInput{
				WorkflowId: values[0].([32]byte),
			}

			result, err := mock.GetWorkflowMetadata(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getWorkflowMetadata"].Outputs.Pack(result)
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
		string(abi.Methods["supportsInterface"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.SupportsInterface == nil {
				return nil, errors.New("supportsInterface method not mocked")
			}
			inputs := abi.Methods["supportsInterface"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := SupportsInterfaceInput{
				InterfaceId: values[0].([4]byte),
			}

			result, err := mock.SupportsInterface(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["supportsInterface"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
