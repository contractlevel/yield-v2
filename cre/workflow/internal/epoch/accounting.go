package epoch

import (
	"fmt"
	"math/big"

	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/onchain"
)

var sharePrecision = new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)

type epochAccounting struct {
	TotalWithdraw *big.Int
	NewShares     *big.Int
	NetFlow       *big.Int
	TotalShares   *big.Int
}

// calculateEpochClose mirrors ParentVaultEpochLib._closeEpoch. Inputs are never
// mutated. Multiplication inside mulDivDown is full precision, whereas ordinary
// Solidity arithmetic must remain within uint256 before the next operation.
func calculateEpochClose(epoch parent_vault.TypesEpoch, totalShares, tvl *big.Int, assetDecimals uint8, isLocal bool) (*epochAccounting, error) {
	deposit := epoch.TotalDepositAmount
	burn := epoch.TotalShareBurnAmount
	if !onchain.Uint256(deposit) || !onchain.Uint256(burn) || !onchain.Uint256(totalShares) || !onchain.Uint256(tvl) || assetDecimals > 77 {
		return nil, fmt.Errorf("invalid epoch accounting input")
	}
	if deposit.Sign() == 0 && burn.Sign() == 0 {
		return nil, fmt.Errorf("no epoch activity")
	}
	assetPrecision := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(assetDecimals)), nil)
	accounting := &epochAccounting{TotalWithdraw: new(big.Int)}
	var err error
	if totalShares.Sign() != 0 {
		if tvl.Sign() == 0 {
			return nil, fmt.Errorf("zero TVL with outstanding shares")
		}
		var price *big.Int
		price, err = mulDivDown(tvl, sharePrecision, totalShares)
		if err != nil {
			return nil, err
		}
		if price.Sign() == 0 {
			return nil, fmt.Errorf("zero price per share")
		}
		accounting.TotalWithdraw, err = mulDivDown(burn, tvl, totalShares)
		if err != nil {
			return nil, err
		}
		accounting.NewShares, err = mulDivDown(deposit, totalShares, tvl)
	} else {
		if burn.Sign() != 0 {
			return nil, fmt.Errorf("share burn with zero total shares")
		}
		accounting.NewShares, err = mulDivDown(deposit, sharePrecision, assetPrecision)
	}
	if err != nil {
		return nil, err
	}

	// Solidity casts each operand to int256 before subtracting.
	if deposit.BitLen() > 255 || accounting.TotalWithdraw.BitLen() > 255 {
		return nil, fmt.Errorf("epoch net flow exceeds int256")
	}
	accounting.NetFlow = new(big.Int).Sub(deposit, accounting.TotalWithdraw)
	if deposit.Sign() != 0 {
		minimumDepositShares := new(big.Int).Mul(accounting.NewShares, assetPrecision)
		if !onchain.Uint256(minimumDepositShares) {
			return nil, fmt.Errorf("minimum deposit share calculation overflows")
		}
		if minimumDepositShares.Cmp(deposit) < 0 {
			return nil, fmt.Errorf("deposit would mint zero shares")
		}
	}
	if !isLocal && accounting.NetFlow.Sign() < 0 {
		withdraw := new(big.Int).Neg(accounting.NetFlow)
		if withdraw.Cmp(assetPrecision) < 0 {
			return nil, fmt.Errorf("remote withdrawal below minimum asset amount")
		}
	}
	accounting.TotalShares = new(big.Int).Add(totalShares, accounting.NewShares)
	if !onchain.Uint256(accounting.TotalShares) {
		return nil, fmt.Errorf("total shares overflow")
	}
	accounting.TotalShares.Sub(accounting.TotalShares, burn)
	if accounting.TotalShares.Sign() < 0 {
		return nil, fmt.Errorf("total shares underflow")
	}
	return accounting, nil
}

// reconcileEpochDeposit mirrors the short-delivery adjustment using total
// deposits, not merely the net amount sent to the remote strategy.
func reconcileEpochDeposit(epoch parent_vault.TypesEpoch, totalShares, actualAmount *big.Int) (*big.Int, error) {
	for _, value := range []*big.Int{epoch.TotalDepositAmount, epoch.TotalWithdrawClaimAmount, epoch.RemainingShareMintAmount, totalShares, actualAmount} {
		if !onchain.Uint256(value) {
			return nil, fmt.Errorf("invalid deposit reconciliation input")
		}
	}
	expected := new(big.Int).Sub(epoch.TotalDepositAmount, epoch.TotalWithdrawClaimAmount)
	if expected.Sign() <= 0 {
		return nil, fmt.Errorf("epoch is not a net deposit")
	}
	if actualAmount.Sign() == 0 || actualAmount.Cmp(expected) > 0 {
		return nil, fmt.Errorf("invalid actual deposit amount")
	}
	if actualAmount.Cmp(expected) == 0 {
		return new(big.Int).Set(epoch.RemainingShareMintAmount), nil
	}
	shortfall := new(big.Int).Sub(expected, actualAmount)
	effectiveDeposit := new(big.Int).Sub(epoch.TotalDepositAmount, shortfall)
	// 0 < effectiveDeposit < total deposits, so the quotient cannot exceed
	// the validated uint256 mint amount. Keep the product at full precision.
	adjusted := new(big.Int).Mul(epoch.RemainingShareMintAmount, effectiveDeposit)
	adjusted.Quo(adjusted, epoch.TotalDepositAmount)
	if adjusted.Sign() == 0 {
		return nil, fmt.Errorf("deposit would mint zero shares")
	}
	reduction := new(big.Int).Sub(epoch.RemainingShareMintAmount, adjusted)
	if reduction.Cmp(totalShares) > 0 {
		return nil, fmt.Errorf("deposit reconciliation underflows total shares")
	}
	return adjusted, nil
}

func mulDivDown(x, y, denominator *big.Int) (*big.Int, error) {
	if denominator.Sign() == 0 {
		return nil, fmt.Errorf("division by zero")
	}
	result := new(big.Int).Mul(x, y)
	result.Quo(result, denominator)
	if !onchain.Uint256(result) {
		return nil, fmt.Errorf("mulDiv result overflows uint256")
	}
	return result, nil
}
