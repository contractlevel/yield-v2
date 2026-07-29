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
library Types {
    /*//////////////////////////////////////////////////////////////
                                STRATEGY
    //////////////////////////////////////////////////////////////*/
    /// @notice Struct for defining an onchain strategy
    /// @param protocolId The protocol ID - keccak256("aave-v3"), keccak256("aave-v4")
    /// @param chainSelector CCIP chain selector
    struct Strategy {
        bytes32 protocolId;
        uint64 chainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice CCIP transaction type discriminators for epoch net-flow settlement and rebalances
    /// @param EPOCH_NET_DEPOSIT Epoch netflow has more deposits than withdraws and bridges the underlying asset to the active strategy chain
    /// @param EPOCH_NET_WITHDRAW Epoch netflow has more withdraws than deposits and bridges the underlying asset from the strategy to the Parent
    /// @param REBALANCE The system rebalances by bridging the TVL from the old strategy to the new strategy chain
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

    /// @notice Recovery state for failed epoch operations
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount needed to retry the failed operation
    struct EpochRecovery {
        uint256 epochNonce;
        uint256 amount;
    }

    /// @notice Recovery state for failed rebalance deposit operations
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount needed to retry the failed deposit
    struct RebalanceDepositRecovery {
        uint256 rebalanceNonce;
        uint256 amount;
    }

    /// @notice Recovery state for failed rebalance withdraw operations
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    struct RebalanceWithdrawRecovery {
        uint256 rebalanceNonce;
        Strategy strategy;
    }

    /// @notice Recovery state for failed ChildVault CCIP send operations
    /// @param amount The amount of asset to bridge
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE) to replay
    /// @param protocolId The target strategy protocol id to rebalance into; only meaningful when ccipTxType is REBALANCE
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
    /// @dev This is only used on the Parent chain
    /// @param NONE There is no active rebalance operation
    /// @param REBALANCING The rebalance is in progress
    enum RebalanceState {
        NONE, // 0
        REBALANCING // 1
    }

    /// @notice Data for the rebalance operation
    /// @dev This is only used on the Parent chain
    /// @param nonce How many rebalances have been initiated. This is used for individual rebalance IDs
    /// @param state The state of the rebalance operation
    /// @param activeStrategy The active strategy, where the Yieldcoin TVL is currently allocated
    /// @param pendingStrategy The pending strategy, where the Yieldcoin TVL is going to be allocated
    /// @param lastRebalanceCompletedTimestamp The timestamp of the last rebalance operation completed. This is for fee collection.
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
    /// @param OPEN The epoch is open for deposits and withdraws
    /// @param EXECUTING The epoch is executing
    /// @param CLAIMABLE The epoch is claimable
    enum EpochStatus {
        NONE, // 0
        OPEN, // 1
        EXECUTING, // 2
        CLAIMABLE // 3
    }

    /// @notice Data for an epoch
    /// @param totalDepositAmount The total amount of asset deposited during the epoch
    /// @param totalShareBurnAmount The total amount of shares submitted to be burned during the epoch
    /// @param totalWithdrawClaimAmount The total amount of asset available for withdraw claims during the epoch
    /// @param pricePerShare The price per share of the epoch
    /// @param remainingDepositClaimAmount The unclaimed asset deposit amount used for shrinking-pool share claims
    /// @param remainingShareMintAmount The unclaimed shares to mint for deposit claims
    /// @param remainingShareBurnAmount The unclaimed shares submitted for withdraw claims
    /// @param remainingWithdrawClaimAmount The unclaimed asset available for withdraw claims
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
        uint256 pricePerShare;
        uint256 remainingDepositClaimAmount;
        uint256 remainingShareMintAmount;
        uint256 remainingShareBurnAmount;
        uint256 remainingWithdrawClaimAmount;
        uint256 openedAtTimestamp;
        EpochStatus status;
    }
}
