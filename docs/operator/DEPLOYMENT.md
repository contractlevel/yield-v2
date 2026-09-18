# Deployment

This runbook covers testnet and production deployments. Run EVM commands from `evm/`. Keep deployed addresses, role holders, transaction hashes, and approvals in environment-specific deployment records rather than this document.

## Prerequisites

- Configure the required RPC URLs without committing secrets.
- Configure a Foundry keystore account for the deployer.
- Fund the deployer with native gas tokens on every target chain.
- Review the network values in `script/HelperConfig.s.sol`.
- Confirm the intended parent chain, child chains, underlying asset, protocols, role holders, and treasury.

The shared actor section in `script/HelperConfig.s.sol` defines `DEFAULT_ADMIN`, `UPGRADER`, `OPERATOR`, and `INITIAL_USER` for mainnet and testnet. Treasury fees go to `OPERATOR`. The parent allowlist is enabled with `INITIAL_USER` as its sole initial member.

Base hosts the parent; Ethereum, Avalanche, Arbitrum, Optimism, and Polygon host children. Testnets use the corresponding testnet configurations. The deployer is a separate keystore address. Pass `--sender <deployer_address>` with `--account` so the script's `msg.sender` matches the signer.

## Deploy

Deploy the parent-chain vault, share token, seed lock, adapters, registry, and workflow router:

```bash
forge script script/deploy/DeployParent.s.sol:DeployParent \
    --rpc-url <parent_rpc> \
    --account <deployer_account> \
    --broadcast \
    --verify
```

Deploy the child-chain contracts once on each child chain:

```bash
forge script script/deploy/DeployChild.s.sol:DeployChild \
    --rpc-url <child_rpc> \
    --account <deployer_account> \
    --broadcast \
    --verify
```

For current testnet commands and deployment records, see [`TESTNET`](../test/TESTNET.md).

## Configure

Both the operator and deployer retain `CONFIG_OPERATOR_ROLE` on every vault and WorkflowRouter. The deployer can run `SetCrosschainVaults.s.sol` and `ConfigureWorkflowRouter.s.sol` with the same keystore and `--sender`, without another role grant. Registry and share-token configuration belong to the operator; the separate deployer's temporary registry config access is removed during deployment.

The interaction scripts read `deployed.vaultProxy` and `deployed.workflowRouter` from each network's `HelperConfig` entry. `SetCrosschainVaults.s.sol` covers all six testnets and runs once per chain. Its network list is testnet-specific.

After all vaults are deployed:

1. Register the trusted cross-chain vaults with `SetCrosschainVaults.s.sol` on every chain.
2. Deploy the DefiLlama relay with a fresh bearer token.
3. Populate and validate the CRE environment configuration.
4. Prepare and validate the CRE workflow deployment, which generates the signed report envelope containing the target chain selector, target router address, observation timestamp, and vault calldata, but do not activate it yet.
5. Configure each WorkflowRouter with `ConfigureWorkflowRouter.s.sol`.
6. Fund every vault with sufficient LINK for CCIP.
7. Assign production roles to their approved holders and remove temporary deployer access.

Use [`CONFIG`](./CONFIG.md) for configuration functions and [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md) for required authorities.

## Accept the admin handoff

The scripts start admin transfers but do not complete them. The configured `DEFAULT_ADMIN` must call `acceptDefaultAdminTransfer()` on:

- Parent chain: ParentVault proxy, YieldcoinShare proxy, AdapterRegistry, and WorkflowRouter.
- Each child chain: ChildVault proxy, AdapterRegistry, and WorkflowRouter.

All these contracts have a zero initial admin-transfer delay. Accept in a later transaction once the acceptance timestamp returned by `pendingDefaultAdmin()` has passed. Until acceptance, the deployer remains default admin on that contract. No transfer is started if the deployer is already the configured default admin.

Admin acceptance does not remove deployer config access. After configuration, manually remove the deployer's `CONFIG_OPERATOR_ROLE` from every vault and WorkflowRouter: the deployer can call `renounceRole(role, deployer)`, or the current default admin can call `revokeRole(role, deployer)`. Keep the operator's config role.

## Bootstrap the parent vault

Complete the permanent seed before normal protocol operation:

1. Deposit at least 100 USDC into the ParentVault's first epoch.
2. Activate the CRE workflow and let it close the first epoch.
3. Manually claim the resulting shares.
4. Transfer all shares from the seed deposit to the `YieldcoinShareSeedLock` deployed by `DeployParent.s.sol`. The lock has no functions, owner, or upgrade path, so its shares cannot be transferred or withdrawn.
5. Verify `ParentVault.getTotalShares()` and the lock's share-token balance are each at least `100e18`.

Record the deposit, epoch close, claim, transfer, lock address, and final balances in the deployment record. Do not treat the vault as launched until the locked seed position is verified. See [`KI-010`](../security/KNOWN_ISSUES.md#ki-010--bootstrap-share-allocation-ignores-residual-tvl-when-total-shares-return-to-zero) and [`KI-024`](../security/KNOWN_ISSUES.md#ki-024--unseeded-bootstrap-allows-adapter-donation-and-claim-ordering-to-redirect-depositor-principal).

## Verify

Before handoff:

- Confirm every proxy points to the intended verified implementation.
- Confirm immutable constructor values and proxy initialization values match the deployment record, including each WorkflowRouter's vault-derived nonzero chain selector.
- Confirm adapters are registered for the correct vault, asset, and protocol.
- Confirm cross-chain vault mappings and CCIP gas limits on every chain.
- Confirm WorkflowRouter metadata and selector allowlists, and verify a freshly generated report is accepted only by its configured chain and router.
- Confirm role assignments created by the parent deployment, including that `ParentVault` holds the share token's minter and burner roles.
- Confirm the `YieldcoinShareSeedLock` address, bytecode, and permanent seed-share balance.
- Confirm vault LINK balances and CRE secrets without exposing secret values.
- Run the applicable deployment and fork tests.

Record the deployed addresses, configuration transactions, verification links, role assignments, workflow identity, and final approval in the environment-specific deployment record before handing the deployment to operations.
