package epoch

import (
	"math/big"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/stretchr/testify/require"

	"cre/contracts/evm/src/generated/parent_vault"
	"cre/workflow/internal/onchain"
)

func Fuzz_OnEpochCronTrigger_guardOutcomes(f *testing.F) {
	f.Add(uint8(0), int64(0), int64(1), int64(0))
	f.Add(uint8(1), int64(0), int64(0), int64(0))
	f.Add(uint8(1), int64(1), int64(0), int64(9_999))

	f.Fuzz(func(t *testing.T, status uint8, depositAmount, burnAmount, openedAt int64) {
		resetSeams(t)
		installParentCodec(t, &fakeParentCodec{closeCalldata: []byte{1}})
		installBindings(t)

		deps := baseInitiatorDeps()
		deps.GetEpoch = func(cre.Runtime, onchain.ParentVaultInterface, *big.Int, *big.Int) (parent_vault.TypesEpoch, error) {
			return parent_vault.TypesEpoch{
				Status:               status,
				TotalDepositAmount:   big.NewInt(depositAmount),
				TotalShareBurnAmount: big.NewInt(burnAmount),
				OpenedAtTimestamp:    big.NewInt(openedAt),
			}, nil
		}
		deps.SubmitReport = baseInitiatorDeps().SubmitReport

		result, err := onEpochCronTriggerWithDeps(testConfig(), testRuntime(t), nil, deps)
		require.NoError(t, err, "guard-only fuzz cases should not error")
		require.NotNil(t, result, "expected result")
	})
}
