package onchain

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
)

func Fuzz_NewParentVaultBinding_addressValidation(f *testing.F) {
	f.Add(validVaultAddress)
	f.Add("not-an-address")
	f.Add("")
	f.Add("0x0000000000000000000000000000000000000000")

	f.Fuzz(func(t *testing.T, addr string) {
		binding, err := NewParentVaultBinding(nil, addr)

		if common.IsHexAddress(addr) {
			require.NoError(t, err, "expected valid parent vault address to pass")
			require.NotNil(t, binding, "expected non-nil parent vault binding")
		} else {
			require.Error(t, err, "expected invalid parent vault address to fail")
			require.Nil(t, binding, "expected nil parent vault binding")
		}
	})
}

func Fuzz_NewChildVaultBinding_addressValidation(f *testing.F) {
	f.Add(validVaultAddress)
	f.Add("not-an-address")
	f.Add("")
	f.Add("0x0000000000000000000000000000000000000000")

	f.Fuzz(func(t *testing.T, addr string) {
		binding, err := NewChildVaultBinding(nil, addr)

		if common.IsHexAddress(addr) {
			require.NoError(t, err, "expected valid child vault address to pass")
			require.NotNil(t, binding, "expected non-nil child vault binding")
		} else {
			require.Error(t, err, "expected invalid child vault address to fail")
			require.Nil(t, binding, "expected nil child vault binding")
		}
	})
}
