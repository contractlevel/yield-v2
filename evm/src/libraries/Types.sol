// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @author @contractlevel
/// @notice Types for the Yieldcoin v2 protocol
/// @dev The types are divided into the following categories:
/// @dev - Strategy: Defining an onchain strategy
/// @dev - CCIP: Crosschain transaction type discriminators and their corresponding data
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
    /// @notice CCIP Transaction Types - used to discriminate between deposit, withdraw, and rebalance when receiving CCIP messages
    /// @param DEPOSIT Epoch netflow has more deposits that withdraws, and bridges USDC to the active strategy chain
    /// @param WITHDRAW Epoch netflow has more withdraws than deposits, USDC is bridged from the strategy to the Parent
    /// @param REBALANCE The system rebalances by bridging the TVL from the old strategy to the new strategy chain
    enum CcipTx {
        DEPOSIT, // 0 // @review rename these to EPOCH_DEPOSIT and EPOCH_WITHDRAW or something similar EpochInFlow EpochOutFlow
        WITHDRAW, // 1
        REBALANCE // 2
    }

    /// @notice Data for a rebalance CCIP message
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param targetProtocolId The protocol ID of the target strategy protocol to rebalance into
    struct RebalanceCcipData {
        uint256 rebalanceNonce;
        bytes32 targetProtocolId;
    }

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovery state for failed operations that only need an amount
    /// @param amount The amount needed to retry the failed operation
    /// @param createdAt The timestamp when the recovery state was stored
    struct AmountRecovery {
        uint256 amount;
        uint256 createdAt;
    }

    /// @notice Recovery state for failed rebalance deposit operations
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount needed to retry the failed deposit
    /// @param createdAt The timestamp when the recovery state was stored
    struct RebalanceDepositRecovery {
        uint256 rebalanceNonce;
        uint256 amount;
        uint256 createdAt;
    }

    /// @notice Recovery state for failed rebalance withdraw operations
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @param createdAt The timestamp when the recovery state was stored
    struct RebalanceWithdrawRecovery {
        uint256 rebalanceNonce;
        Strategy strategy;
        uint256 createdAt;
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
    /// @param lastRebalanceInitiatedTimestamp The timestamp of the last rebalance operation initiated. This is for recovery timeouts.
    /// @param lastRebalanceCompletedTimestamp The timestamp of the last rebalance operation completed. This is for fee collection.
    struct Rebalance {
        uint256 nonce;
        RebalanceState state;
        Strategy activeStrategy;
        Strategy pendingStrategy;
        uint256 lastRebalanceInitiatedTimestamp;
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
    /// @param totalDepositAmount The total amount of USDC deposited during the epoch
    /// @param totalShareBurnAmount The total amount of shares submitted to be burned during the epoch
    /// @param totalWithdrawClaimAmount The total amount of USDC available for withdraw claims during the epoch
    /// @param pricePerShare The price per share of the epoch
    /// @param openedAtTimestamp The timestamp when the epoch was opened
    /// @param closedAtTimestamp The timestamp when the epoch was closed
    /// @param status The status of the epoch
    struct Epoch {
        uint256 totalDepositAmount;
        uint256 totalShareBurnAmount;
        uint256 totalWithdrawClaimAmount;
        uint256 pricePerShare;
        uint256 openedAtTimestamp;
        uint256 closedAtTimestamp;
        EpochStatus status;
    }
}
