package onchain

import (
	"fmt"
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre/workflow/internal/helper"
)

const recoveryModeNone uint8 = 0

// ActiveRecovery identifies a vault with a non-NONE recovery mode.
type ActiveRecovery struct {
	ChainName string
	Mode      uint8
}

type baseVaultFactory func(*evm.Client, string) (BaseVaultInterface, error)

// FindActiveRecovery returns the first configured vault with an active
// recovery mode. A nil result means every vault is operating normally.
func FindActiveRecovery(runtime cre.Runtime, evms []helper.EvmConfig, blockNumber *big.Int) (*ActiveRecovery, error) {
	return findActiveRecovery(runtime, evms, blockNumber, NewBaseVaultBinding)
}

func findActiveRecovery(
	runtime cre.Runtime,
	evms []helper.EvmConfig,
	blockNumber *big.Int,
	newVaultBinding baseVaultFactory,
) (*ActiveRecovery, error) {
	for _, evmCfg := range evms {
		vault, err := newVaultBinding(
			&evm.Client{ChainSelector: evmCfg.ChainSelector},
			evmCfg.VaultAddress,
		)
		if err != nil {
			return nil, fmt.Errorf("bind vault on %s: %w", evmCfg.ChainName, err)
		}

		mode, err := GetRecoveryMode(runtime, vault, blockNumber)
		if err != nil {
			return nil, fmt.Errorf("get recovery mode on %s: %w", evmCfg.ChainName, err)
		}
		if mode != recoveryModeNone {
			return &ActiveRecovery{ChainName: evmCfg.ChainName, Mode: mode}, nil
		}
	}

	return nil, nil
}
