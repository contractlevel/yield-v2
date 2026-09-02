**Yieldcoin V2**

**Canonical Execution Paths**

_All epoch and rebalance flows across parent and child strategy configurations_

The system has nine positive- or negative-flow execution paths across two categories: epoch settlement
and rebalance, plus the shared zero-net-flow epoch case described below. Each directional path is
determined by whether the active strategy is on Parent chain or on a Child chain, and the direction of
net capital flow.

In local Parent paths, strategy interaction and CCIP send failures revert atomically.
In remote Child paths, strategy interaction and most Child-originated CCIP send failures store explicit recovery state and emit failure/recovery events. Recovery functions retry the failed step. A CCIP token-pool capacity-ceiling failure reverts the Child operation atomically instead of storing an identically replayable send.

# **Summary**

| **Path**                          | **CCIP sends** | **CRE executions** | **Settlement**                             |
| --------------------------------- | -------------- | ------------------ | ------------------------------------------ |
| 1a Epoch, parent, net deposit     | 0              | 1                  | Fully synchronous                          |
| 1b Epoch, parent, net withdrawal  | 0              | 1                  | Fully synchronous                          |
| 2a Epoch, child, net deposit      | 1              | 2                  | Epoch claimable after remote settlement confirmation |
| 2b Epoch, child, net withdrawal   | 0 or 1         | 1 or 2             | Dust settles on Parent; larger shortfalls settle after CCIP |
| 3a Rebalance, parent to parent    | 0              | 1                  | Fully synchronous                          |
| 3b Rebalance, parent to child     | 1              | 2                  | Completes asynchronously                   |
| 4a Rebalance, Child to Parent     | 1              | 2                  | Finalises in Parent ccipReceive on success |
| 4b Rebalance, child to same Child | 0              | 3                  | Completes asynchronously                   |
| 4c Rebalance, child A to child B  | 1              | 3                  | Completes asynchronously                   |

# **Epoch Flows**

At epoch close, CRE reads TVL from the active strategy chain and writes it to Parent. Parent executes all financial calculations onchain in a single transaction. The location of the active strategy and the direction of net capital flow — deposits minus withdrawals in underlying asset terms — determines which path executes.

### **Zero Net Flow — Any Strategy Location**

When deposits exactly equal withdrawal entitlements in underlying-asset terms, Parent updates epoch
and authoritative share accounting, marks the epoch `CLAIMABLE`, emits `EpochClaimable`, and opens
the next epoch. No adapter interaction or CCIP send is required, regardless of whether the active
strategy is on the parent chain or a child chain.

## **1a — Epoch, Parent Local Strategy, Net Deposit**

More deposits than withdrawals. Active strategy is on Parent chain.

- Users submit deposit and withdraw intents on Parent. Underlying asset for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron reads** the current parent epoch nonce and active-strategy TVL, then triggers `closeEpoch(expectedEpochNonce, tvl)` on Parent.

- Parent calculates `newShares` and `totalWithdraw` directly from TVL and authoritative shares, then calculates `netFlow`.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow > 0**: epoch → CLAIMABLE. Emits EpochClaimable(epochNonce). The local adapter deposit
  executes synchronously in the same transaction, and the next epoch opens only if that deposit succeeds.

- \_executeDeposit(netFlow, true) directly to local active adapter. Reverts on failure.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimAsset() on Parent. Escrowed Yieldcoin burned, asset transferred.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **1b — Epoch, Parent Local Strategy, Net Withdrawal**

More withdrawals than deposits. Active strategy is on Parent chain.

- Users submit deposit and withdraw intents on Parent. Underlying asset for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron reads** the current parent epoch nonce and active-strategy TVL, then triggers `closeEpoch(expectedEpochNonce, tvl)` on Parent.

- Parent calculates `newShares` and `totalWithdraw` directly from TVL and authoritative shares, then calculates `netFlow`.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow < 0**: \_executeWithdraw(netWithdrawAmount, true) directly from local active adapter. Reverts on failure.

- Epoch → CLAIMABLE. Next epoch opens.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimAsset() on Parent. Escrowed Yieldcoin burned, asset transferred.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **2a — Epoch, Child Strategy, Net Deposit**

More deposits than withdrawals. Active strategy is on a Child chain.

- Users submit deposit and withdraw intents on Parent. Underlying asset for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron reads** the current parent epoch nonce and active-strategy TVL, then triggers `closeEpoch(expectedEpochNonce, tvl)` on Parent.

- Parent calculates `newShares` and `totalWithdraw` directly from TVL and authoritative shares, then calculates `netFlow`.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow > 0**: epoch → EXECUTING. Next epoch opens. The closed epoch remains
  `EXECUTING` until the destination ChildVault deposits the assets and ParentVault accepts
  `completeEpochDeposit(expectedEpochNonce, actualDepositAmount)`.

- Parent **\_ccipSend**(netFlow, strategyChain, DEPOSIT, epochNonce).

- Child \_handleCCIPDeposit() → \_executeDeposit(amount, false). Emits EpochDepositToStrategySuccess on success. On failure, stores epoch deposit recovery and emits EpochDepositToStrategyFailure; `executeRecovery()` retries the stored deposit.

- **CRE log trigger** (EpochDepositToStrategySuccess from the destination ChildVault) → call `Parent.completeEpochDeposit(expectedEpochNonce, actualDepositAmount)` with the event's epoch nonce and amount.

- Parent verifies the most recently closed epoch is a positive-net-flow EXECUTING epoch and the actual amount is nonzero and no greater than the expected net deposit. A shortfall reduces that epoch's pending depositor shares and authoritative total shares before Parent emits `EpochDepositReconciled`, transitions the epoch to CLAIMABLE, and emits `EpochClaimable`.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimAsset() on Parent. Escrowed Yieldcoin burned, asset transferred.

**CCIP sends: 1**

**CRE executions: 2**

**_Epoch claimable after remote deposit settlement confirmation_**

## **2b — Epoch, Child Strategy, Net Withdrawal**

More withdrawals than deposits. Active strategy is on a Child chain.

- Users submit deposit and withdraw intents on Parent. Underlying asset for deposits and Yieldcoin for withdraws escrowed on Parent.

- **CRE cron reads** the current parent epoch nonce and active-strategy TVL, then triggers `closeEpoch(expectedEpochNonce, tvl)` on Parent.

- Parent calculates `newShares` and `totalWithdraw` directly from TVL and authoritative shares, then calculates `netFlow`.

- Parent updates totalShares: += newShares, -= totalShareBurnAmount.

- **netFlow < 0 and netWithdrawAmount < getRemoteWithdrawDustThreshold()**: Parent sends no Child request, emits `RemoteWithdrawDustForfeited`, makes the epoch immediately `CLAIMABLE`, and opens the next epoch. The withdraw claim pool contains only that epoch's deposits already held on Parent.

- **netFlow < 0 and netWithdrawAmount >= getRemoteWithdrawDustThreshold()**: epoch → EXECUTING. Next epoch opens. Emits EpochWithdrawExecuting(epochNonce, netWithdrawAmount).

- **CRE log trigger** (EpochWithdrawExecuting) → child.executeEpochWithdraw(epochNonce, netWithdrawAmount).

- Child \_executeWithdraw(amount, false). Emits EpochWithdrawFromStrategySuccess on success. On failure, stores epoch withdraw recovery and emits EpochWithdrawFromStrategyFailure; `executeRecovery()` retries the stored withdrawal.

- On success: child **\_ccipSend**(amountOut, parentChain, WITHDRAW, epochNonce).

- If the Child CCIP send exceeds the token-pool capacity, the Child call reverts atomically so the original workflow operation can be retried. Other send-attempt failures store CCIP send recovery; `executeRecovery()` retries the stored send.

- Parent receives EPOCH_NET_WITHDRAW, verifies that the provisional epoch accounting is a net withdrawal, updates the withdraw claim pool to Parent-held deposits plus the complete amount delivered through CCIP, emits EpochWithdrawAmountShort if the received amount is under the full requested shortfall, and finalizes the epoch as `CLAIMABLE`.

- Depositors call claimShares() on Parent. Yieldcoin minted.

- Withdrawers call claimAsset() on Parent. Escrowed Yieldcoin burned, asset transferred.

**CCIP sends: 0 below the service threshold; 1 at or above it**

**CRE executions: 1 below the service threshold; 2 at or above it**

**_Dust is claimable at close; a larger shortfall is claimable after CCIP settles_**

# **Rebalance Flows**

Rebalance migrates the protocol's position from the current active strategy to a new one. It only initiates when s_rebalance.state == NONE, no recovery is pending, no prior epoch is EXECUTING, and the requested strategy is not the active strategy. All paths complete by calling \_finalizeRebalance(), which updates activeStrategy, resets state to NONE, increments the rebalance nonce, records lastRebalanceCompletedTimestamp, and mints any management fee.

CRE monitors RebalanceDepositSuccess events on the receiving chain and calls `completeRebalance(expectedRebalanceNonce)` on Parent with the event's rebalance nonce to finalize — except for the local-to-local path (synchronous) and the remote-Child-to-Parent success path (finalized inside Parent ccipReceive).

## **3a — Rebalance, Parent Local to Local**

Both old and new strategy are on Parent chain. Different protocols.

- **CRE cron reads** the current parent rebalance nonce and triggers `parent.initiateRebalance(expectedRebalanceNonce, newStrategy)`.

- Guards: no recovery pending, expected rebalance nonce matches, state == NONE, MIN_REBALANCE_PERIOD cooldown elapsed since the last completed rebalance, new strategy differs from active strategy, target chain is a supported chain, target protocol is a supported protocol, at least one epoch has already completed, no prior epoch EXECUTING.

- Emits RebalanceInitiated. Because this path completes atomically, Parent does not persist
  `state = REBALANCING` or `pendingStrategy`.

- \_executeWithdraw(max, true) from old local active adapter. Reverts on failure.

- Emits RebalanceWithdrawSuccess.

- \_setActiveAdapter(newStrategy.protocolId).

- \_executeDeposit(amountOut, true) into new local active adapter. Reverts on failure.

- Emits RebalanceDepositSuccess.

- \_finalizeRebalance() → activeStrategy = newStrategy, s_rebalance.nonce++,
  lastRebalanceCompletedTimestamp updated, management fee minted. There is no persisted rebalance
  state or pending strategy to clear. Emits RebalanceCompleted.

**CCIP sends: 0**

**CRE executions: 1**

**_Fully synchronous_**

## **3b — Rebalance, Parent Local to Child Remote**

Old strategy on Parent, new strategy on a Child chain.

- **CRE cron reads** the current parent rebalance nonce and triggers `parent.initiateRebalance(expectedRebalanceNonce, newStrategy)`.

- Guards: no recovery pending, expected rebalance nonce matches, state == NONE, MIN_REBALANCE_PERIOD cooldown elapsed since the last completed rebalance, new strategy differs from active strategy, target chain is a supported chain, target protocol is a supported protocol, at least one epoch has already completed, no prior epoch EXECUTING.

- state → REBALANCING. Emits RebalanceInitiated.

- \_executeWithdraw(max, true) from the local active adapter. Reverts on failure.

- Emits RebalanceWithdrawSuccess.

- s_activeProtocolAdapter = address(0) — Parent is no longer active strategy.

- **\_ccipSend**(amountOut, newStrategy.chainSelector, REBALANCE, rebalanceNonce, newStrategy.protocolId).

- Child \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; `executeRecovery()` retries the stored deposit.

- **CRE log trigger** (RebalanceDepositSuccess) → call `parent.completeRebalance(expectedRebalanceNonce)` with the event's rebalance nonce.

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceCompletedTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 2**

**_Completes asynchronously_**

## **4a — Rebalance, Child to Parent**

Old strategy on a Child chain, new strategy on Parent chain.

- **CRE cron reads** the current parent rebalance nonce and triggers `parent.initiateRebalance(expectedRebalanceNonce, newStrategy)`.

- Guards: no recovery pending, expected rebalance nonce matches, state == NONE, MIN_REBALANCE_PERIOD cooldown elapsed since the last completed rebalance, new strategy differs from active strategy, target chain is a supported chain, target protocol is a supported protocol, at least one epoch has already completed, no prior epoch EXECUTING.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → child.executeRebalance(rebalanceNonce, newStrategy) on old strategy Child.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; `executeRecovery()` retries the stored withdrawal.

- s_activeProtocolAdapter = address(0) on old Child.

- **\_ccipSend**(amountOut, parentChain, REBALANCE, rebalanceNonce, newStrategy.protocolId).

- If the Child CCIP send exceeds the token-pool capacity, the Child call reverts atomically so the original workflow operation can be retried. Other send-attempt failures store CCIP send recovery; `executeRecovery()` retries the stored send.

- Parent \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; `executeRecovery()` retries the stored deposit and finalizes the rebalance after success.

- On immediate deposit success, Parent ccipReceive calls \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, lastRebalanceCompletedTimestamp updated, s_rebalance.nonce++, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 2**

**_Finalizes in Parent ccipReceive on success_**

## **4b — Rebalance, Child to Same Local Child**

Old and new strategy are both locally on the same Child chain. Different protocols.

- **CRE cron reads** the current parent rebalance nonce and triggers `parent.initiateRebalance(expectedRebalanceNonce, newStrategy)`.

- Guards: no recovery pending, expected rebalance nonce matches, state == NONE, MIN_REBALANCE_PERIOD cooldown elapsed since the last completed rebalance, new strategy differs from active strategy, target chain is a supported chain, target protocol is a supported protocol, at least one epoch has already completed, no prior epoch EXECUTING.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → child.executeRebalance(rebalanceNonce, newStrategy) on Child.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; `executeRecovery()` retries the stored withdrawal.

- newStrategy.chainSelector == i_thisChainSelector → local deposit on same Child.

- \_setActiveAdapter(newStrategy.protocolId).

- \_executeDeposit(amountOut, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; `executeRecovery()` retries the stored deposit.

- **CRE log trigger** (RebalanceDepositSuccess) → call `parent.completeRebalance(expectedRebalanceNonce)` with the event's rebalance nonce.

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceCompletedTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 0**

**CRE executions: 3**

**_Completes asynchronously_**

## **4c — Rebalance, Child A to Remote Child B**

Old strategy on one Child A chain, new strategy on a different Child B chain.

- **CRE cron reads** the current parent rebalance nonce and triggers `parent.initiateRebalance(expectedRebalanceNonce, newStrategy)`.

- Guards: no recovery pending, expected rebalance nonce matches, state == NONE, MIN_REBALANCE_PERIOD cooldown elapsed since the last completed rebalance, new strategy differs from active strategy, target chain is a supported chain, target protocol is a supported protocol, at least one epoch has already completed, no prior epoch EXECUTING.

- state → REBALANCING. Emits RebalanceInitiated.

- No further local parent action — old strategy is remote.

- **CRE log trigger** (RebalanceInitiated) → childA.executeRebalance(rebalanceNonce, newStrategy) on old strategy Child A.

- \_executeWithdraw(max, false). Emits RebalanceWithdrawSuccess on success. On failure, stores rebalance withdraw recovery and emits RebalanceWithdrawFailure; `executeRecovery()` retries the stored withdrawal.

- s_activeProtocolAdapter = address(0) on old Child A.

- **\_ccipSend**(amountOut, newStrategy.chainSelector, REBALANCE, rebalanceNonce, newStrategy.protocolId). Old Child A sends directly to new Child B. A token-pool capacity-ceiling failure reverts the Child A operation atomically; other send-attempt failures store CCIP send recovery for `executeRecovery()`.

- New Child B \_handleCCIPRebalance() → \_setActiveAdapter(protocolId) → \_executeDeposit(amount, false). Emits RebalanceDepositSuccess on success. On failure, stores rebalance deposit recovery and emits RebalanceDepositFailure; `executeRecovery()` retries the stored deposit.

- **CRE log trigger** (RebalanceDepositSuccess) → call `parent.completeRebalance(expectedRebalanceNonce)` with the event's rebalance nonce.

- \_finalizeRebalance() → activeStrategy = pendingStrategy, state → NONE, s_rebalance.nonce++, lastRebalanceCompletedTimestamp updated, management fee minted. Emits RebalanceCompleted.

**CCIP sends: 1**

**CRE executions: 3**

**_Completes asynchronously_**

_Yieldcoin V2 · Canonical Execution Paths_
