// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Types
/// @author @contractlevel
/// @notice Types for the Yieldcoin v2 protocol
/// @dev The types are divided into the following categories:
/// @dev - Strategy: Defining an onchain strategy
/// @dev - CCIP: Crosschain transaction type discriminators and their corresponding data
/// @dev - Recovery: Recovery modes stored in the event of failures
/// @dev - Rebalance: Defining an individual rebalance
/// @dev - Epoch: Defining an individual epoch period
/// @dev - Operational state: Defining all of the operational state for a single onchain read
library Types {
    /*//////////////////////////////////////////////////////////////
                                STRATEGY
    //////////////////////////////////////////////////////////////*/
    /// @notice Struct for defining an onchain strategy
    /// @param protocolId The protocol ID, such as keccak256("aave-v3")
    /// @param chainSelector The CCIP selector of the strategy chain
    struct Strategy {
        bytes32 protocolId;
        uint64 chainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice CCIP transaction type discriminators for epoch net-flow settlement and rebalances
    /// @param EPOCH_NET_DEPOSIT Bridges a positive epoch net flow to the active strategy chain
    /// @param EPOCH_NET_WITHDRAW Bridges underlying asset from the active strategy chain to settle a negative epoch net flow
    /// @param REBALANCE Bridges the active strategy position from the old strategy chain to the new strategy chain
    enum CcipTx {
        EPOCH_NET_DEPOSIT, // 0
        EPOCH_NET_WITHDRAW, // 1
        REBALANCE // 2
    }

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Active recovery mode discriminator
    /// @param NONE No recovery state is active
    /// @param REBALANCE_DEPOSIT Failed rebalance deposit recovery is active
    /// @param REBALANCE_WITHDRAW Failed rebalance withdraw recovery is active
    /// @param EPOCH_DEPOSIT Failed epoch deposit recovery is active
    /// @param EPOCH_WITHDRAW Failed epoch withdraw recovery is active
    /// @param CCIP_SEND Failed ChildVault CCIP send recovery is active
    enum RecoveryMode {
        NONE,
        REBALANCE_DEPOSIT,
        REBALANCE_WITHDRAW,
        EPOCH_DEPOSIT,
        EPOCH_WITHDRAW,
        CCIP_SEND
    }

    /// @notice Recovery state for a failed ChildVault epoch deposit or withdraw
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of underlying asset needed to retry the failed operation
    struct EpochRecovery {
        uint256 epochNonce;
        uint256 amount;
    }

    /// @notice Recovery state for a failed rebalance deposit
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of underlying asset to retry depositing
    struct RebalanceDepositRecovery {
        uint256 rebalanceNonce;
        uint256 amount;
    }

    /// @notice Recovery state for a failed ChildVault rebalance withdraw
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param strategy The target strategy to continue the rebalance into after withdrawal succeeds
    struct RebalanceWithdrawRecovery {
        uint256 rebalanceNonce;
        Strategy strategy;
    }

    /// @notice Recovery state for failed ChildVault CCIP send operations
    /// @param amount The amount of underlying asset to bridge
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE) to replay
    /// @param protocolId The target strategy protocol ID; only meaningful when ccipTxType is REBALANCE
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The CCIP transaction type to replay
    struct CcipSendRecovery {
        uint256 amount;
        uint256 nonce;
        bytes32 protocolId;
        uint64 destinationChainSelector;
        CcipTx ccipTxType;
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice State of the rebalance operation
    /// @param NONE There is no active rebalance operation
    /// @param REBALANCING The rebalance is in progress
    /// @dev Used only by ParentVault
    enum RebalanceState {
        NONE, // 0
        REBALANCING // 1
    }

    /// @notice Data for the rebalance operation
    /// @param nonce The active rebalance ID while state is REBALANCING; otherwise the ID assigned to the next rebalance
    /// @param state The state of the rebalance operation
    /// @param activeStrategy The last finalized strategy; assets may be in transit while a rebalance is active
    /// @param pendingStrategy The target strategy while a rebalance is active, otherwise the zero-value strategy
    /// @param lastRebalanceCompletedTimestamp The completion timestamp used for rebalance cooldowns and fee collection
    /// @dev Used only by ParentVault
    struct Rebalance {
        uint256 nonce;
        RebalanceState state;
        Strategy activeStrategy;
        Strategy pendingStrategy;
        uint256 lastRebalanceCompletedTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                 EPOCH
    //////////////////////////////////////////////////////////////*/
    /// @notice Status of an epoch
    /// @param NONE The epoch has not been opened
    /// @param OPEN The epoch is open for deposits and withdraw intents
    /// @param EXECUTING The epoch is waiting for remote strategy execution or crosschain settlement
    /// @param CLAIMABLE The epoch has settled and its user entries can be claimed
    enum EpochStatus {
        NONE, // 0
        OPEN, // 1
        EXECUTING, // 2
        CLAIMABLE // 3
    }

    /// @notice Data for an epoch
    /// @param totalDepositAmount The total underlying asset recorded for deposit intents, reduced by cancellations while OPEN and fixed at settlement
    /// @param totalShareBurnAmount The total shares recorded for withdraw intents, reduced by cancellations while OPEN and fixed at settlement
    /// @param totalWithdrawClaimAmount The underlying asset allocated to withdraw claims at settlement; provisional during a remote withdraw
    /// @param remainingDepositClaimAmount The unclaimed underlying-asset deposit amount used for shrinking-pool share claims
    /// @param remainingShareMintAmount The unclaimed shares to mint for deposit claims
    /// @param remainingShareBurnAmount The unclaimed shares submitted for withdraw claims
    /// @param remainingWithdrawClaimAmount The unclaimed underlying asset available for withdraw claims
    /// @param openedAtTimestamp The timestamp when the epoch was opened
    /// @param status The status of the epoch
    /// @dev Remaining counter pairs are mutable claim-settlement state. Existing totals remain historical settlement state.
    ///      The claimant who exhausts a side's input pool receives that side's rounding remainder, bounded per side per epoch
    ///      by at most N - 1 smallest output units where N is the number of claimants on that side.
    ///      Deposit-side counters should reach zero together. Withdraw-side counters should reach zero together.
    struct Epoch {
        uint256 totalDepositAmount;
        uint256 totalShareBurnAmount;
        uint256 totalWithdrawClaimAmount;
        uint256 remainingDepositClaimAmount;
        uint256 remainingShareMintAmount;
        uint256 remainingShareBurnAmount;
        uint256 remainingWithdrawClaimAmount;
        uint256 openedAtTimestamp;
        EpochStatus status;
    }

    /*//////////////////////////////////////////////////////////////
                           OPERATIONAL STATE
    //////////////////////////////////////////////////////////////*/
    /// @notice Operational state required to determine the next ParentVault action
    /// @param paused Whether the ParentVault is paused
    /// @param recoveryMode The active recovery mode, or NONE when no recovery is active
    /// @param currentEpochNonce The nonce of the currently open epoch
    /// @param currentEpoch The currently open epoch
    /// @param previousEpoch The epoch immediately preceding the current epoch
    /// @param rebalance The current rebalance state
    /// @param tvl The vault's accounted underlying-asset value
    struct ParentOperationalState {
        bool paused;
        RecoveryMode recoveryMode;
        uint256 currentEpochNonce;
        Epoch currentEpoch;
        Epoch previousEpoch;
        Rebalance rebalance;
        uint256 tvl;
    }

    /// @notice Operational state required to determine the next ChildVault action
    /// @param paused Whether the ChildVault is paused
    /// @param recoveryMode The active recovery mode, or NONE when no recovery is active
    /// @param lastHandledEpochNonce The highest epoch nonce handled by the ChildVault
    /// @param lastHandledRebalanceNonce The highest rebalance nonce handled by the ChildVault
    /// @param tvl The vault's accounted underlying-asset value
    struct ChildOperationalState {
        bool paused;
        RecoveryMode recoveryMode;
        uint256 lastHandledEpochNonce;
        uint256 lastHandledRebalanceNonce;
        uint256 tvl;
    }
}
