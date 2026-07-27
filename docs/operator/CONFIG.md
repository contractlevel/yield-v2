# Operator Configuration

This document is an operator-focused API guide for Yieldcoin v2 configuration and operational setter functions. It lists which functions an operator may need to call, which role is required, and why each function exists.

For the full authority model, use [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) as the source of truth. This guide is the operator-facing companion for day-to-day configuration and emergency operations.

## Contents

- [Operator Configuration](#operator-configuration)
  - [Contents](#contents)
  - [Use](#use)
  - [Role Summary](#role-summary)
  - [Vault Configuration](#vault-configuration)
  - [Workflow Router Configuration](#workflow-router-configuration)
  - [Pause Controls](#pause-controls)
  - [Adapter Registry Configuration](#adapter-registry-configuration)
  - [Recapitalization and Emergency Functions](#recapitalization-and-emergency-functions)
  - [Token and Policy Configuration](#token-and-policy-configuration)
  - [Policy Engine Replacement](#policy-engine-replacement)
  - [Rewards](#rewards)
  - [Upgrades and Role Administration](#upgrades-and-role-administration)

## Use

- Use the role assigned for the specific function.
- Verify the current value before changing configuration.
- Confirm the transaction emitted the expected event after the change.

## Role Summary

| Role or authority                 | Main responsibility                                                                                                                                    |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `DEFAULT_ADMIN_ROLE`              | Grant and revoke local roles. It should not be used for routine protocol operation.                                                                    |
| `CONFIG_OPERATOR_ROLE`            | Maintain vault, router, registry, token metadata, CCIP, treasury, supported protocol, and emergency receiver configuration.                            |
| `PAUSER_ROLE` / `UNPAUSER_ROLE`   | Pause and unpause vaults, router, and token where configured.                                                                                          |
| `POLICY_ENGINE_MANAGER_ROLE`      | Replace the policy engine attached to policy-protected contracts.                                                                                      |
| `DONATE_OPERATOR_ROLE`            | Recapitalize the active strategy by donating underlying asset without minting shares.                                                                  |
| `EMERGENCY_DRAINER_ROLE`          | Drain underlying asset to the configured emergency receiver after pause delay conditions are met.                                                      |
| `LINK_OPERATOR_ROLE`              | Withdraw unused LINK from vault contracts.                                                                                                             |
| `REWARDS_OPERATOR_ROLE`           | Claim protocol rewards from supported adapters, currently Compound V3.                                                                                 |
| `CANCEL_DEPOSIT_OPERATOR_ROLE`    | Force-cancel a stuck current-epoch deposit to preserve liveness.                                                                                       |
| `COMPLIANCE_OPERATOR_ROLE`        | Perform token compliance actions through ACE RBAC. See [`COMPLIANCE`](./COMPLIANCE.md).                                                                |
| `UPGRADER_ROLE` / token `owner()` | Upgrade UUPS implementations. See [`UPGRADES`](./UPGRADES.md).                                                                                         |
| `EPOCH_OPERATOR_ROLE`             | Execute epoch settlement. This role is intended for [`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol), not a routine human operator wallet. |
| `REBALANCE_OPERATOR_ROLE`         | Execute strategy rebalances. This role is intended for `WorkflowRouter`, not a routine human operator wallet.                                          |

See the matrix entries for [fundamental principles](../security/ACCESS_CONTROL_MATRIX.md#fundamental-principles), [authority mapping](../security/ACCESS_CONTROL_MATRIX.md#authority-matrix), and [contract-level controls](../security/ACCESS_CONTROL_MATRIX.md#contract-level-matrix).

## Vault Configuration

Vault configuration exists on both [`ParentVault`](../../evm/src/vaults/ParentVault.sol) and [`ChildVault`](../../evm/src/vaults/ChildVault.sol) through [`BaseVault`](../../evm/src/vaults/BaseVault.sol).

| Function                                        | Role                   | Applies to              | Purpose                                                                                                     |
| ----------------------------------------------- | ---------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------- |
| `setCrosschainVaults(chainSelectors, vaults)`   | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Registers the trusted vault address for each CCIP chain selector. Set a vault to `address(0)` to remove it. |
| `setCcipGasLimit(chainSelector, gasLimit)`      | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Sets or clears a per-chain CCIP gas limit override. Use `0` to fall back to the default gas limit.          |
| `setDefaultCcipGasLimit(gasLimit)`              | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Sets the default CCIP gas limit used when no per-chain override exists.                                     |
| `setEmergencyReceiver(emergencyReceiver)`       | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Sets the address that receives underlying asset during `emergencyDrain`.                                    |
| `setTreasury(treasury)`                         | `CONFIG_OPERATOR_ROLE` | Parent only             | Sets the treasury address for protocol fees.                                                                |
| `setSupportedProtocol(protocolId, isSupported)` | `CONFIG_OPERATOR_ROLE` | Parent only             | Marks whether a strategy protocol is supported anywhere in the system.                                      |
| `setInitialActiveProtocolAdapter(protocolId)`   | `DEFAULT_ADMIN_ROLE`   | Parent only             | One-time deployment action that sets the first active adapter after deployment and adapter registration.    |

Before changing cross-chain vaults or gas limits, confirm there is no active rebalance, no epoch waiting on cross-chain execution, and no stored recovery that depends on the old route. Removing a cross-chain vault can orphan in-flight CCIP messages.

Before changing the emergency receiver or treasury, verify the address is controlled by the intended custody process. The receiver only receives funds; it does not gain permission to execute any actions.

## Workflow Router Configuration

[`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol) validates Chainlink CRE reports before dispatching allowed calldata to the vault.

| Function                                                     | Role                   | Purpose                                                                                                            |
| ------------------------------------------------------------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `setWorkflowMetadata(workflowId, name, owner)`               | `CONFIG_OPERATOR_ROLE` | Registers or removes the expected workflow identity. Use zero `name` and zero `owner` together to remove metadata. |
| `setWorkflowSelectors(workflowId, selectors, isAllowlisted)` | `CONFIG_OPERATOR_ROLE` | Allows or removes specific vault function selectors for a workflow. Requires the workflow ID to already have registered metadata. |

Workflow selector configuration is security-critical. The operator should allowlist only the selectors needed by the specific workflow, such as epoch or rebalance execution selectors, and should verify selector values before applying changes.

Every successful `setWorkflowMetadata` call starts a fresh, empty selector-allowlist generation for that workflow ID - registration, removal, or updating the metadata of an already-registered workflow ID (changing either the name or the owner, or both). This applies even when reusing a workflow ID that was previously removed and registering it under a different name or owner: the router will never let a new registration inherit selectors that were allowlisted for a prior one. `setWorkflowMetadata` reverts with `WorkflowRouter__MetadataUnchanged` if the submitted name and owner already match the currently registered metadata for the workflow ID - including calling removal on a workflow ID that is already unregistered - so every successful call is guaranteed to be a real identity change.

Registering a workflow ID, or updating the metadata of one that is still registered, requires selectors to be re-added with `setWorkflowSelectors` afterward. Removing a workflow ID also invalidates its selectors, but additionally leaves it unable to receive new selectors until it is registered again, since `setWorkflowSelectors` reverts with `WorkflowRouter__WorkflowNotRegistered` for any workflow ID with no registered metadata. Always call `setWorkflowMetadata` before `setWorkflowSelectors` when configuring a new workflow.

## Pause Controls

| Function    | Role            | Applies to                                                                 | Purpose                                                                          |
| ----------- | --------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `pause()`   | `PAUSER_ROLE`   | Parent vault, child vault, WorkflowRouter, YieldcoinShare through ACE RBAC | Stops the protected contract path during incidents or controlled maintenance.    |
| `unpause()` | `UNPAUSER_ROLE` | Parent vault, child vault, WorkflowRouter, YieldcoinShare through ACE RBAC | Resumes operation after the condition that required the pause has been resolved. |

Vault pause state blocks normal user, epoch, and rebalance flows, but `donate(amount)` remains callable by `DONATE_OPERATOR_ROLE` while paused. `emergencyDrain(revertOnFailure)` requires the target vault to be paused.

## Adapter Registry Configuration

[`AdapterRegistry`](../../evm/src/modules/AdapterRegistry.sol) maps protocol IDs to protocol adapter contracts on each chain.

| Function                          | Role                   | Purpose                                                                                                    |
| --------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| `setAdapter(protocolId, adapter)` | `CONFIG_OPERATOR_ROLE` | Registers, replaces, or removes the adapter for a protocol ID. Set `adapter` to `address(0)` to remove it. |

Before changing an adapter, verify the adapter is deployed for the correct vault and underlying asset. A vault can only activate an adapter that is registered for the requested protocol ID and bound to that vault.

## Recapitalization and Emergency Functions

These functions are high-risk operational tools. Use them only with explicit internal approval and a clear record of why the action is needed.

| Function                          | Role                           | Applies to              | Purpose                                                                                                                                                                                  |
| --------------------------------- | ------------------------------ | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `donate(amount)`                  | `DONATE_OPERATOR_ROLE`         | Parent and child vaults | Transfers underlying asset from the caller and deposits it into the active strategy without minting shares or creating user claims.                                                      |
| `emergencyDrain(revertOnFailure)` | `EMERGENCY_DRAINER_ROLE`       | Parent and child vaults | After the vault has been paused for at least one day, withdraws available strategy TVL when possible and transfers all vault-held underlying asset to the configured emergency receiver. |
| `withdrawLink(amount)`            | `LINK_OPERATOR_ROLE`           | Parent and child vaults | Transfers LINK from the vault to the caller.                                                                                                                                             |
| `forceCancelDeposit(user)`        | `CANCEL_DEPOSIT_OPERATOR_ROLE` | Parent only             | Cancels a user's current-epoch deposit and refunds the exact deposited asset amount.                                                                                                     |

`donate(amount)` is intended for recapitalization and recovery. It is allowed while paused. Do not donate before the first deposit, because bootstrap pricing can let the first depositor capture the donation.

`emergencyDrain(revertOnFailure)` requires the vault to be paused and the one-day emergency drain delay to have elapsed. The `CONFIG_OPERATOR_ROLE` sets the emergency receiver, while `EMERGENCY_DRAINER_ROLE` executes the drain. These powers should be held separately where practical.

`withdrawLink(amount)` only moves LINK, not the underlying asset. LINK is still operationally important because CCIP sends depend on LINK balances.

`forceCancelDeposit(user)` is a narrow liveness tool for deposits that could block epoch settlement. It should not be used as a normal user support path.

## Token and Policy Configuration

[`YieldcoinShare`](../../evm/src/token/YieldcoinShare.sol) uses Chainlink ACE policy checks for most token-level operations. For the detailed compliance model, see [`COMPLIANCE`](./COMPLIANCE.md). For the role model, see [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#yieldcoinshare).

| Function or authority                | Control                                                      | Purpose                                                          |
| ------------------------------------ | ------------------------------------------------------------ | ---------------------------------------------------------------- |
| `setCCIPAdmin(newAdmin)`             | ACE RBAC `CONFIG_OPERATOR_ROLE`                              | Sets the stored Chainlink CCIP token admin identity.             |
| `setName(...)` / `setSymbol(...)`    | ACE RBAC `CONFIG_OPERATOR_ROLE`                              | Updates token metadata when allowed by policy.                   |
| `attachPolicyEngine(policyEngine)`   | ACE RBAC `POLICY_ENGINE_MANAGER_ROLE`                        | Replaces the policy engine attached to the token.                |
| `pause()` / `unpause()`              | ACE RBAC `PAUSER_ROLE` / `UNPAUSER_ROLE`                     | Pauses or unpauses token behavior through the token policy path. |
| forced transfer and freeze functions | ACE RBAC `COMPLIANCE_OPERATOR_ROLE`                          | Executes compliance operations.                                  |
| `mint(...)` / `burn(...)`            | ACE RBAC `MINTER_ROLE` / `BURNER_ROLE` held by `ParentVault` | Allows the vault flow to mint and burn shares.                   |

`setCCIPAdmin(newAdmin)` is not currently used by live Yieldcoin share-token flows. It is included so the protocol can later enable CCIP functionality for `YieldcoinShare` without changing the token's admin model.

Policy wiring is administered through `PolicyEngine.ADMIN_ROLE`. Policy internals, including RBAC operation allowances and role membership, are administered through `PolicyEngine.POLICY_CONFIG_ADMIN_ROLE`.

## Policy Engine Replacement

| Function                           | Control                               | Contract       | Purpose                                                  |
| ---------------------------------- | ------------------------------------- | -------------- | -------------------------------------------------------- |
| `attachPolicyEngine(policyEngine)` | Local `POLICY_ENGINE_MANAGER_ROLE`    | Parent vault   | Replaces the policy engine attached to the parent vault. |
| `attachPolicyEngine(policyEngine)` | ACE RBAC `POLICY_ENGINE_MANAGER_ROLE` | YieldcoinShare | Replaces the policy engine attached to the share token.  |

Policy engine replacement is a high-risk operation. The replacement engine should already have the intended policy wiring before it is attached, otherwise protected functions can unexpectedly revert or lose intended checks.

## Rewards

[`CompoundV3Adapter.claimRewards(to)`](../../evm/src/modules/adapters/CompoundV3Adapter.sol) can be called by an address with `REWARDS_OPERATOR_ROLE` on the associated vault.

The adapter checks the role on the vault rather than owning its own role state. The recipient `to` must not be the zero address. Operators should verify the recipient and expected reward token behavior before claiming.

Beyond this ability to claim, COMP rewards handling is not explicitly part of the protocol and deferred. See [DESIGN DECISIONS](../protocol/DECISIONS.md#dd-009---yield-accounting-is-underlying-asset-only).

## Upgrades and Role Administration

UUPS vault upgrades are authorized by `UPGRADER_ROLE`. `YieldcoinShare` upgrade authority is its inherited `owner()`, which should be treated as the token upgrader authority and not as general token administration.

Local `DEFAULT_ADMIN_ROLE` holders grant and revoke local roles with inherited `grantRole(...)` and `revokeRole(...)`. They should not be routine operators for vault, router, registry, or emergency actions. Use the access matrix to verify the intended holder and scope before changing any role.

See [`UPGRADES`](./UPGRADES.md) for upgrade procedure notes and [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#summary) for the authority summary.
