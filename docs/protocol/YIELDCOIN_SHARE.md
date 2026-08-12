# YieldcoinShare

[`YieldcoinShare`](../../evm/src/token/YieldcoinShare.sol) is the upgradeable ERC20 share token for
Yieldcoin v2.

| Property | Value |
| --- | --- |
| Name | Yieldcoin |
| Symbol | YIELD |
| Decimals | 18 |
| Proxy pattern | ERC-1967 with UUPS upgrades |
| Access control | OpenZeppelin `AccessControlDefaultAdminRulesUpgradeable` |

## Share Lifecycle

ParentVault is granted `MINTER_ROLE` and `BURNER_ROLE` during deployment. No other protocol
component needs supply-changing authority.

1. A deposit records underlying assets for the current epoch; it does not mint shares immediately.
2. After the epoch becomes claimable, `claimShares` mints the user's settled share allocation.
3. A withdrawal intent transfers the user's shares into ParentVault escrow.
4. `cancelWithdraw` returns escrowed shares while the epoch remains open.
5. After settlement, `claimAsset` burns the escrowed shares held by ParentVault and transfers the
   user's underlying-asset allocation.

ParentVault maintains its own epoch-level total-share accounting. This can temporarily differ from
the token's `totalSupply()` between epoch close and the final claim because the accounting delta is
recorded before the corresponding token mint or burn occurs.

## ERC20 and Pause Behavior

YieldcoinShare follows standard ERC20 balance and allowance behavior.

When paused:

- `transfer` and `transferFrom` revert;
- `mint` and `burn` revert; and
- approvals remain available because they do not change balances or total supply.

Token pause therefore also blocks ParentVault operations that transfer, mint, or burn shares. This
includes creating or cancelling a withdrawal intent and claiming settled shares or assets. Vault and
token pause state should be coordinated during incident response.

`PAUSER_ROLE` and `UNPAUSER_ROLE` are separate so emergency pause authority does not automatically
include restart authority.

## Roles

| Role | Authority |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Grant and revoke token roles; manage the two-step default-admin transfer |
| `MINTER_ROLE` | Mint shares; granted to ParentVault |
| `BURNER_ROLE` | Burn shares held in ParentVault escrow; granted to ParentVault |
| `PAUSER_ROLE` | Pause transfers, minting, and burning |
| `UNPAUSER_ROLE` | Unpause the token |
| `CONFIG_OPERATOR_ROLE` | Update the stored CCIP token administrator |
| `UPGRADER_ROLE` | Authorize UUPS implementation upgrades |

See [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#yieldcoinshare) for launch role
holders and protocol-wide authority.

## CCIP Admin

`getCCIPAdmin()` returns the stored Chainlink CCIP token administrator identity.
`setCCIPAdmin(newAdmin)` requires `CONFIG_OPERATOR_ROLE`, rejects the zero address, and emits
`CCIPAdminTransferred`.

The CCIP admin value does not grant token roles or UUPS upgrade authority.

## Upgrade Safety

- The implementation constructor disables initializers.
- The proxy is initialized atomically during deployment.
- Initialization validates every role holder and the initial CCIP admin, initializes the transient
  reentrancy guard, and can execute only once.
- `_authorizeUpgrade` requires `UPGRADER_ROLE`.
- Token-specific mutable state uses ERC-7201 namespaced storage.
- Upgrade tests verify preservation of metadata, CCIP admin, balances, allowances, total supply,
  pause state, default admin, and roles.
