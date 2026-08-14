# Upgrades

This runbook covers UUPS upgrades of `ParentVault`, `ChildVault`, and `YieldcoinShare`. Production upgrades must be executed through the protocol operator's OpenZeppelin `TimelockController`.

The timelock must hold `UPGRADER_ROLE` on each vault and on `YieldcoinShare`. `YieldcoinShare` uses
role-based access control rather than ownership; its default-admin authority is separate from
`UPGRADER_ROLE`. These authorities must not be assigned to a routine operator wallet.

## 1. Prepare

- Define the reason, scope, expected state changes, and affected deployments.
- Review every contract and dependency changed by the release.
- Require an independent security review for material logic or storage changes. Apply review proportionate to risk for smaller changes.
- Confirm the new implementation preserves the required UUPS interface and upgrade authorization.
- Record the release commit and reproducible build inputs.

## 2. Validate

- Validate storage-layout compatibility against the currently deployed implementation.
- Confirm ERC-7201 storage namespaces have not changed or collided.
- Confirm the new implementation's immutable asset, router, registry, chain selector, share token, and parent selector values match the target proxy.
- Confirm implementation contracts cannot be initialized directly.
- Do not call the original initializer again. An upgrade must preserve the state already initialized and subsequently updated through the proxy, including roles or ownership, configuration, accounting, pause state, and lifecycle state.
- In particular, do not reset ParentVault epoch or rebalance nonces to `1`, reopen an initialized epoch, reset completion timestamps, clear recovery state, or reset ChildVault handled-nonce high-water marks.
- Any migration call must be explicit, idempotent where practical, and separately reviewed. It may change existing state only when that change is part of the approved migration.
- Test the complete timelock proposal and execution against a fork of every affected chain.

Fork tests must confirm that roles or ownership, pause state, configuration, epoch and share accounting, rebalance state, recovery state, and child nonce high-water marks remain correct.

## 3. Execute

1. Deploy and verify the new implementation.
2. Reconfirm its bytecode, immutable values, storage-layout report, and target proxy.
3. Schedule the exact upgrade call through the production `TimelockController`.
4. Publish or internally circulate the scheduled operation for the required review period.
5. Recheck protocol and cross-chain state before execution.
6. Execute the timelocked upgrade with the approved operator signers.

Do not combine unrelated upgrades or configuration changes in the same operation.

## 4. Verify

- Confirm the proxy points to the intended verified implementation.
- Confirm the expected upgrade event and transaction status.
- Recheck all state covered by the fork tests.
- Run read-only and low-risk checks before restoring normal operation.
- Monitor the first epoch, rebalance, token operation, and cross-chain flow affected by the release.

Record the implementation address, target proxies, release commit, review evidence, storage-layout result, timelock operation, execution transaction, verification results, and final approval in the environment-specific upgrade record.

If verification fails, stop automation and pause affected components where appropriate. Do not re-run an initializer or attempt an unreviewed migration. Prepare and test a corrective implementation through the same upgrade process.
