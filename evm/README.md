# Yieldcoin v2 EVM

<!-- @review expand this document?  -->

## Recovery

All rebalance withdraw failures store withdraw recovery; all rebalance deposit failures store deposit recovery, regardless of whether the target is local or remote.

## WorkflowRouter-called selectors

These are the functions in the Vaults that are called by WorkflowRouters. We don't want them to clash.

// @review double check these

```
initiateRebalance((bytes32,uint64))                0x3d34b5e6
completeRebalance()                                0x1f02a47d
closeEpoch(uint256)                                0xd16d9057
executeRebalance(uint256,(bytes32,uint64))         0x1aa137ec
executeEpochWithdraw(uint256,uint256)              0x1c12f962
```
