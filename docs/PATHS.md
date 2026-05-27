**Yieldcoin V2**

**Canonical Execution Paths**

_All epoch and rebalance flows across parent and child strategy configurations_

The system has nine execution paths across two categories: epoch settlement and rebalance. Each path is determined by whether the active strategy is on Parent chain or on a Child chain, and the direction of net capital flow.

In local Parent paths, strategy interaction and CCIP send failures revert atomically.
In remote Child paths, strategy interaction and Child-originated CCIP send failures store explicit recovery state and emit failure/recovery events. Recovery functions retry the failed step.

# **Summary**

| **Path**                          | **CCIP sends** | **CRE executions** | **Settlement**                      |
| --------------------------------- | -------------- | ------------------ | ----------------------------------- |
| 1a Epoch, parent, net deposit     | 0              | 1                  | Fully synchronous                   |
| 1b Epoch, parent, net withdrawal  | 0              | 1                  | Fully synchronous                   |
| 2a Epoch, child, net deposit      | 1              | 1                  | Epoch claimable before CCIP settles |
| 2b Epoch, child, net withdrawal   | 1              | 2                  | Epoch claimable after CCIP settles  |
| 3a Rebalance, parent to parent    | 0              | 1                  | Fully synchronous                   |
| 3b Rebalance, parent to child     | 1              | 2                  | Completes asynchronously            |
| 4a Rebalance, Child to Parent     | 1              | 2                  | Finalises in Parent ccipReceive on success |
| 4b Rebalance, child to same Child | 0              | 3                  | Completes asynchronously            |
| 4c Rebalance, child A to child B  | 1              | 3                  | Completes asynchronously            |

# **Epoch Flows**

At epoch close, CRE reads TVL from the active strategy chain and writes it to Parent. Parent executes all financial calculations onchain in a single transaction. The location of the active strategy and the direction of net capital flow — deposits minus withdrawals in underlying asset terms — determines which path executes.

## **1a — Epoch, Parent Local Strategy, Net Deposit**

More deposits than withdrawals. Active strategy is on Parent chain.

- Users submit deposit and withdraw intents on Parent. USDC for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron triggers** closeEpoch(tvl) on Parent.

- Parent calculates pricePerShare, newShares, totalWithdrawUsdc, netFlow.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow > 0**: epoch → CLAIMABLE. Next epoch opens.

- \_executeDeposit(netFlow, true) directly to local active adapter. Reverts on failure.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimUsdc() on Parent. Escrowed Yieldcoin burned, USDC transferred.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **1b — Epoch, Parent Local Strategy, Net Withdrawal**

More withdrawals than deposits. Active strategy is on Parent chain.

- Users submit deposit and withdraw intents on Parent. USDC for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron triggers** closeEpoch(tvl) on Parent.

- Parent calculates pricePerShare, newShares, totalWithdrawUsdc, netFlow.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow < 0**: \_executeWithdraw(netWithdrawAmount, true) directly from local active adapter. Reverts on failure.

- Epoch → CLAIMABLE. Next epoch opens.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimUsdc() on Parent. Escrowed Yieldcoin burned, USDC transferred.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **2a — Epoch, Child Strategy, Net Deposit**

More deposits than withdrawals. Active strategy is on a Child chain.

- Users submit deposit and withdraw intents on Parent. USDC for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron triggers** closeEpoch(tvl) on Parent.

- Parent calculates pricePerShare, newShares, totalWithdrawUsdc, netFlow.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow > 0**: epoch → CLAIMABLE. Next epoch opens.

- Parent **\_ccipSend**(netFlow, strategyChain, DEPOSIT, epochNonce).

- Child \_handleCCIPDeposit() → \_executeDeposit(amount, false). Emits DepositToStrategySuccess on success. On failure, stores epoch deposit recovery and emits DepositToStrategyFailure; recovery calls recoverFailedEpochDeposit().

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimUsdc() on Parent. Escrowed Yieldcoin burned, USDC transferred.

**CCIP sends: 1**

**CRE executions: 1**

**_Epoch claimable before CCIP settles_**

## **2b — Epoch, Child Strategy, Net Withdrawal**

More withdrawals than deposits. Active strategy is on a Child chain.

- Users submit deposit and withdraw intents on Parent. USDC for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron triggers** closeEpoch(tvl) on Parent.

- Parent calculates pricePerShare, newShares, totalWithdrawUsdc, netFlow.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow < 0**: epoch → EXECUTING. Next epoch opens. Emits EpochExecuting(epochNonce, netWithdrawAmount).

- **CRE log trigger** (EpochExecuting) → child.executeEpochWithdraw(epochNonce, netWithdrawAmount).

- Child \_executeWithdraw(amount, false). Emits WithdrawFromStrategySuccess on success. On failure, stores epoch withdraw recovery and emits WithdrawFromStrategyFailure; recovery calls recoverFailedEpochWithdraw().

- On success: child **\_ccipSend**(amountOut, parentChain, WITHDRAW, epochNonce).

- If Child CCIP send fails, stores CCIP send recovery; recovery calls recoverFailedCcipSend().

- Parent receives EPOCH_NET_WITHDRAW, updates withdraw claim amount from actual received USDC, emits EpochWithdrawAmountShort if under expected amount, then \_finalizeEpoch(epochNonce) → epoch → CLAIMABLE.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimUsdc() on Parent. Escrowed Yieldcoin burned, USDC transferred.

**CCIP sends: 1**

**CRE executions: 2**

**_Epoch claimable after CCIP settles_**

# **Rebalance Flows**

Rebalance migrates the protocol's position from the current active strategy to a new one. It only initiates when s_rebalance.state == NONE, no recovery is pending, no prior epoch is EXECUTING, and the requested strategy is not the active strategy. All paths complete by calling \_finalizeRebalance(), which updates activeStrategy, resets state to NONE, increments the rebalance nonce, records lastRebalanceTimestamp, and mints any management fee.

CRE monitors RebalanceDepositSuccess events on the receiving chain and calls completeRebalance() on Parent to finalize — except for the local-to-local path (synchronous) and the remote-Child-to-Parent success path (finalized inside Parent ccipReceive).

## **3a — Rebalance, Parent Local to Local**

Both old and new strategy are on Parent chain. Different protocols.

- **CRE cron triggers** parent.initiateRebalance(newStrategy).

- Guards: state == NONE, no recovery pending, no prior epoch EXECUTING, new strategy differs from active strategy.

- state → REBALANCING. Emits RebalanceInitiated.

- \_executeWithdraw(max, true) from old local active adapter. Reverts on failure.

- Emits RebalanceWithdrawSuccess.

- \_setActiveAdapter(newStrategy.protocolId).

- \_executeDeposit(amountOut, true) into new local active adapter. Reverts on failure.

- Emits RebalanceDepositSuccess.

- \_finalizeRebalance() → activeStrategy = newStrategy, s_rebalance.nonce++, state → NONE, lastRebalanceTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **3b — Rebalance, Parent Local to Child Remote**

Old strategy on Parent, new strategy on a Child chain.

- **CRE cron triggers** parent.initiateRebalance(newStrategy).

- Guards: state == NONE, no recovery pending, no prior epoch EXECUTING, new strategy differs from active strategy.

- state → REBALANCING. Emits RebalanceInitiated.

- \_executeWithdraw(max, true) from local Aave adapter. Reverts on failure.

- Emits RebalanceWithdrawSuccess.

- s_activeProtocolAdapter = address(0) — Parent is no longer active strategy.

- **\_ccipSend**(amountOut, newStrategy.chainSelector, REBALANCE, rebalanceNonce, newStrategy.protocolId).

- Child \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; recovery calls recoverFailedRebalanceDeposit().

- **CRE log trigger** (RebalanceDepositSuccess) → parent.completeRebalance(rebalanceNonce).

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 2**

**_Completes asynchronously_**

## **4a — Rebalance, Child to Parent**

Old strategy on a Child chain, new strategy on Parent chain.

- **CRE cron triggers** parent.initiateRebalance(newStrategy).

- Guards: state == NONE, no recovery pending, no prior epoch EXECUTING, new strategy differs from active strategy.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → child.executeRebalance(rebalanceNonce, newStrategy) on old strategy Child.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; recovery calls recoverFailedRebalanceWithdraw().

- s_activeProtocolAdapter = address(0) on old Child.

- **\_ccipSend**(amountOut, parentChain, REBALANCE, rebalanceNonce, newStrategy.protocolId).

- If Child CCIP send fails, stores CCIP send recovery; recovery calls recoverFailedCcipSend().

- Parent \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; recovery calls recoverFailedRebalanceDeposit(), which finalizes the rebalance after a successful retry.

- On immediate deposit success, Parent ccipReceive calls \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, lastRebalanceTimestamp updated, s_rebalance.nonce++, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 2**

**_Finalizes in Parent ccipReceive on success_**

## **4b — Rebalance, Child to Same Local Child**

Old and new strategy are both locally on the same Child chain. Different protocols.

- **CRE cron triggers** parent.initiateRebalance(newStrategy).

- Guards: state == NONE, no recovery pending, no prior epoch EXECUTING, new strategy differs from active strategy.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → child.executeRebalance(rebalanceNonce, newStrategy) on Child.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; recovery calls recoverFailedRebalanceWithdraw().

- newStrategy.chainSelector == i_thisChainSelector → local deposit on same Child.

- \_setActiveAdapter(newStrategy.protocolId).

- \_executeDeposit(amountOut, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; recovery calls recoverFailedRebalanceDeposit().

- **CRE log trigger** (RebalanceDepositSuccess) → parent.completeRebalance(rebalanceNonce).

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 0**

**CRE executions: 3**

**_Completes asynchronously_**

## **4c — Rebalance, Child A to Remote Child B**

Old strategy on one Child A chain, new strategy on a different Child B chain.

- **CRE cron triggers** parent.initiateRebalance(newStrategy).

- Guards: state == NONE, no recovery pending, no prior epoch EXECUTING, new strategy differs from active strategy.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → childA.executeRebalance(rebalanceNonce, newStrategy) on old strategy Child A.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; recovery calls recoverFailedRebalanceWithdraw().

- s_activeProtocolAdapter = address(0) on old Child A.

- **\_ccipSend**(amountOut, newStrategy.chainSelector, REBALANCE, rebalanceNonce, newStrategy.protocolId). Old Child A sends directly to new Child B. If Child CCIP send fails, stores CCIP send recovery; recovery calls recoverFailedCcipSend().

- New Child B \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; recovery calls recoverFailedRebalanceDeposit().

- **CRE log trigger** (RebalanceDepositSuccess) → parent.completeRebalance(rebalanceNonce).

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 3**

**_Completes asynchronously_**

_Yieldcoin V2 · Canonical Execution Paths_
