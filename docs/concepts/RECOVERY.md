# Recovery

Recovery is the protocol's stored-state retry mechanism for operations the system already accepted and attempted to execute.

Recovery is permissionless. Anyone can monitor for recovery state and call the relevant recovery path when the external failure condition has cleared. There is no recovery operator role because recovery callers do not provide input.

The failed operation stores the recovery state. A recovery call can only consume that stored state and retry the intended operation. If the retry fails, the recovery state remains available for a later attempt. If the retry succeeds, the recovery state is cleared and the protocol advances the original operation.

## Parent and Child Recovery

On [`ParentVault`](../../evm/src/vaults/ParentVault.sol), the only active recovery mode is `REBALANCE_DEPOSIT`. This can happen when the parent chain receives funds from a cross-chain rebalance and then fails to deposit those funds into the new parent-chain strategy. The cross-chain transfer has already completed, so the parent stores recovery state and retries the deposit later.

Other parent-chain failures generally revert atomically. In those cases, no cross-chain state has escaped and the transaction can leave clean state without storing recovery.

On [`ChildVault`](../../evm/src/vaults/ChildVault.sol), more recovery modes are needed because the child is acting after cross-chain epoch or rebalance state already exists. At that point the original parent-chain action cannot be cleanly reverted, so failed child strategy deposits, child strategy withdraws, rebalance withdraws, and child-originated CCIP sends store recovery state for retry.

## Monitoring And Execution

Each vault exposes `getRecoveryMode()`.

- If it returns `RecoveryMode.NONE`, no recovery is active on that vault.
- If it returns any other `RecoveryMode`, recovery is active and should be executed when conditions allow.

Recovery is executed by calling `executeRecovery()` on the vault with the active recovery mode. The function reverts when no recovery is pending and is deliberately permissionless so anyone can advance recovery state.

Recovery can exist on any parent or child vault. Monitoring should check every deployed vault on every supported chain.

While recovery is active, normal protocol progress is constrained. Epoch and rebalance flows check for pending recovery and cannot continue through paths that require clean recovery state. The recovery should be executed first, then the blocked epoch or rebalance flow can continue.

## Further Reading

For exact recovery paths, see [`PATHS`](../protocol/PATHS.md). For recovery authority rules, see [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#vault-recovery). For recovery invariants, see [`INVARIANTS`](../security/INVARIANTS.md#recovery).
