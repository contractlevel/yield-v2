package onchain

import (
	"math/big"

	"cre/contracts/evm/src/generated/child_vault"
	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// ParentVaultInterface defines the onchain reads used by parent-chain handlers.
type ParentVaultInterface interface {
	GetParentOperationalState(cre.Runtime, *big.Int) cre.Promise[parent_vault.TypesParentOperationalState]
}

// ChildVaultInterface defines the subset used to interact with child-chain vaults.
type ChildVaultInterface interface {
	GetChildOperationalState(cre.Runtime, *big.Int) cre.Promise[child_vault.TypesChildOperationalState]
}
