package onchain

import (
	"fmt"

	"cre/contracts/evm/src/generated/base_vault"
	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// NewBaseVaultBinding constructs a binding for reads common to every vault.
func NewBaseVaultBinding(client *evm.Client, addr string) (BaseVaultInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid BaseVault address: %s", addr)
	}

	return base_vault.NewBaseVault(client, common.HexToAddress(addr), nil)
}

// NewParentVaultBinding constructs the parent vault binding.
// It satisfies ParentVaultInterface (and thus BaseVaultInterface via embedding).
func NewParentVaultBinding(client *evm.Client, addr string) (ParentVaultInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ParentVault address: %s", addr)
	}
	parentVaultAddr := common.HexToAddress(addr)

	return parent_vault.NewParentVault(client, parentVaultAddr, nil)
}

// NewChildVaultBinding constructs the child peer binding.
// It satisfies ChildVaultInterface (and thus BaseVaultInterface via embedding).
func NewChildVaultBinding(client *evm.Client, addr string) (ChildVaultInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ChildVault address: %s", addr)
	}
	childVaultAddr := common.HexToAddress(addr)

	return child_vault.NewChildVault(client, childVaultAddr, nil)
}
