# Access Control Matrix

## Purpose

This document defines the access control model for Yieldcoin v2.

It is the source of truth for how authority should be named, assigned, implemented, and reviewed across the codebase. Contract changes should preserve this model unless this document is updated first.

## Fundamental Principles

| Principle                                           | Rule                                                                                                                                                         |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `DEFAULT_ADMIN_ROLE` grants and revokes roles only  | Default admin roles administer roles for their own contract. They should not operate privileged business functions.                                          |
| ACE policies control runtime permissions            | Selector-level permissions, KYC, compliance actions, token operations, and provider authorization are enforced through Chainlink ACE where practical.        |
| `PolicyEngine` owns ACE policies                    | ACE policy contracts are owned/administered by `PolicyEngine` where practical, so policy internals are configured through one engine role.                   |
| Policy wiring and policy configuration are separate | `PolicyEngine.ADMIN_ROLE` wires policy stacks. `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` configures policy internals. They may be co-held but remain distinct. |
| Local roles control system administration           | Upgrades, policy engine replacement, vault/router/registry configuration, and operational system functions use explicit local roles.                         |
| Compliance operation is not policy administration   | A compliance operator can perform compliance actions, but should not automatically rewire, replace, or administer the policy system.                         |
| Role names describe real power                      | Broad authority uses broad names. Narrow operational authority stays narrow.                                                                                 |

## Authority Matrix

| Authority                   | System                                  | Controller                                                                       | Can do                                                                                      | Notes                                                                                         |
| --------------------------- | --------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Local role admin            | Vaults, WorkflowRouter, AdapterRegistry | `DEFAULT_ADMIN_ROLE`                                                             | Grant/revoke local roles                                                                    | Use `AccessControlDefaultAdminRules`; avoid direct operational functions where possible       |
| ACE role admin              | `PolicyEngine`                          | `PolicyEngine.DEFAULT_ADMIN_ROLE`                                                | Grant/revoke `PolicyEngine` roles                                                           | Same role-admin purpose as vault default admin, but without default-admin transfer guardrails |
| Policy wiring               | `PolicyEngine`                          | `POLICY_ADMIN_ROLE` actor holding `PolicyEngine.ADMIN_ROLE`                      | Add/remove/reorder policies, set extractors, set mappers, set target/default allow behavior | High privilege; distinct from policy configuration and compliance operation                   |
| Policy configuration        | `PolicyEngine`                          | `POLICY_CONFIG_ADMIN_ROLE` actor holding `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` | Configure internals of policies owned/administered by `PolicyEngine`                        | High privilege; distinct from policy wiring; may be held by the same multisig initially       |
| Policy engine replacement   | Policy-protected contracts              | `POLICY_ENGINE_MANAGER_ROLE`                                                     | Replace attached policy engine                                                              | Separate from compliance operation and default admin role administration                      |
| RBAC policy administration  | `RoleBasedAccessControlPolicy`          | `PolicyEngine` controlled by `POLICY_CONFIG_ADMIN_ROLE`                          | Manage operation allowances and RBAC role membership through `setPolicyConfiguration`       | `PolicyEngine` is RBAC `owner()` and holds RBAC `DEFAULT_ADMIN_ROLE`                          |
| Token compliance operations | `YieldcoinShare` through ACE RBAC       | `COMPLIANCE_OPERATOR_ROLE`                                                       | Forced transfers, freeze/unfreeze, address freeze, possibly pause/unpause                   | Runtime authority enforced by ACE policy                                                      |
| Token pause                 | `YieldcoinShare` through ACE RBAC       | `PAUSER_ROLE`                                                                    | Pause token                                                                                 | Can also allow `COMPLIANCE_OPERATOR_ROLE` if desired                                          |
| Token unpause               | `YieldcoinShare` through ACE RBAC       | `UNPAUSER_ROLE`                                                                  | Unpause token                                                                               | Separate from pause if asymmetric safety is desired                                           |
| Share supply                | `YieldcoinShare` through ACE RBAC       | `ParentVault` with `MINTER_ROLE` / `BURNER_ROLE`                                 | Mint and burn shares                                                                        | Share supply authority belongs to the vault flow                                              |
| Vault user access           | `ParentVault` through ACE policies      | KYC/compliance policy stack                                                      | Gate deposit, withdraw, claim, cancel functions                                             | ACE is the user eligibility layer                                                             |
| Epoch execution             | Vaults                                  | `WorkflowRouter` holding `EPOCH_OPERATOR_ROLE`                                   | Epoch execution (`closeEpoch`, `executeEpochWithdraw`)                                      | Keep operational vault roles local; only user-facing functions should move through ACE        |
| Rebalance execution         | Vaults                                  | `WorkflowRouter` holding `REBALANCE_OPERATOR_ROLE`                               | Rebalance execution (`initiateRebalance`, `completeRebalance`, `executeRebalance`)          | Keep operational vault roles local; only user-facing functions should move through ACE        |
| Vault recovery              | Vaults                                  | Public stored-state retry                                                        | Execute recovery from previously stored recovery state                                      | Caller must not choose amount, strategy, destination, or recipient                            |
| Protocol config             | Vaults, routers, registry               | `CONFIG_OPERATOR_ROLE`                                                           | Set vault/router config, adapters, workflow metadata/selectors, emergency receiver          | Explicit and narrow                                                                           |
| Emergency receiver          | Vaults                                  | Configured receiver address                                                      | Receives USDC from `emergencyDrain`                                                        | Fund destination only; does not grant execution or configuration authority                    |
| CCIP token admin            | `YieldcoinShare`                        | `CONFIG_OPERATOR_ROLE` actor through ACE RBAC                                    | Set Chainlink CCIP token admin identity                                                     | `getCCIPAdmin()` returns stored CCIP admin state, never token `owner()`                       |
| Upgrades                    | Upgradeable contracts, if added         | `UPGRADER_ROLE`                                                                  | Upgrade implementation contracts                                                            | Defined for future upgradeable surfaces                                                       |

## Contract-Level Matrix

### ParentVault

| Function or authority                                | Control                                                            |
| ---------------------------------------------------- | ------------------------------------------------------------------ |
| Grant/revoke roles                                   | `DEFAULT_ADMIN_ROLE`                                               |
| `setInitialActiveProtocolAdapter`                    | `DEFAULT_ADMIN_ROLE` because this is a one-time deploy-time action |
| Config setters                                       | `CONFIG_OPERATOR_ROLE`                                             |
| Pause/unpause                                        | `PAUSER_ROLE` / `UNPAUSER_ROLE`                                    |
| Epoch (`closeEpoch`)                                 | `EPOCH_OPERATOR_ROLE` granted to `WorkflowRouter`                  |
| Rebalance (`initiateRebalance`, `completeRebalance`) | `REBALANCE_OPERATOR_ROLE` granted to `WorkflowRouter`              |
| Recovery                                             | Public stored-state retry                                          |
| Emergency drain                                      | `EMERGENCY_DRAINER_ROLE` executes; `CONFIG_OPERATOR_ROLE` sets receiver |
| LINK withdrawal                                      | `LINK_OPERATOR_ROLE`                                               |
| `attachPolicyEngine`                                 | `POLICY_ENGINE_MANAGER_ROLE`                                       |
| User deposit/withdraw/claim/cancel                   | ACE policy stack                                                   |

### ChildVault

| Function or authority          | Control                                               |
| ------------------------------ | ----------------------------------------------------- |
| Grant/revoke roles             | `DEFAULT_ADMIN_ROLE`                                  |
| Config setters                 | `CONFIG_OPERATOR_ROLE`                                |
| Pause/unpause                  | `PAUSER_ROLE` / `UNPAUSER_ROLE`                       |
| Epoch (`executeEpochWithdraw`) | `EPOCH_OPERATOR_ROLE` granted to `WorkflowRouter`     |
| Rebalance (`executeRebalance`) | `REBALANCE_OPERATOR_ROLE` granted to `WorkflowRouter` |
| Recovery                       | Public stored-state retry                             |
| Emergency drain                | `EMERGENCY_DRAINER_ROLE` executes; `CONFIG_OPERATOR_ROLE` sets receiver |
| LINK withdrawal                | `LINK_OPERATOR_ROLE`                                  |

### WorkflowRouter

| Function or authority       | Control                         |
| --------------------------- | ------------------------------- |
| Grant/revoke roles          | `DEFAULT_ADMIN_ROLE`            |
| Workflow metadata/selectors | `CONFIG_OPERATOR_ROLE`          |
| `onReport`                  | `KEYSTONE_FORWARDER_ROLE`       |
| Pause/unpause               | `PAUSER_ROLE` / `UNPAUSER_ROLE` |

### AdapterRegistry

| Function or authority | Control                |
| --------------------- | ---------------------- |
| Grant/revoke roles    | `DEFAULT_ADMIN_ROLE`   |
| Adapter registration  | `CONFIG_OPERATOR_ROLE` |

### YieldcoinShare

| Function or authority                      | Control                                                                                       |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| ACE RBAC administration                    | `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` is RBAC `owner()` and holds RBAC `DEFAULT_ADMIN_ROLE` |
| `mint` / `burn`                            | ACE RBAC: `ParentVault` holds `MINTER_ROLE` / `BURNER_ROLE`                                   |
| `pause`                                    | ACE RBAC: `PAUSER_ROLE`, optionally also `COMPLIANCE_OPERATOR_ROLE`                           |
| `unpause`                                  | ACE RBAC: `UNPAUSER_ROLE`, optionally also `COMPLIANCE_OPERATOR_ROLE`                         |
| `forcedTransfer` and batch forced transfer | ACE RBAC: `COMPLIANCE_OPERATOR_ROLE`                                                          |
| Freeze/unfreeze functions                  | ACE RBAC: `COMPLIANCE_OPERATOR_ROLE`                                                          |
| Transfers and approvals                    | ACE policy stack for KYC/compliance as needed                                                 |
| Metadata setters                           | ACE RBAC: `CONFIG_OPERATOR_ROLE`                                                              |
| `attachPolicyEngine`                       | Local `POLICY_ENGINE_MANAGER_ROLE`; do not rely on token `owner()`                            |
| `setCCIPAdmin()`                           | ACE RBAC: `CONFIG_OPERATOR_ROLE`                                                              |
| `getCCIPAdmin()`                           | Return stored CCIP admin, e.g. `s_ccipAdmin` or namespaced storage equivalent                 |
| `owner()`                                  | Keep only if required by inherited mechanics; do not treat as token admin                     |

## Chainlink ACE Model

### PolicyEngine

| Role                       | Holder                       | Direct power                                                      |
| -------------------------- | ---------------------------- | ----------------------------------------------------------------- |
| `DEFAULT_ADMIN_ROLE`       | Default admin multisig       | Grant/revoke `PolicyEngine` roles                                 |
| `ADMIN_ROLE`               | Policy admin multisig        | Wire policies, extractors, mappers, target/default allow behavior |
| `POLICY_CONFIG_ADMIN_ROLE` | Policy config admin multisig | Configure policy internals through the engine                     |

`PolicyEngine.DEFAULT_ADMIN_ROLE` grants and revokes ACE `PolicyEngine` roles. It has the same role-admin purpose as local default admin roles, but without the `AccessControlDefaultAdminRules` guardrails used by local contracts.

`PolicyEngine.ADMIN_ROLE` is policy-wiring authority. It controls which policies apply to which targets and selectors.

`PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` is policy-configuration authority. It calls `setPolicyConfiguration`, which makes `PolicyEngine` call a configuration function on a policy contract. For policies owned or administered by `PolicyEngine`, this is the human-facing authority for mutable policy internals.

`ADMIN_ROLE` and `POLICY_CONFIG_ADMIN_ROLE` remain conceptually separate. They may be granted to the same multisig initially, but that is a holder choice, not a role-meaning change.

### Policy Ownership

| Policy authority                       | Holder         |
| -------------------------------------- | -------------- |
| Policy contract `owner()`              | `PolicyEngine` |
| Policy-specific admin roles, if needed | `PolicyEngine` |

Human governance administers policy internals through `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`. `PolicyEngine` is the on-chain executor that owns or administers individual policy contracts.

### RoleBasedAccessControlPolicy

| RBAC authority                   | Holder         | Direct power                                |
| -------------------------------- | -------------- | ------------------------------------------- |
| RBAC policy `DEFAULT_ADMIN_ROLE` | `PolicyEngine` | Grants/revokes RBAC roles inside the policy |
| RBAC policy `owner()`            | `PolicyEngine` | Grants/removes operation allowances         |

RBAC access is complete only when both pieces align:

- role membership decides who has a role;
- operation allowances decide what that role can do.

`PolicyEngine` must hold both RBAC `owner()` and RBAC `DEFAULT_ADMIN_ROLE`, so role membership and operation allowances are governed together through `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`.

RBAC changes are made through `PolicyEngine.setPolicyConfiguration`:

| RBAC change                | Selector                                                           |
| -------------------------- | ------------------------------------------------------------------ |
| Grant operation allowance  | `grantOperationAllowanceToRole(bytes4 operation, bytes32 role)`    |
| Remove operation allowance | `removeOperationAllowanceFromRole(bytes4 operation, bytes32 role)` |
| Grant role membership      | `grantRole(bytes32 role, address account)`                         |
| Revoke role membership     | `revokeRole(bytes32 role, address account)`                        |

### OnlyAuthorizedSenderPolicy

| Policy authority | Holder         | Direct power                           |
| ---------------- | -------------- | -------------------------------------- |
| Policy `owner()` | `PolicyEngine` | Add/remove authorized sender addresses |

Authorized sender changes are made through `PolicyEngine.setPolicyConfiguration`:

| Sender change      | Selector                             |
| ------------------ | ------------------------------------ |
| Authorize sender   | `authorizeSender(address account)`   |
| Unauthorize sender | `unauthorizeSender(address account)` |

Human governance administers authorized senders through `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`. `PolicyEngine` is the on-chain executor that owns `OnlyAuthorizedSenderPolicy`, so provider allowlists are not controlled directly by a provider or compliance operator.

### IdentityRegistry and CredentialRegistry

| Function or authority                                                                                    | Control                                                                                         |
| -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Registry `owner()`                                                                                       | `PolicyEngine`                                                                                  |
| `attachPolicyEngine`                                                                                     | Registry `owner()`; effectively disabled in normal operation by making `PolicyEngine` the owner |
| `IdentityRegistry.registerIdentity` / `registerIdentities` / `removeIdentity`                            | Authorized identity provider senders in `OnlyAuthorizedSenderPolicy`, plus terminal allow       |
| `CredentialRegistry.registerCredential` / `registerCredentials` / `removeCredential` / `renewCredential` | Authorized credential provider senders in `OnlyAuthorizedSenderPolicy`, plus terminal allow     |
| Add/remove authorized provider senders                                                                   | `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` via `PolicyEngine.setPolicyConfiguration`               |
| Registry selector policy wiring                                                                          | `PolicyEngine.ADMIN_ROLE`                                                                       |
| Credential validation policy configuration                                                               | `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`                                                         |

`IdentityRegistry` and `CredentialRegistry` are Chainlink ACE `PolicyProtectedUpgradeable` contracts. Their mutable registry functions are protected by ACE policies, while inherited ownership controls policy engine attachment. Registry `owner()` must therefore be the `PolicyEngine`, not a credential issuer or compliance operator.

Identity and credential providers can write registry entries only when their sender address is authorized in the registry's `OnlyAuthorizedSenderPolicy`. `PolicyEngine.ADMIN_ROLE` wires that policy to the registry selectors. `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` changes the authorized provider senders by calling `PolicyEngine.setPolicyConfiguration`, which makes `PolicyEngine` call `authorizeSender` or `unauthorizeSender` on the policy.

## Runtime Policy Mapping

| Target                                    | Functions                                                                            | Policy                                                                       |
| ----------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `ParentVault`                             | `deposit`, `withdraw`, `claimShares`, `claimUsdc`, `cancelDeposit`, `cancelWithdraw` | KYC/compliance policy stack plus terminal allow                              |
| `YieldcoinShare`                          | `transfer`, `transferFrom`, approvals                                                | KYC/compliance transfer policy stack                                         |
| `YieldcoinShare`                          | `mint`, `burn`                                                                       | RBAC policy: `MINTER_ROLE` / `BURNER_ROLE` held by `ParentVault`             |
| `YieldcoinShare`                          | freeze/unfreeze and forced transfer functions                                        | RBAC policy: `COMPLIANCE_OPERATOR_ROLE`                                      |
| `YieldcoinShare`                          | `pause`, `unpause`                                                                   | RBAC policy: `PAUSER_ROLE` / `UNPAUSER_ROLE`, optionally compliance operator |
| `IdentityRegistry` / `CredentialRegistry` | Provider registration/removal/renewal selectors                                      | Authorized sender policy for KYC provider plus terminal allow                |

## Vault Recovery

Vault recovery functions are permissionless stored-state retries.

Recovery entry points may be public when they satisfy all of these conditions:

- caller input is limited to a nonce or recovery identifier;
- recovery amount comes from stored recovery state;
- recovery strategy comes from stored recovery state or existing active vault state;
- destination chain, receiver, and recipient are not caller-controlled;
- failed retry reverts without clearing stored recovery state;
- successful retry clears stored recovery state and completes the intended operation.

Under this model, a separate `RECOVERY_OPERATOR_ROLE` is not needed. Authorization happens when the failed operation stores recovery state; execution only consumes that state.

## Summary

The codebase uses one clear rule per authority type:

- ACE controls runtime permission decisions.
- Local OpenZeppelin roles control system administration.
- `DEFAULT_ADMIN_ROLE` grants and revokes roles only.
- `PolicyEngine` owns/administers ACE policies where practical.
- `PolicyEngine.ADMIN_ROLE` wires policy stacks.
- `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE` configures policy internals.
- Policy administration is separate from compliance operation.
- Policy engine replacement is separate from policy wiring.
- Token `owner()` is not the hidden center of operational authority.
