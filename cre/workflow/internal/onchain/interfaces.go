package onchain

import (
	"math/big"

	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// ParentVaultInterface defines the onchain reads used by parent-chain handlers.
type ParentVaultInterface interface {
	BaseVaultInterface
	GetRebalance(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[parent_vault.TypesRebalance]
	GetEpochNonce(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
	GetEpoch(runtime cre.Runtime, args parent_vault.GetEpochInput, blockNumber *big.Int) cre.Promise[parent_vault.TypesEpoch]
}

// ChildVaultInterface defines the subset used to interact with child-chain vaults.
type ChildVaultInterface interface {
	BaseVaultInterface
}

// BaseVaultInterface defines the common vault reads used by workflow handlers.
type BaseVaultInterface interface {
	GetTVL(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
	GetRecoveryMode(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[uint8]
}
