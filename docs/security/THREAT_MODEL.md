# Threat Model

This document summarizes the main threat surfaces for Yieldcoin v2 and the controls that bound them. It is intended as an auditor-facing map of what can go wrong and where to inspect the design. Accepted residual risks are tracked in [KNOWN_ISSUES](./KNOWN_ISSUES.md) and are referenced here instead of duplicated.

## 1. System scope

Yieldcoin v2 is a multichain yield vault. Users interact with `ParentVault` on the parent chain. Capital is deployed through protocol adapters either on the parent chain or on child chains through CCIP. Chainlink CRE drives epoch settlement and rebalancing through `WorkflowRouter`.

Primary assets at risk:

- Underlying asset held transiently in vaults or deployed through adapters.
- Yieldcoin share accounting in `ParentVault`.
- User ability to deposit, withdraw, claim, cancel, and transfer shares.
- Privileged control over workflow routing, adapters, pauses, upgrades, and temporary break-glass role grants.

## 2. Trust boundaries

- **External strategy protocols.** Active adapters place funds into third-party lending protocols. The protocol can validate adapter behavior, but cannot make an external market solvent or withdrawable.
- **Commercial operator roles.** Privileged roles configure protocol components and operate pause, recovery-escalation, and break-glass controls. See [KI-001](./KNOWN_ISSUES.md#ki-001--centralized-trust-in-privileged-operatoradmin-roles).
- **Underlying asset issuer.** The initial underlying asset is USDC, whose issuer can blacklist addresses or pause transfers. See [KI-002](./KNOWN_ISSUES.md#ki-002--underlying-asset-issuer-can-blacklist-or-pause-the-protocol).
- **CRE and WorkflowRouter.** CRE supplies trusted TVL inputs and workflow-triggered actions. `WorkflowRouter` is the on-chain ingress for Keystone Forwarder reports and validates workflow metadata and selector allowlists before dispatching to the vault.
- **CCIP.** CCIP transports messages and tokens between parent and child vaults. Vaults validate the decoded sender against the configured crosschain vault for the source chain selector.
- **Off-chain yield data.** The DefiLlama relay informs rebalance decisions, but does not directly write on-chain state. CRE and on-chain allowlists constrain what can be executed.

## 3. Main threat surfaces

### 3.1 Active strategy protocol failure

The largest direct economic threat is failure of the active external strategy protocol: exploit, insolvency, market pause, withdrawal failure, oracle/accounting failure inside the strategy, or loss of liquidity. In that case, funds already deployed through the adapter may be partially or fully unavailable.

Mitigations are necessarily limited:

- Only registered adapters bound to the expected vault can be activated.
- Rebalances can target only supported protocols and registered crosschain vaults.
- Adapters are `onlyVault`, use protocol-specific amount checks, and return withdrawn assets to the vault.
- Operators can pause affected vault/router paths and rebalance away from a compromised strategy only to the extent funds remain withdrawable.

Residual risk remains inherent to the product: Yieldcoin v2 cannot guarantee solvency or availability of a third-party lending protocol.

### 3.2 Privileged operator/admin compromise

A compromised privileged signer can misconfigure roles, workflow metadata/selectors, adapter mappings, supported protocols, pause controls, temporary break-glass authority, or upgrade authority within that role's scope. See [KI-001](./KNOWN_ISSUES.md#ki-001--centralized-trust-in-privileged-operatoradmin-roles).

Code-level mitigations include role separation, explicit role checks, `AccessControlDefaultAdminRules` on native components, narrow workflow ingress through `WorkflowRouter`, and adapter/vault binding checks.

### 3.3 CRE, TVL, and rebalance decision failure

`ParentVault.closeEpoch(tvl)` trusts the TVL supplied through CRE. An incorrect TVL can corrupt epoch settlement once users claim against the affected epoch. CRE liveness is also required for scheduled epoch close. See [KI-007](./KNOWN_ISSUES.md#ki-007--epoch-close-depends-on-cre-workflow-execution).

Rebalance decisions depend on off-chain yield data. A compromised relay or upstream data source can influence strategy selection, but cannot directly call contracts. On-chain controls still require a valid workflow report, allowlisted selector, supported protocol, registered adapter, and registered destination chain. Relay data-integrity risk is documented in [KI-011](./KNOWN_ISSUES.md#ki-011--compromised-defillama-api-or-relay-can-skew-rebalance-inputs), while relay resource-exhaustion residuals are documented in [KI-004](./KNOWN_ISSUES.md#ki-004--residual-cpumemory-dos-surface-in-defillama-relay-upstream-processing).

### 3.4 Underlying asset issuer controls

If the underlying asset issuer blacklists protocol addresses, strategy addresses, or pauses the token globally, deposits, withdrawals, claims, rebalances, or recovery can stop regardless of Yieldcoin v2 contract correctness. See [KI-002](./KNOWN_ISSUES.md#ki-002--underlying-asset-issuer-can-blacklist-or-pause-the-protocol).

### 3.5 CCIP message or delivery failure

Cross-chain flows depend on CCIP message authenticity, token delivery, and liveness. Vaults reject unexpected source vaults and unsupported message types, and validate received token shape before handling CCIP state transitions.

Child-side strategy and outbound CCIP failures store explicit recovery state where possible. Recovery execution is permissionless, consumes stored state, and does not let the caller choose arbitrary amounts, destinations, strategies, or recipients. Global CCIP liveness remains an external dependency.

### 3.6 Adapter correctness and registration

Adapters are the boundary between vault accounting and external protocol mechanics. A buggy or malicious registered adapter can report incorrect TVL, fail to withdraw, or interact incorrectly with the underlying strategy.

Mitigations include `onlyVault` adapter entry points, vault-bound adapter registration checks, supported-protocol checks for rebalances, protocol-specific withdraw amount validation, and invariant/test coverage for adapter registration and active-strategy consistency. Registered adapters remain a trusted component of the system.

### 3.7 Permissionless third-party supplies can influence strategy TVL

Supported lending markets allow a third party to supply underlying assets on behalf of an adapter. This increases the adapter's raw protocol balance and reported TVL without passing through the vault's deposit accounting. If CRE includes that balance when closing an epoch, the unsolicited supply can affect epoch pricing, shares minted to depositors, assets allocated to withdrawers, and fee accounting.

Epoch batching prevents the standard single-transaction flash-loan donation attack because the third party cannot withdraw funds credited to the adapter. A third party can nevertheless use real capital to influence accounting. Operators should monitor lending-market supply events that credit adapter addresses and alert on unexpected adapter TVL increases, then investigate unexplained changes before epoch close where operationally feasible.

See [KI-008](./KNOWN_ISSUES.md#ki-008--strategy-tvl-can-include-permissionless-third-party-supplies) for the full analysis, residual risk, and revisit conditions.

## 4. Verifiable controls

Auditors should verify these controls against code and tests:

- `WorkflowRouter.onReport` requires `KEYSTONE_FORWARDER_ROLE`, registered workflow metadata, and allowlisted selectors.
- Vault epoch/rebalance functions are callable only by `WorkflowRouter` through `EPOCH_OPERATOR_ROLE` or `REBALANCE_OPERATOR_ROLE`.
- CCIP receivers validate the source chain selector and decoded sender against registered crosschain vaults.
- Parent/local strategy failures revert atomically; child asynchronous failures store typed recovery state for retry.
- `executeRecovery()` is permissionless, requires an active recovery mode, and consumes only stored recovery state.
- Share minting and burning require roles held by `ParentVault`; pausing `YieldcoinShare` blocks transfers, minting, and burning while leaving approvals available.
- Adapters are registered, vault-bound, and callable only by their vault.
- UUPS upgrades are restricted by the configured upgrade authority.

## 5. Related documents

- [ARCHITECTURE](../protocol/ARCHITECTURE.md) — System overview and component relationships.
- [PATHS](../protocol/PATHS.md) — Full epoch and rebalance execution paths.
- [INVARIANTS](./INVARIANTS.md) — Protocol safety properties and test coverage.
- [ACCESS_CONTROL_MATRIX](./ACCESS_CONTROL_MATRIX.md) — Role meanings and privileged entry points.
- [KNOWN_ISSUES](./KNOWN_ISSUES.md) — Accepted residual risks and revisit conditions.
