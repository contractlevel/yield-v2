# Operator Configuration

This document is an operator-focused API guide for Yieldcoin v2 configuration and operational setter functions. It lists which functions an operator may need to call, which role is required, and why each function exists.

For the full authority model, use [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) as the source of truth. This guide is the operator-facing companion for day-to-day configuration and incident-response operations.

## Contents

- [Operator Configuration](#operator-configuration)
  - [Contents](#contents)
  - [Use](#use)
  - [Role Summary](#role-summary)
  - [Vault Configuration](#vault-configuration)
  - [Workflow Router Configuration](#workflow-router-configuration)
  - [Pause Controls](#pause-controls)
  - [Adapter Registry Configuration](#adapter-registry-configuration)
  - [Operational Functions](#operational-functions)
  - [Token Configuration](#token-configuration)
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
| `CONFIG_OPERATOR_ROLE`            | Maintain vault, router, registry, token metadata, CCIP, treasury, and supported protocol configuration.                                                |
| `PAUSER_ROLE` / `UNPAUSER_ROLE`   | Pause and unpause vaults, router, and token where configured.                                                                                          |
| `LINK_OPERATOR_ROLE`              | Withdraw unused LINK from vault contracts.                                                                                                             |
| `REWARDS_OPERATOR_ROLE`           | Claim protocol rewards from supported adapters, currently Compound V3.                                                                                 |
| `CANCEL_DEPOSIT_OPERATOR_ROLE`    | Force-cancel a stuck current-epoch deposit to preserve liveness.                                                                                       |
| `UPGRADER_ROLE`                   | Upgrade UUPS implementations. See [`UPGRADES`](./UPGRADES.md).                                                                                         |
| `EPOCH_OPERATOR_ROLE`             | Execute epoch settlement. This role is intended for [`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol), not a routine human operator wallet. |
| `REBALANCE_OPERATOR_ROLE`         | Execute strategy rebalances. This role is intended for `WorkflowRouter`, not a routine human operator wallet.                                          |

See [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#roles) for role holders and the
contract-specific tables that follow it for exact entry-point authority.

## Vault Configuration

Vault configuration exists on both [`ParentVault`](../../evm/src/vaults/ParentVault.sol) and [`ChildVault`](../../evm/src/vaults/ChildVault.sol) through [`BaseVault`](../../evm/src/vaults/BaseVault.sol).

| Function                                        | Role                   | Applies to              | Purpose                                                                                                     |
| ----------------------------------------------- | ---------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------- |
| `setCrosschainVaults(chainSelectors, vaults)`   | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Registers the trusted vault address for each CCIP chain selector. Set a vault to `address(0)` to remove it. |
| `setCcipGasLimit(chainSelector, gasLimit)`      | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Sets or clears a per-chain CCIP gas limit override. Use `0` to fall back to the default gas limit.          |
| `setDefaultCcipGasLimit(gasLimit)`              | `CONFIG_OPERATOR_ROLE` | Parent and child vaults | Sets the default CCIP gas limit used when no per-chain override exists.                                     |
| `setTreasury(treasury)`                         | `CONFIG_OPERATOR_ROLE` | Parent only             | Sets the treasury address for protocol fees.                                                                |
| `setSupportedProtocol(protocolId, isSupported)` | `CONFIG_OPERATOR_ROLE` | Parent only             | Marks whether a strategy protocol is supported anywhere in the system.                                      |
| `setInitialActiveProtocolAdapter(protocolId)`   | `DEFAULT_ADMIN_ROLE`   | Parent only             | One-time deployment action that sets the first active adapter after deployment and adapter registration.    |

Before changing cross-chain vaults or gas limits, confirm there is no active rebalance, no epoch waiting on cross-chain execution, and no stored recovery that depends on the old route. Removing a cross-chain vault can orphan in-flight CCIP messages.

Before changing the treasury, verify the address is controlled by the intended custody process.

## Workflow Router Configuration

[`WorkflowRouter`](../../evm/src/modules/WorkflowRouter.sol) validates Chainlink CRE reports before dispatching allowed calldata to the vault.

| Function                                                     | Role                   | Purpose                                                                                                                           |
| ------------------------------------------------------------ | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `setWorkflowMetadata(workflowId, name, owner)`               | `CONFIG_OPERATOR_ROLE` | Registers or removes the expected workflow identity. Use zero `name` and zero `owner` together to remove metadata.                |
| `setWorkflowSelectors(workflowId, selectors, isAllowlisted)` | `CONFIG_OPERATOR_ROLE` | Allows or removes specific vault function selectors for a workflow. Requires the workflow ID to already have registered metadata. |

Workflow selector configuration is security-critical. The operator should allowlist only the selectors needed by the specific workflow, such as epoch or rebalance execution selectors, and should verify selector values before applying changes.

Every successful `setWorkflowMetadata` call starts a fresh, empty selector-allowlist generation for that workflow ID - registration, removal, or updating the metadata of an already-registered workflow ID (changing either the name or the owner, or both). This applies even when reusing a workflow ID that was previously removed and registering it under a different name or owner: the router will never let a new registration inherit selectors that were allowlisted for a prior one. `setWorkflowMetadata` reverts with `WorkflowRouter__MetadataUnchanged` if the submitted name and owner already match the currently registered metadata for the workflow ID - including calling removal on a workflow ID that is already unregistered - so every successful call is guaranteed to be a real identity change.

Registering a workflow ID, or updating the metadata of one that is still registered, requires selectors to be re-added with `setWorkflowSelectors` afterward. Removing a workflow ID also invalidates its selectors, but additionally leaves it unable to receive new selectors until it is registered again, since `setWorkflowSelectors` reverts with `WorkflowRouter__WorkflowNotRegistered` for any workflow ID with no registered metadata. Always call `setWorkflowMetadata` before `setWorkflowSelectors` when configuring a new workflow.

## Pause Controls

| Function    | Role            | Applies to                                                                 | Purpose                                                                          |
| ----------- | --------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `pause()`   | `PAUSER_ROLE`   | Parent vault, child vault, WorkflowRouter, and YieldcoinShare | Stops the protected contract path during incidents or controlled maintenance.    |
| `unpause()` | `UNPAUSER_ROLE` | Parent vault, child vault, WorkflowRouter, and YieldcoinShare | Resumes operation after the condition that required the pause has been resolved. |

Vault pause state blocks normal user, epoch, rebalance, recovery, inbound CCIP, and ParentVault completion flows. In particular, `completeEpochDeposit(expectedEpochNonce)` and `completeRebalance(expectedRebalanceNonce)` cannot acknowledge CRE-observed remote success while ParentVault is paused. After reconciling cross-chain state, operators must use the controlled unpause procedure in [OPERATIONS](./OPERATIONS.md#paused-cross-chain-execution) to resume or finalize an in-flight operation. Before submitting a completion report, read ParentVault state and pass the most recently closed epoch nonce (`getEpochNonce() - 1`) or current rebalance nonce (`getRebalance().nonce`), respectively.

## Adapter Registry Configuration

[`AdapterRegistry`](../../evm/src/modules/AdapterRegistry.sol) maps protocol IDs to protocol adapter contracts on each chain.

| Function                          | Role                   | Purpose                                                                                                    |
| --------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| `setAdapter(protocolId, adapter)` | `CONFIG_OPERATOR_ROLE` | Registers, replaces, or removes the adapter for a protocol ID. Set `adapter` to `address(0)` to remove it. |

Before changing an adapter, verify it is deployed for the correct vault and underlying asset, and that no pending rebalance or recovery still depends on the current mapping. A vault can only activate an adapter that is registered for the requested protocol ID and bound to that vault.

## Operational Functions

| Function                   | Role                           | Applies to              | Purpose                                                                              |
| -------------------------- | ------------------------------ | ----------------------- | ------------------------------------------------------------------------------------ |
| `withdrawLink(amount)`     | `LINK_OPERATOR_ROLE`           | Parent and child vaults | Transfers LINK from the vault to the caller.                                         |
| `forceCancelDeposit(user)` | `CANCEL_DEPOSIT_OPERATOR_ROLE` | Parent only             | Cancels a user's current-epoch deposit and refunds the exact deposited asset amount. |

`withdrawLink(amount)` only moves LINK, not the underlying asset. LINK is still operationally important because CCIP sends depend on LINK balances.

`forceCancelDeposit(user)` is a narrow epoch-liveness tool and should not be used as a normal user-support path. Its operational rationale is documented in [DD-012](../protocol/DECISIONS.md#dd-012---forcecanceldeposit-is-a-narrow-epoch-liveness-tool).

## Token Configuration

[`YieldcoinShare`](../../evm/src/token/YieldcoinShare.sol) is an upgradeable ERC-20 share token governed by local OpenZeppelin access-control roles. For the role model, see [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#yieldcoinshare).

| Function or authority              | Control                                                    | Purpose                                                               |
| ---------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------- |
| `setCCIPAdmin(newAdmin)`           | `CONFIG_OPERATOR_ROLE`                                     | Sets the stored Chainlink CCIP token admin identity.                  |
| `pause()` / `unpause()`            | `PAUSER_ROLE` / `UNPAUSER_ROLE`                            | Pauses or unpauses transfers, minting, and burning.                   |
| `mint(...)` / `burn(...)`          | `MINTER_ROLE` / `BURNER_ROLE` held by `ParentVault`        | Allows the parent-vault flow to mint and burn shares.                 |
| UUPS implementation upgrade       | `UPGRADER_ROLE`                                            | Authorizes an upgrade to a compatible token implementation.          |

`setCCIPAdmin(newAdmin)` is not currently used by live Yieldcoin share-token flows. It is included so the protocol can later enable CCIP functionality for `YieldcoinShare` without changing the token's admin model.

## Rewards

[`CompoundV3Adapter.claimRewards(to)`](../../evm/src/modules/adapters/CompoundV3Adapter.sol) can be called by an address with `REWARDS_OPERATOR_ROLE` on the associated vault.

The adapter checks the role on the vault rather than owning its own role state. The recipient `to` must not be the zero address. Operators should verify the recipient and expected reward token behavior before claiming.

This is a best-effort, Compound-specific recovery hook. Secondary incentives, including rewards from Aave controllers, Merkl, partner programs, and points programs, are not supported consistently across adapters and may remain unclaimed, expire, or become unrecoverable. They are excluded from vault TVL and user entitlements. See [DESIGN DECISIONS](../protocol/DECISIONS.md#dd-009---yield-accounting-is-underlying-asset-only).

## Upgrades and Role Administration

UUPS vault and `YieldcoinShare` upgrades are authorized by `UPGRADER_ROLE`.

Local `DEFAULT_ADMIN_ROLE` holders grant and revoke local roles with inherited `grantRole(...)` and `revokeRole(...)`. They should not be routine operators for vault, router, registry, or incident-response actions. Use the access matrix to verify the intended holder and scope before changing any role.

See [`UPGRADES`](./UPGRADES.md) for upgrade procedure notes and
[`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#roles) for the authority summary.
