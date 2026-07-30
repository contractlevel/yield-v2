package onchain

import (
	"errors"
	"fmt"
	"math/big"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/stretchr/testify/require"

	"cre/workflow/internal/helper"
)

func recoveryConfigs(count int) []helper.EvmConfig {
	configs := make([]helper.EvmConfig, count)
	for i := range configs {
		configs[i] = helper.EvmConfig{
			ChainName:     fmt.Sprintf("chain-%c", 'a'+i),
			ChainSelector: uint64(i + 1),
			VaultAddress:  validVaultAddress,
		}
	}
	return configs
}

func Test_FindActiveRecovery_none(t *testing.T) {
	configs := recoveryConfigs(5)
	blockNumber := big.NewInt(-2)
	var selectors []uint64

	got, err := findActiveRecovery(nil, configs, blockNumber, func(client *evm.Client, _ string) (BaseVaultInterface, error) {
		selectors = append(selectors, client.ChainSelector)
		return &fakeReadVault{}, nil
	})

	require.NoError(t, err)
	require.Nil(t, got)
	require.Equal(t, []uint64{1, 2, 3, 4, 5}, selectors)
}

func Test_FindActiveRecovery_nonNoneModes(t *testing.T) {
	for mode := uint8(1); mode <= 5; mode++ {
		mode := mode
		t.Run(fmt.Sprintf("mode_%d", mode), func(t *testing.T) {
			configs := recoveryConfigs(5)
			calls := 0
			blockNumber := big.NewInt(-2)

			got, err := findActiveRecovery(nil, configs, blockNumber, func(*evm.Client, string) (BaseVaultInterface, error) {
				calls++
				if calls == 3 {
					return &fakeReadVault{recoveryMode: mode}, nil
				}
				return &fakeReadVault{}, nil
			})

			require.NoError(t, err)
			require.Equal(t, &ActiveRecovery{ChainName: "chain-c", Mode: mode}, got)
			require.Equal(t, 3, calls, "expected scan to stop at the active vault")
		})
	}
}

func Test_FindActiveRecovery_bindingError(t *testing.T) {
	got, err := findActiveRecovery(nil, recoveryConfigs(1), big.NewInt(-2), func(*evm.Client, string) (BaseVaultInterface, error) {
		return nil, errors.New("bind failed")
	})

	require.Nil(t, got)
	require.ErrorContains(t, err, "bind vault on chain-a: bind failed")
}

func Test_FindActiveRecovery_readError(t *testing.T) {
	got, err := findActiveRecovery(nil, recoveryConfigs(1), big.NewInt(-2), func(*evm.Client, string) (BaseVaultInterface, error) {
		return &fakeReadVault{recoveryErr: errors.New("read failed")}, nil
	})

	require.Nil(t, got)
	require.ErrorContains(t, err, "get recovery mode on chain-a: read failed")
}

func Test_FindActiveRecovery_public(t *testing.T) {
	got, err := FindActiveRecovery(nil, nil, big.NewInt(-2))
	require.NoError(t, err)
	require.Nil(t, got)
}
