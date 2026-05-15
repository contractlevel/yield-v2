package onchain

import (
	"errors"
	"math/big"
	"testing"

	"cre/contracts/evm/src/generated/parent_vault"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/stretchr/testify/require"
)

type fakeReadVault struct {
	rebalanceResult parent_vault.TypesRebalance
	rebalanceErr    error
	rebalanceBlock  *big.Int

	epochNonceResult *big.Int
	epochNonceErr    error
	epochNonceBlock  *big.Int

	epochResult parent_vault.TypesEpoch
	epochErr    error
	epochNonce  *big.Int
	epochBlock  *big.Int

	tvlResult *big.Int
	tvlErr    error
	tvlBlock  *big.Int
}

func (f *fakeReadVault) GetRebalance(_ cre.Runtime, blockNumber *big.Int) cre.Promise[parent_vault.TypesRebalance] {
	f.rebalanceBlock = blockNumber
	return cre.PromiseFromResult(f.rebalanceResult, f.rebalanceErr)
}

func (f *fakeReadVault) GetEpochNonce(_ cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
	f.epochNonceBlock = blockNumber
	return cre.PromiseFromResult(f.epochNonceResult, f.epochNonceErr)
}

func (f *fakeReadVault) GetEpoch(_ cre.Runtime, args parent_vault.GetEpochInput, blockNumber *big.Int) cre.Promise[parent_vault.TypesEpoch] {
	f.epochNonce = args.EpochNonce
	f.epochBlock = blockNumber
	return cre.PromiseFromResult(f.epochResult, f.epochErr)
}

func (f *fakeReadVault) GetTVL(_ cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
	f.tvlBlock = blockNumber
	return cre.PromiseFromResult(f.tvlResult, f.tvlErr)
}

func Test_GetRebalance(t *testing.T) {
	want := parent_vault.TypesRebalance{State: 1}
	blockNumber := big.NewInt(-2)
	vault := &fakeReadVault{rebalanceResult: want}

	got, err := GetRebalance(nil, vault, blockNumber)
	require.NoError(t, err, "expected rebalance read to succeed")
	require.Equal(t, want, got, "unexpected rebalance")
	require.Same(t, blockNumber, vault.rebalanceBlock, "expected block number to pass through")
}

func Test_GetRebalance_error(t *testing.T) {
	vault := &fakeReadVault{rebalanceErr: errors.New("read failed")}

	got, err := GetRebalance(nil, vault, big.NewInt(1))
	require.Error(t, err, "expected rebalance read error")
	require.Equal(t, parent_vault.TypesRebalance{}, got, "expected zero rebalance on error")
	require.ErrorContains(t, err, "read failed")
}

func Test_GetEpochNonce(t *testing.T) {
	want := big.NewInt(7)
	blockNumber := big.NewInt(-2)
	vault := &fakeReadVault{epochNonceResult: want}

	got, err := GetEpochNonce(nil, vault, blockNumber)
	require.NoError(t, err, "expected epoch nonce read to succeed")
	require.Same(t, want, got, "unexpected epoch nonce")
	require.Same(t, blockNumber, vault.epochNonceBlock, "expected block number to pass through")
}

func Test_GetEpochNonce_error(t *testing.T) {
	vault := &fakeReadVault{epochNonceErr: errors.New("nonce failed")}

	got, err := GetEpochNonce(nil, vault, big.NewInt(1))
	require.Error(t, err, "expected epoch nonce read error")
	require.Nil(t, got, "expected nil nonce on error")
	require.ErrorContains(t, err, "nonce failed")
}

func Test_GetEpoch(t *testing.T) {
	want := parent_vault.TypesEpoch{Status: 1}
	epochNonce := big.NewInt(3)
	blockNumber := big.NewInt(-2)
	vault := &fakeReadVault{epochResult: want}

	got, err := GetEpoch(nil, vault, epochNonce, blockNumber)
	require.NoError(t, err, "expected epoch read to succeed")
	require.Equal(t, want, got, "unexpected epoch")
	require.Same(t, epochNonce, vault.epochNonce, "expected epoch nonce to pass through")
	require.Same(t, blockNumber, vault.epochBlock, "expected block number to pass through")
}

func Test_GetEpoch_error(t *testing.T) {
	vault := &fakeReadVault{epochErr: errors.New("epoch failed")}

	got, err := GetEpoch(nil, vault, big.NewInt(1), big.NewInt(2))
	require.Error(t, err, "expected epoch read error")
	require.Equal(t, parent_vault.TypesEpoch{}, got, "expected zero epoch on error")
	require.ErrorContains(t, err, "epoch failed")
}

func Test_ReadTVL(t *testing.T) {
	want := big.NewInt(100)
	blockNumber := big.NewInt(-2)
	vault := &fakeReadVault{tvlResult: want}

	got, err := ReadTVL(nil, vault, blockNumber)
	require.NoError(t, err, "expected TVL read to succeed")
	require.Same(t, want, got, "unexpected TVL")
	require.Same(t, blockNumber, vault.tvlBlock, "expected block number to pass through")
}

func Test_ReadTVL_error(t *testing.T) {
	vault := &fakeReadVault{tvlErr: errors.New("tvl failed")}

	got, err := ReadTVL(nil, vault, big.NewInt(1))
	require.Error(t, err, "expected TVL read error")
	require.Nil(t, got, "expected nil TVL on error")
	require.ErrorContains(t, err, "tvl failed")
}
