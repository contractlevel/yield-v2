package epoch

import (
	"math/big"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestEpochAccountingBoundaries(t *testing.T) {
	for _, test := range []struct {
		name                           string
		deposit, burn, shares, tvl     int64
		local                          bool
		withdraw, mint, net, remaining int64
		reason                         string
	}{
		{"seed", 1_000_000, 0, 0, 0, false, 0, 1_000_000_000_000_000_000, 1_000_000, 1_000_000_000_000_000_000, ""},
		{"balanced", 1_000_000, 1_000_000, 2_000_000, 2_000_000, false, 1_000_000, 1_000_000, 0, 2_000_000, ""},
		{"remote minimum", 0, 1_000_000, 2_000_000, 2_000_000, false, 1_000_000, 0, -1_000_000, 1_000_000, ""},
		{"remote below minimum", 0, 999_999, 2_000_000, 2_000_000, false, 0, 0, 0, 0, "below minimum"},
		{"local dust", 0, 1, 2_000_000, 2_000_000, true, 1, 0, -1, 1_999_999, ""},
		{"rounding down", 1, 1, 3, 2, true, 0, 1, 1, 3, ""},
		{"empty", 0, 0, 1, 1, true, 0, 0, 0, 0, "no epoch activity"},
		{"zero TVL", 1, 0, 1, 0, true, 0, 0, 0, 0, "zero TVL"},
		{"burn without shares", 0, 1, 0, 1, true, 0, 0, 0, 0, "zero total shares"},
		{"mint rounds to zero", 1, 0, 1, 2, true, 0, 0, 0, 0, "mint zero shares"},
		{"excess burn", 0, 2, 1, 1, true, 0, 0, 0, 0, "total shares underflow"},
	} {
		t.Run(test.name, func(t *testing.T) {
			epoch := newTestEpoch()
			epoch.TotalDepositAmount = big.NewInt(test.deposit)
			epoch.TotalShareBurnAmount = big.NewInt(test.burn)
			got, err := calculateEpochClose(epoch, big.NewInt(test.shares), big.NewInt(test.tvl), 6, test.local)
			if test.reason != "" {
				require.ErrorContains(t, err, test.reason)
				return
			}
			require.NoError(t, err)
			require.Zero(t, big.NewInt(test.withdraw).Cmp(got.TotalWithdraw))
			require.Zero(t, big.NewInt(test.mint).Cmp(got.NewShares))
			require.Zero(t, big.NewInt(test.net).Cmp(got.NetFlow))
			require.Zero(t, big.NewInt(test.remaining).Cmp(got.TotalShares))
			require.Equal(t, big.NewInt(test.deposit), epoch.TotalDepositAmount)
			require.Equal(t, big.NewInt(test.burn), epoch.TotalShareBurnAmount)
		})
	}
}

func TestMulDivFullPrecision(t *testing.T) {
	max := new(big.Int).Sub(new(big.Int).Lsh(big.NewInt(1), 256), big.NewInt(1))
	got, err := mulDivDown(max, max, max)
	require.NoError(t, err)
	require.Equal(t, max, got)
	_, err = mulDivDown(max, max, big.NewInt(1))
	require.ErrorContains(t, err, "overflows")
	_, err = mulDivDown(big.NewInt(1), big.NewInt(1), new(big.Int))
	require.ErrorContains(t, err, "division by zero")
}

func FuzzMulDivDown(f *testing.F) {
	f.Add(uint64(7), uint64(5), uint64(3))
	f.Add(^uint64(0), ^uint64(0), uint64(1))
	f.Add(uint64(0), uint64(1), uint64(0))
	f.Fuzz(func(t *testing.T, x, y, denominator uint64) {
		a, b, d := new(big.Int).SetUint64(x), new(big.Int).SetUint64(y), new(big.Int).SetUint64(denominator)
		quotient, err := mulDivDown(a, b, d)
		if denominator == 0 {
			require.ErrorContains(t, err, "division by zero")
			return
		}
		require.NoError(t, err)
		product := new(big.Int).Mul(a, b)
		remainder := new(big.Int).Sub(product, new(big.Int).Mul(quotient, d))
		require.GreaterOrEqual(t, remainder.Sign(), 0)
		require.Less(t, remainder.Cmp(d), 0)
		require.Equal(t, x, a.Uint64())
		require.Equal(t, y, b.Uint64())
		require.Equal(t, denominator, d.Uint64())
	})
}

func TestEpochAccountingUint256Boundaries(t *testing.T) {
	pow := func(bits uint) *big.Int { return new(big.Int).Lsh(big.NewInt(1), bits) }
	max := new(big.Int).Sub(pow(256), big.NewInt(1))
	for _, test := range []struct {
		name                       string
		deposit, burn, shares, tvl *big.Int
		decimals                   uint8
		reason                     string
	}{
		{"nil input", nil, big.NewInt(0), big.NewInt(1), big.NewInt(1), 6, "invalid epoch accounting input"},
		{"negative input", big.NewInt(-1), big.NewInt(0), big.NewInt(1), big.NewInt(1), 6, "invalid epoch accounting input"},
		{"oversized input", pow(256), big.NewInt(0), big.NewInt(1), big.NewInt(1), 6, "invalid epoch accounting input"},
		{"excess decimals", big.NewInt(1), big.NewInt(0), big.NewInt(1), big.NewInt(1), 78, "invalid epoch accounting input"},
		{"price overflow", big.NewInt(1), big.NewInt(0), big.NewInt(1), max, 6, "mulDiv result overflows"},
		{"price rounds to zero", big.NewInt(1), big.NewInt(0), max, big.NewInt(1), 6, "zero price per share"},
		{"withdraw overflow", big.NewInt(0), max, sharePrecision, max, 6, "mulDiv result overflows"},
		{"mint overflow", max, big.NewInt(0), sharePrecision, big.NewInt(1), 6, "mulDiv result overflows"},
		{"seed overflow", max, big.NewInt(0), big.NewInt(0), big.NewInt(0), 6, "mulDiv result overflows"},
		{"signed deposit overflow", pow(255), big.NewInt(0), pow(200), pow(200), 6, "exceeds int256"},
		{"signed withdrawal overflow", big.NewInt(0), pow(255), pow(255), pow(255), 6, "exceeds int256"},
		{"minimum mint overflow", pow(240), big.NewInt(0), pow(240), pow(240), 6, "minimum deposit share calculation overflows"},
		{"total shares overflow", big.NewInt(1), big.NewInt(0), max, max, 6, "total shares overflow"},
	} {
		t.Run(test.name, func(t *testing.T) {
			epoch := newTestEpoch()
			epoch.TotalDepositAmount, epoch.TotalShareBurnAmount = test.deposit, test.burn
			_, err := calculateEpochClose(epoch, test.shares, test.tvl, test.decimals, true)
			require.ErrorContains(t, err, test.reason)
		})
	}
}

func TestDepositReconciliationBoundaries(t *testing.T) {
	for _, test := range []struct {
		name                                              string
		deposit, withdraw, mint, shares, actual, adjusted int64
		reason                                            string
	}{
		{"exact", 100, 40, 1000, 1000, 60, 1000, ""},
		{"shortfall uses gross deposit", 100, 40, 1000, 1000, 30, 700, ""},
		{"rounds down", 100, 40, 3, 3, 30, 2, ""},
		{"zero mint", 100, 0, 1, 1, 1, 0, "mint zero shares"},
		{"underflow", 100, 0, 100, 1, 1, 0, "underflows"},
		{"net zero", 100, 100, 1, 1, 1, 0, "not a net deposit"},
		{"zero delivery", 100, 0, 100, 100, 0, 0, "invalid actual"},
		{"excess delivery", 100, 0, 100, 100, 101, 0, "invalid actual"},
		{"negative input", -1, 0, 100, 100, 1, 0, "invalid deposit reconciliation input"},
	} {
		t.Run(test.name, func(t *testing.T) {
			epoch := newTestEpoch()
			epoch.TotalDepositAmount = big.NewInt(test.deposit)
			epoch.TotalWithdrawClaimAmount = big.NewInt(test.withdraw)
			epoch.RemainingShareMintAmount = big.NewInt(test.mint)
			got, err := reconcileEpochDeposit(epoch, big.NewInt(test.shares), big.NewInt(test.actual))
			if test.reason != "" {
				require.ErrorContains(t, err, test.reason)
				return
			}
			require.NoError(t, err)
			require.Equal(t, big.NewInt(test.adjusted), got)
			require.Equal(t, big.NewInt(test.mint), epoch.RemainingShareMintAmount)
		})
	}
}
