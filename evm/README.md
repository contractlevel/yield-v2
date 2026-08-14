# Yieldcoin v2 EVM

<!-- @review expand this document?  -->

## Recovery

Recovery depends on where an operation executes. Synchronous ParentVault strategy interactions and
Parent-originated CCIP sends revert atomically on failure and do not store recovery state. Failures
after an asynchronous operation reaches a ChildVault store typed recovery state where possible.
ParentVault stores `REBALANCE_DEPOSIT` recovery only when an inbound cross-chain rebalance has
already delivered assets to ParentVault and depositing them into the new local strategy fails.

See [`docs/concepts/RECOVERY.md`](../docs/concepts/RECOVERY.md) for the recovery model and
[`docs/protocol/PATHS.md`](../docs/protocol/PATHS.md) for the individual execution paths.

## WorkflowRouter-called selectors

These are the functions in the Vaults that are called by WorkflowRouters. We don't want them to clash.

// @review double check these

```
initiateRebalance(uint256,(bytes32,uint64))        0x3ba1b347
completeRebalance(uint256)                         0x58b275bc
closeEpoch(uint256,uint256)                        0xf5591e6e
completeEpochDeposit(uint256)                      0x37129c0b
executeRebalance(uint256,(bytes32,uint64))         0x1aa137ec
executeEpochWithdraw(uint256,uint256)              0x1c12f962
```

## Proxies

```
cast index-erc7201 yieldcoin.storage.BaseVault && cast index-erc7201 yieldcoin.storage.ParentVault && cast index-erc7201 yieldcoin.storage.ChildVault
0x99afdd01627a14a05f9b616b4e511b7ffe10b226156d7b6f476c4380e58f9d00
0x4d89b729d7d5f9a6740a79abcbedc524fd1c9bd2e1f192f6caeffd6a1cf4ea00
0x78e4dbdeeaf798c2dd37013d97b7b9a2111b1f613652054109dec720ccf6f400
```
