package onchain

import (
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/stretchr/testify/require"
)

func Fuzz_ReadWrappers_passThroughInputs(f *testing.F) {
	f.Add(int64(-2), int64(1))
	f.Add(int64(0), int64(0))
	f.Add(int64(100), int64(50))

	f.Fuzz(func(t *testing.T, blockNumberValue, epochNonceValue int64) {
		blockNumber := big.NewInt(blockNumberValue)
		epochNonce := big.NewInt(epochNonceValue)
		vault := &fakeReadVault{
			rebalanceResult:  parent_vault.TypesRebalance{State: 1},
			epochNonceResult: epochNonce,
			epochResult:      parent_vault.TypesEpoch{Status: 1},
			tvlResult:        big.NewInt(100),
		}

		_, err := GetRebalance(nil, vault, blockNumber)
		require.NoError(t, err, "expected rebalance read to succeed")
		require.Same(t, blockNumber, vault.rebalanceBlock, "expected rebalance block number to pass through")

		gotEpochNonce, err := GetEpochNonce(nil, vault, blockNumber)
		require.NoError(t, err, "expected epoch nonce read to succeed")
		require.Same(t, epochNonce, gotEpochNonce, "expected epoch nonce result to pass through")
		require.Same(t, blockNumber, vault.epochNonceBlock, "expected epoch nonce block number to pass through")

		_, err = GetEpoch(nil, vault, epochNonce, blockNumber)
		require.NoError(t, err, "expected epoch read to succeed")
		require.Same(t, epochNonce, vault.epochNonce, "expected epoch nonce input to pass through")
		require.Same(t, blockNumber, vault.epochBlock, "expected epoch block number to pass through")

		_, err = ReadTVL(nil, vault, blockNumber)
		require.NoError(t, err, "expected TVL read to succeed")
		require.Same(t, blockNumber, vault.tvlBlock, "expected TVL block number to pass through")
	})
}
