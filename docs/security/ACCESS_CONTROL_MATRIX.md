# Access Control Matrix

## Model

Yieldcoin v2 uses OpenZeppelin AccessControl directly. There is no policy or compliance
authorization layer.

- `DEFAULT_ADMIN_ROLE` grants and revokes roles. It does not implicitly bypass other role checks.
- Pause and unpause authority are separate.
- User vault actions are permissionless while the ParentVault is unpaused.
- UUPS upgrades require `UPGRADER_ROLE`.
- Recovery execution is permissionless and uses previously stored recovery data.

## Roles

| Role                           | Held by                        | Authority                                                                                                                     |
| ------------------------------ | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `DEFAULT_ADMIN_ROLE`           | Multisig A                     | Grant and revoke roles; manage the two-step default-admin transfer. On ParentVault, also set the initial active adapter once. |
| `UPGRADER_ROLE`                | Multisig B                     | Authorize UUPS upgrades to YieldcoinShare, ParentVault, or ChildVault.                                                        |
| `PAUSER_ROLE`                  | Hardware wallet and Multisig C | Pause YieldcoinShare, a vault, or WorkflowRouter.                                                                             |
| `UNPAUSER_ROLE`                | Multisig C                     | Unpause YieldcoinShare, a vault, or WorkflowRouter.                                                                           |
| `CONFIG_OPERATOR_ROLE`         | Multisig C                     | Update token, vault, and router configuration; register, replace, or remove protocol adapters in AdapterRegistry.             |
| `EPOCH_OPERATOR_ROLE`          | WorkflowRouter                 | Execute vault epoch operations.                                                                                               |
| `REBALANCE_OPERATOR_ROLE`      | WorkflowRouter                 | Execute vault rebalance operations.                                                                                           |
| `LINK_OPERATOR_ROLE`           | Multisig C                     | Withdraw LINK from a vault.                                                                                                   |
| `KEYSTONE_FORWARDER_ROLE`      | CRE Forwarder                  | Submit reports to WorkflowRouter.                                                                                             |
| `MINTER_ROLE`                  | ParentVault                    | Mint YieldcoinShare tokens.                                                                                                   |
| `BURNER_ROLE`                  | ParentVault                    | Burn YieldcoinShare tokens.                                                                                                   |
| `REWARDS_OPERATOR_ROLE`        | Multisig C                     | Claim Compound v3 rewards through an adapter.                                                                                 |
| `CANCEL_DEPOSIT_OPERATOR_ROLE` | Multisig C                     | Force-cancel a ParentVault deposit.                                                                                           |

Roles use `DEFAULT_ADMIN_ROLE` as their administrator unless the contract explicitly says
otherwise.

## Contracts

### YieldcoinShare

| Function       | Access                                 |
| -------------- | -------------------------------------- |
| `mint`         | `MINTER_ROLE` — granted to ParentVault |
| `burn`         | `BURNER_ROLE` — granted to ParentVault |
| `pause`        | `PAUSER_ROLE`                          |
| `unpause`      | `UNPAUSER_ROLE`                        |
| `setCCIPAdmin` | `CONFIG_OPERATOR_ROLE`                 |
| UUPS upgrade   | `UPGRADER_ROLE`                        |
| Transfers      | Public; disabled while paused          |
| Approvals      | Public; remain available while paused  |

Pausing YieldcoinShare disables transfers, minting, and burning.

### ParentVault

| Function                                              | Access                                                 |
| ----------------------------------------------------- | ------------------------------------------------------ |
| `setInitialActiveProtocolAdapter`                     | `DEFAULT_ADMIN_ROLE`; callable successfully once       |
| `setTreasury`                                         | `CONFIG_OPERATOR_ROLE`                                 |
| `setSupportedProtocol`                                | `CONFIG_OPERATOR_ROLE`                                 |
| Cross-chain vault and CCIP gas setters                | `CONFIG_OPERATOR_ROLE`                                 |
| `deposit`, `withdraw`, claims, and user cancellations | Public; disabled while paused                          |
| `forceCancelDeposit`                                  | `CANCEL_DEPOSIT_OPERATOR_ROLE`; available while paused |
| `closeEpoch`, `completeEpochDeposit`                  | `EPOCH_OPERATOR_ROLE`                                  |
| `initiateRebalance`, `completeRebalance`              | `REBALANCE_OPERATOR_ROLE`                              |
| `executeRecovery`                                     | Public; disabled while paused                          |
| `withdrawLink`                                        | `LINK_OPERATOR_ROLE`                                   |
| UUPS upgrade                                          | `UPGRADER_ROLE`                                        |

`closeEpoch`, `completeEpochDeposit`, `initiateRebalance`, and `completeRebalance` are all disabled
while ParentVault is paused. An in-progress operation can be finalized only after ParentVault is
deliberately unpaused following cross-chain state reconciliation. See
[`OPERATIONS`](../operator/OPERATIONS.md#paused-cross-chain-execution).

### ChildVault

| Function                               | Access                                           |
| -------------------------------------- | ------------------------------------------------ |
| Cross-chain vault and CCIP gas setters | `CONFIG_OPERATOR_ROLE`                           |
| `executeEpochWithdraw`                 | `EPOCH_OPERATOR_ROLE`; disabled while paused     |
| `executeRebalance`                     | `REBALANCE_OPERATOR_ROLE`; disabled while paused |
| `executeRecovery`                      | Public; disabled while paused                    |
| `withdrawLink`                         | `LINK_OPERATOR_ROLE`                             |
| UUPS upgrade                           | `UPGRADER_ROLE`                                  |

### WorkflowRouter

| Function                               | Access                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------- |
| `onReport`                             | `KEYSTONE_FORWARDER_ROLE`, registered workflow metadata, and allowlisted selector |
| Workflow metadata and selector setters | `CONFIG_OPERATOR_ROLE`                                                            |
| `pause`                                | `PAUSER_ROLE`                                                                     |
| `unpause`                              | `UNPAUSER_ROLE`                                                                   |

WorkflowRouter must also hold the role required by the forwarded vault function. Its selector
allowlist does not bypass vault access control.

### AdapterRegistry

| Function or authority                                                                    | Access                 |
| ---------------------------------------------------------------------------------------- | ---------------------- |
| Register or replace the adapter for a protocol ID with `setAdapter(protocolId, adapter)` | `CONFIG_OPERATOR_ROLE` |
| Remove a protocol by setting its adapter to `address(0)`                                 | `CONFIG_OPERATOR_ROLE` |
| Read the adapter registered for a protocol ID with `getAdapter(protocolId)`              | Public                 |

### Protocol Adapters

| Function                   | Access                                                      |
| -------------------------- | ----------------------------------------------------------- |
| `deposit`, `withdraw`      | Immutable bound vault only                                  |
| Compound v3 `claimRewards` | Caller must hold `REWARDS_OPERATOR_ROLE` on the bound vault |
| Read functions             | Public                                                      |

## Non-Role Trust Boundaries

| Boundary                        | Check                                                                                           |
| ------------------------------- | ----------------------------------------------------------------------------------------------- |
| Incoming CCIP message           | Called through the immutable CCIP router and sent by the registered vault for the source chain  |
| `BaseVault.tryDepositToAdapter` | External self-call only                                                                         |
| `ChildVault.tryCcipSend`        | External self-call only                                                                         |
| Recovery execution              | Uses stored recovery data; caller cannot choose the amount, recipient, strategy, or destination |

## Launch Configuration

The holders above are the initial launch configuration. Role separation, signer thresholds, and
holder assignments should be revisited if protocol TVL warrants stronger controls.

The deployer temporarily holds administration and configuration authority needed for wiring. The
scripts revoke temporary configuration roles and begin the two-step transfer to the configured
default admin. The configured admin must accept that transfer on-chain. The treasury receives
management-fee shares but has no authority solely by being configured as treasury.
