package onchain

import (
	"testing"

	"github.com/stretchr/testify/require"
)

const validVaultAddress = "0x0000000000000000000000000000000000000001"

func Test_NewBaseVaultBinding_valid(t *testing.T) {
	binding, err := NewBaseVaultBinding(nil, validVaultAddress)
	require.NoError(t, err)
	require.NotNil(t, binding)
	require.Implements(t, (*BaseVaultInterface)(nil), binding)
}

func Test_NewBaseVaultBinding_invalidAddress(t *testing.T) {
	binding, err := NewBaseVaultBinding(nil, "not-an-address")
	require.ErrorContains(t, err, "invalid BaseVault address: not-an-address")
	require.Nil(t, binding)
}

func Test_NewParentVaultBinding_valid(t *testing.T) {
	binding, err := NewParentVaultBinding(nil, validVaultAddress)
	require.NoError(t, err, "expected valid parent vault address to construct binding")
	require.NotNil(t, binding, "expected non-nil parent vault binding")
	require.Implements(t, (*ParentVaultInterface)(nil), binding, "expected binding to implement ParentVaultInterface")
}

func Test_NewParentVaultBinding_invalidAddress(t *testing.T) {
	binding, err := NewParentVaultBinding(nil, "not-an-address")
	require.Error(t, err, "expected invalid parent vault address to fail")
	require.Nil(t, binding, "expected nil parent vault binding on error")
	require.ErrorContains(t, err, "invalid ParentVault address: not-an-address")
}

func Test_NewChildVaultBinding_valid(t *testing.T) {
	binding, err := NewChildVaultBinding(nil, validVaultAddress)
	require.NoError(t, err, "expected valid child vault address to construct binding")
	require.NotNil(t, binding, "expected non-nil child vault binding")
	require.Implements(t, (*ChildVaultInterface)(nil), binding, "expected binding to implement ChildVaultInterface")
}

func Test_NewChildVaultBinding_invalidAddress(t *testing.T) {
	binding, err := NewChildVaultBinding(nil, "not-an-address")
	require.Error(t, err, "expected invalid child vault address to fail")
	require.Nil(t, binding, "expected nil child vault binding on error")
	require.ErrorContains(t, err, "invalid ChildVault address: not-an-address")
}
