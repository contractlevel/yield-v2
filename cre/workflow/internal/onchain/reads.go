package onchain

import (
	"math/big"

	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

func GetRebalance(runtime cre.Runtime, vault ParentVaultInterface, blockNumber *big.Int) (parent_vault.TypesRebalance, error) {
	return vault.GetRebalance(runtime, blockNumber).Await()
}

func GetEpochNonce(runtime cre.Runtime, vault ParentVaultInterface, blockNumber *big.Int) (*big.Int, error) {
	return vault.GetEpochNonce(runtime, blockNumber).Await()
}

func GetEpoch(runtime cre.Runtime, vault ParentVaultInterface, epochNonce *big.Int, blockNumber *big.Int) (parent_vault.TypesEpoch, error) {
	return vault.GetEpoch(runtime, parent_vault.GetEpochInput{EpochNonce: epochNonce}, blockNumber).Await()
}

func ReadTVL(runtime cre.Runtime, vault BaseVaultInterface, blockNumber *big.Int) (*big.Int, error) {
	return vault.GetTVL(runtime, blockNumber).Await()
}
