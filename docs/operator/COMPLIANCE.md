# Compliance

This document describes the onchain compliance model for Yieldcoin v2. It is operator-facing, but it is public and should not contain private provider credentials, signer contacts, or user PII.

## Contents

- [Compliance](#compliance)
  - [Contents](#contents)
  - [KYC and Identity Provider](#kyc-and-identity-provider)
  - [Current Policy Chains](#current-policy-chains)
    - [ParentVault User Functions](#parentvault-user-functions)
    - [YieldcoinShare Transfers And Approvals](#yieldcoinshare-transfers-and-approvals)
    - [YieldcoinShare Supply, Admin, Pause, And Compliance Operations](#yieldcoinshare-supply-admin-pause-and-compliance-operations)
    - [Identity And Credential Registry Writes](#identity-and-credential-registry-writes)
  - [Replacing Or Updating Policies](#replacing-or-updating-policies)
  - [Replacing The Policy Engine](#replacing-the-policy-engine)

## KYC and Identity Provider

Yieldcoin v2 integrates onchain ACE policy checks with an offchain KYC or compliance process.

The commercial operator can use a third-party KYC provider, such as [SumSub](https://sumsub.com/) or another approved identity provider. Alternatively, the commercial operator can run its own offchain compliance infrastructure and facilitate the required onchain writes itself.

In either model, the offchain process performs the real-world user verification. After a user completes KYC, an authorized provider or operator-controlled writer records the user's onchain identity and credential status:

- `IdentityRegistry.registerIdentity(ccid, account, context)` maps the user's address to a `bytes32` CCID.
- `CredentialRegistry.registerCredential(ccid, credentialTypeId, expiresAt, credentialData, context)` records that the CCID has the required credential, such as `common.kyc`.

The protocol's ACE policies then check that onchain confirmation when a user calls protected [`ParentVault`](../../evm/src/vaults/ParentVault.sol) functions or uses policy-gated Yieldcoin share actions.

The KYC or compliance process should not publish user PII onchain. The identity provider or operator-controlled compliance service computes the user's CCID offchain at its own discretion, then writes the address-to-CCID mapping and the KYC credential for that CCID onchain. Yieldcoin's current KYC flow does not use `credentialData`; if it is used later for extra metadata such as jurisdiction, it should contain only non-sensitive data, a hash, or a reference rather than raw personal data.

## Current Policy Chains

The parent deployment script wires ACE policies during deployment. Policy chains are evaluated in order. Policies that validate successfully generally return `Continue`; [`TerminalAllowPolicy`](../../evm/src/modules/policies/TerminalAllowPolicy.sol) is attached last so the call is explicitly allowed only after the earlier policies pass.

### ParentVault User Functions

The following `ParentVault` user functions are ACE-gated:

- `deposit`
- `withdraw`
- `claimShares`
- `claimAsset`
- `cancelDeposit`
- `cancelWithdraw`

For each selector, the deploy script configures [`SenderExtractor`](../../evm/src/modules/extractors/SenderExtractor.sol), then attaches this policy chain:

1. [`YieldcoinShareFrozenAccountPolicy`](../../evm/src/modules/policies/YieldcoinShareFrozenAccountPolicy.sol) checks that `msg.sender` is not frozen on [`YieldcoinShare`](../../evm/src/token/YieldcoinShare.sol).
2. [`CredentialRegistryIdentityValidatorPolicy`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/src/CredentialRegistryIdentityValidatorPolicy.sol) checks that `msg.sender` has the required KYC credential.
3. `TerminalAllowPolicy` allows the call after the previous checks pass.

This means a user must be KYC-approved and not frozen before using the vault's direct user entry points.

The restriction applies throughout the user lifecycle. A frozen user cannot cancel an open deposit or withdrawal or claim settled shares or assets until an authorized compliance operator unfreezes the account. The underlying intent or claim remains recorded while frozen and resumes through the normal user path after unfreezing. `forceCancelDeposit` is not a compliance bypass; its separate epoch-liveness purpose is documented in [DD-012](../protocol/DECISIONS.md#dd-012---forcecanceldeposit-is-a-narrow-epoch-liveness-tool).

#### Deliberate overlap with share-token checks

`withdraw` and `cancelWithdraw` move `YieldcoinShare` tokens after the ParentVault policy check. Those share-token transfers also enforce KYC and frozen-account restrictions through `YieldcoinShare` / ERC-3643 transfer policy. The overlap is intentional: ParentVault keeps a uniform fail-closed policy stack for all direct user entry points, while the share token remains the final enforcement boundary for token movement. The extra policy calls are accepted as defense-in-depth despite the additional gas cost.

This is also tracked as an accepted gas tradeoff in [GAS - GAS-005](../protocol/GAS.md#gas-005---deliberate-overlap-between-parentvault-policy-checks-and-share-token-transfer-checks).

### YieldcoinShare Transfers And Approvals

The following `YieldcoinShare` user actions are ACE-gated:

- `transfer`
- `transferFrom`
- `batchTransfer`
- `approve`
- `increaseAllowance`
- `decreaseAllowance`

The deploy script configures [`YieldcoinShareKycExtractor`](../../evm/src/modules/extractors/YieldcoinShareKycExtractor.sol), then attaches:

1. [`CredentialRegistryAccountListValidatorPolicy`](../../evm/src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol) checks every extracted account that must satisfy KYC for that selector.
2. `TerminalAllowPolicy` allows the call after the KYC account-list check passes.

The extractor chooses accounts by selector:

- `transfer`: caller and recipient.
- `transferFrom`: caller, source, and recipient.
- `batchTransfer`: caller and every recipient.
- `approve` / `increaseAllowance`: caller and spender.
- `decreaseAllowance`: caller only, so users can reduce approval exposure even if a spender later loses KYC status.

### YieldcoinShare Supply, Admin, Pause, And Compliance Operations

Some `YieldcoinShare` functions are protected by ACE [`RoleBasedAccessControlPolicy`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/src/policies/RoleBasedAccessControlPolicy.sol) instead of local OpenZeppelin roles. The deploy script configures operation allowances and role membership through the [`PolicyEngine`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/src/core/PolicyEngine.sol).

Current role-gated token functions include:

- `mint`: `MINTER_ROLE`, granted to `ParentVault`.
- `burn`: `BURNER_ROLE`, granted to `ParentVault`.
- `setCCIPAdmin`, `setName`, `setSymbol`: `CONFIG_OPERATOR_ROLE`.
- `attachPolicyEngine`: `POLICY_ENGINE_MANAGER_ROLE`.
- `pause`: `PAUSER_ROLE`.
- `unpause`: `UNPAUSER_ROLE`.
- forced transfer, address freeze, partial freeze, and corresponding batch/unfreeze functions: `COMPLIANCE_OPERATOR_ROLE`.

Each of these selectors is followed by `TerminalAllowPolicy`.

`YieldcoinShare.mint` does not KYC-check the recipient directly because `ParentVault` is the only intended caller of share minting, and the user-facing `ParentVault` claim path is already ACE-gated.

### Identity And Credential Registry Writes

The deploy script protects identity and credential registry writes with [`OnlyAuthorizedSenderPolicy`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/src/policies/OnlyAuthorizedSenderPolicy.sol) followed by `TerminalAllowPolicy`.

Authorized provider-gated identity selectors:

- `IdentityRegistry.registerIdentity`
- `IdentityRegistry.registerIdentities`
- `IdentityRegistry.removeIdentity`

Authorized provider-gated credential selectors:

- `CredentialRegistry.registerCredential`
- `CredentialRegistry.registerCredentials`
- `CredentialRegistry.removeCredential`
- `CredentialRegistry.renewCredential`

This is the onchain gate that lets only the configured provider or operator-controlled writer maintain user identity and credential state.

## Replacing Or Updating Policies

Policy wiring is administered through `PolicyEngine.ADMIN_ROLE`. This role controls which policies, extractors, mappers, and default behavior apply to protected targets and selectors.

Policy internals are administered through `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`. This role calls `PolicyEngine.setPolicyConfiguration(...)`, which lets the `PolicyEngine` configure policies it owns or administers. Examples include:

- authorizing or unauthorizing provider senders in `OnlyAuthorizedSenderPolicy`;
- changing RBAC operation allowances or role membership in `RoleBasedAccessControlPolicy`;
- updating configurable credential requirements on policies that expose supported configuration functions.

Policy changes should preserve the intended fail-closed shape:

- restrictive checks first;
- `TerminalAllowPolicy` last;
- no accidental `Allowed` policy before required KYC, freeze, RBAC, or provider checks;
- no unprotected selector that should remain policy-gated.

See [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) for the authority model.

## Replacing The Policy Engine

`ParentVault` and `YieldcoinShare` can attach a replacement policy engine, but the authority path differs.

For `ParentVault`, `attachPolicyEngine(policyEngine)` is a local role-gated function. The caller must have `POLICY_ENGINE_MANAGER_ROLE` on `ParentVault`.

For `YieldcoinShare`, `attachPolicyEngine(policyEngine)` is itself protected by ACE `runPolicy`. The current deploy script gates that selector through `RoleBasedAccessControlPolicy`, with `POLICY_ENGINE_MANAGER_ROLE` granted to the configured policy engine manager.

A policy engine replacement must be treated as a high-risk operation. The replacement engine must already contain equivalent intended policy wiring for all protected selectors before it is attached, otherwise user functions or token functions may revert unexpectedly or lose intended compliance checks.
