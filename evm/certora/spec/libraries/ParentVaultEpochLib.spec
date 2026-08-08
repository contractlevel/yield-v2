using MockYieldcoinShare as share;

/// Verification of ParentVaultEpochLib
/// @author @contractlevel
/// @notice ParentVaultEpochLib handles ParentVault epoch closing, local net-withdraw finalization, and opening the next epoch.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getMinEpochPeriod() external returns (uint256) envfree;
    function getEpochNonce() external returns (uint256) envfree;
    function getPreviousEpochNonce() external returns (uint256) envfree;
    function getPreviousEpochStatus() external returns (Types.EpochStatus) envfree;
    function getTotalShares() external returns (uint256) envfree;
    function getPerformanceFeeHighWaterMark() external returns (uint256) envfree;
    function getTreasury() external returns (address) envfree;
    function getRebalanceState() external returns (Types.RebalanceState) envfree;
    function getEpochTotalDepositAmount(uint256) external returns (uint256) envfree;
    function getEpochTotalShareBurnAmount(uint256) external returns (uint256) envfree;
    function getEpochTotalWithdrawClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochPricePerShare(uint256) external returns (uint256) envfree;
    function getEpochRemainingDepositClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingShareMintAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingShareBurnAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingWithdrawClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochOpenedAtTimestamp(uint256) external returns (uint256) envfree;
    function getEpochStatus(uint256) external returns (Types.EpochStatus) envfree;

    // Library public wrappers
    function closeEpoch(uint256, uint256, uint256, uint256, bool)
        external returns (uint256, uint8, uint256, uint256);
    function completeEpochDeposit() external;
    function finalizeLocalNetWithdraw(uint256, uint256, uint256) external;
    function openNextEpoch(uint256) external;

    // Mock methods
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;

    // Dispatcher summaries
    function _.mint(address, uint256) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition ACTION_NONE() returns uint8 = 0;
definition ACTION_DEPOSIT_TO_LOCAL_STRATEGY() returns uint8 = 1;
definition ACTION_SEND_DEPOSIT_TO_REMOTE_STRATEGY() returns uint8 = 2;
definition ACTION_WITHDRAW_FROM_LOCAL_STRATEGY() returns uint8 = 3;
definition ACTION_WAIT_FOR_REMOTE_WITHDRAW() returns uint8 = 4;

definition EpochOpenEvent() returns bytes32 =
// keccak256("EpochOpen(uint256)")
    to_bytes32(0x581f6669baee8fbb7926034742085996de6e2c904da8849660716d60148f9f3b);

definition EpochDepositExecutingEvent() returns bytes32 =
// keccak256("EpochDepositExecuting(uint256,uint256)")
    to_bytes32(0xa61849e22afb93d7cfe676ea2f393b96d7529f8e5ea5bc633327c8945f9b2b4f);

definition EpochWithdrawExecutingEvent() returns bytes32 =
// keccak256("EpochWithdrawExecuting(uint256,uint256)")
    to_bytes32(0x95711be73a8119e097a46812abd1fa8ec60493925e863579094178cb6d86ec38);

definition EpochClaimableEvent() returns bytes32 =
// keccak256("EpochClaimable(uint256)")
    to_bytes32(0x45d9681f238e455170e797872754deaef148c9e7836f9949104764a4f4cfae8a);

definition PerformanceFeeCollectedEvent() returns bytes32 =
// keccak256("PerformanceFeeCollected(uint256,uint256,uint256)")
    to_bytes32(0xdc4f167bfca42a54abc7c7dd90ec178ea116a54329d32a1a6cb1c6208d17177c);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice StoreCount: track writes to s_epochNonce
ghost mathint ghost_epochNonce_StoreCount {
    init_state axiom ghost_epochNonce_StoreCount == 0;
}

/// @notice StoredValue: track latest value written to s_epochNonce
ghost uint256 ghost_epochNonce_StoredValue {
    init_state axiom ghost_epochNonce_StoredValue == 0;
}

/// @notice StoreCount: track writes to s_totalShares
ghost mathint ghost_totalShares_StoreCount {
    init_state axiom ghost_totalShares_StoreCount == 0;
}

/// @notice StoredValue: track latest value written to s_totalShares
ghost uint256 ghost_totalShares_StoredValue {
    init_state axiom ghost_totalShares_StoredValue == 0;
}

/// @notice StoreCount: track writes to epoch.totalWithdrawClaimAmount
ghost mathint ghost_epoch_totalWithdrawClaimAmount_StoreCount {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0;
}

/// @notice StoredKey: track latest epoch key written for totalWithdrawClaimAmount
ghost uint256 ghost_epoch_totalWithdrawClaimAmount_StoredKey {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoredKey == 0;
}

/// @notice StoredValue: track latest value written to epoch.totalWithdrawClaimAmount
ghost uint256 ghost_epoch_totalWithdrawClaimAmount_StoredValue {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoredValue == 0;
}

/// @notice StoreCount: track writes to epoch.status
ghost mathint ghost_epoch_status_StoreCount {
    init_state axiom ghost_epoch_status_StoreCount == 0;
}

/// @notice StoredKey: track latest epoch key written for status
ghost uint256 ghost_epoch_status_StoredKey {
    init_state axiom ghost_epoch_status_StoredKey == 0;
}

/// @notice StoredValue: track latest value written to epoch.status
ghost Types.EpochStatus ghost_epoch_status_StoredValue {
    init_state axiom ghost_epoch_status_StoredValue == Types.EpochStatus.NONE;
}

/// @notice EventCount: track amount EpochOpen event is emitted
ghost mathint ghost_EpochOpen_EventCount {
    init_state axiom ghost_EpochOpen_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochOpen event
ghost uint256 ghost_EpochOpen_Param_epochNonce {
    init_state axiom ghost_EpochOpen_Param_epochNonce == 0;
}

/// @notice EventCount: track amount EpochDepositExecuting event is emitted
ghost mathint ghost_EpochDepositExecuting_EventCount {
    init_state axiom ghost_EpochDepositExecuting_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochDepositExecuting event
ghost uint256 ghost_EpochDepositExecuting_Param_epochNonce {
    init_state axiom ghost_EpochDepositExecuting_Param_epochNonce == 0;
}

/// @notice EmittedValue: track amount param emitted in EpochDepositExecuting event
ghost uint256 ghost_EpochDepositExecuting_Param_amount {
    init_state axiom ghost_EpochDepositExecuting_Param_amount == 0;
}

/// @notice EventCount: track amount EpochWithdrawExecuting event is emitted
ghost mathint ghost_EpochWithdrawExecuting_EventCount {
    init_state axiom ghost_EpochWithdrawExecuting_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochWithdrawExecuting event
ghost uint256 ghost_EpochWithdrawExecuting_Param_epochNonce {
    init_state axiom ghost_EpochWithdrawExecuting_Param_epochNonce == 0;
}

/// @notice EmittedValue: track amount param emitted in EpochWithdrawExecuting event
ghost uint256 ghost_EpochWithdrawExecuting_Param_amount {
    init_state axiom ghost_EpochWithdrawExecuting_Param_amount == 0;
}

/// @notice EventCount: track amount EpochClaimable event is emitted
ghost mathint ghost_EpochClaimable_EventCount {
    init_state axiom ghost_EpochClaimable_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochClaimable event
ghost uint256 ghost_EpochClaimable_Param_epochNonce {
    init_state axiom ghost_EpochClaimable_Param_epochNonce == 0;
}

ghost mathint ghost_PerformanceFeeCollected_EventCount {
    init_state axiom ghost_PerformanceFeeCollected_EventCount == 0;
}

ghost uint256 ghost_PerformanceFeeCollected_Param_epochNonce {
    init_state axiom ghost_PerformanceFeeCollected_Param_epochNonce == 0;
}

ghost uint256 ghost_PerformanceFeeCollected_Param_feeShares {
    init_state axiom ghost_PerformanceFeeCollected_Param_feeShares == 0;
}

ghost uint256 ghost_PerformanceFeeCollected_Param_settlementPricePerShare {
    init_state axiom ghost_PerformanceFeeCollected_Param_settlementPricePerShare == 0;
}

definition EpochLifecycleEventCountsAreZero() returns bool =
    ghost_EpochClaimable_EventCount == 0
        && ghost_EpochDepositExecuting_EventCount == 0
        && ghost_EpochWithdrawExecuting_EventCount == 0
        && ghost_PerformanceFeeCollected_EventCount == 0;

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto epoch nonce storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochNonce uint256 newValue {
    ghost_epochNonce_StoreCount = ghost_epochNonce_StoreCount + 1;
    ghost_epochNonce_StoredValue = newValue;
}

/// @notice hook onto total shares storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_totalShares uint256 newValue {
    ghost_totalShares_StoreCount = ghost_totalShares_StoreCount + 1;
    ghost_totalShares_StoredValue = newValue;
}

/// @notice hook onto ParentVault epoch totalWithdrawClaimAmount storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].totalWithdrawClaimAmount uint256 newValue {
    ghost_epoch_totalWithdrawClaimAmount_StoreCount = ghost_epoch_totalWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_totalWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_totalWithdrawClaimAmount_StoredValue = newValue;
}

/// @notice hook onto ParentVault epoch status storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].status Types.EpochStatus newValue {
    ghost_epoch_status_StoreCount = ghost_epoch_status_StoreCount + 1;
    ghost_epoch_status_StoredKey = epochNonce;
    ghost_epoch_status_StoredValue = newValue;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == EpochOpenEvent()) {
        ghost_EpochOpen_EventCount = ghost_EpochOpen_EventCount + 1;
        ghost_EpochOpen_Param_epochNonce = bytes32ToUint256(t1);
    } else if (t0 == EpochClaimableEvent()) {
        ghost_EpochClaimable_EventCount = ghost_EpochClaimable_EventCount + 1;
        ghost_EpochClaimable_Param_epochNonce = bytes32ToUint256(t1);
    }
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == EpochDepositExecutingEvent()) {
        ghost_EpochDepositExecuting_EventCount = ghost_EpochDepositExecuting_EventCount + 1;
        ghost_EpochDepositExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochDepositExecuting_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == EpochWithdrawExecutingEvent()) {
        ghost_EpochWithdrawExecuting_EventCount = ghost_EpochWithdrawExecuting_EventCount + 1;
        ghost_EpochWithdrawExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawExecuting_Param_amount = bytes32ToUint256(t2);
    }
}

hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == PerformanceFeeCollectedEvent()) {
        ghost_PerformanceFeeCollected_EventCount = ghost_PerformanceFeeCollected_EventCount + 1;
        ghost_PerformanceFeeCollected_Param_epochNonce = bytes32ToUint256(t1);
        ghost_PerformanceFeeCollected_Param_feeShares = bytes32ToUint256(t2);
        ghost_PerformanceFeeCollected_Param_settlementPricePerShare = bytes32ToUint256(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── CLOSE EPOCH REVERTS ────────────────────

/// @notice Closing an epoch reverts when a rebalance is in progress.
/// @dev Verifies the targeted revert independently of competing conditions.
rule EPOCH_003_closeEpoch_RevertWhen_RebalanceInProgress() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getEpochNonce() == 1, "current epoch is the first epoch";
    require getEpochStatus(getEpochNonce()) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(getEpochNonce()) <= max_uint256 - getMinEpochPeriod(),
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(getEpochNonce()) + getMinEpochPeriod(),
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(getEpochNonce()) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(getEpochNonce()) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev revert condition being verified
    require getRebalanceState() != Types.RebalanceState.NONE, "rebalance is in progress";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the current epoch nonce is zero.
/// @dev Verifies the checked subtraction used to derive the previous epoch nonce.
rule closeEpoch_RevertWhen_CurrentEpochNonceIsZero() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochStatus(0) == Types.EpochStatus.OPEN, "epoch zero is open if reached";
    require getEpochOpenedAtTimestamp(0) <= max_uint256 - getMinEpochPeriod(),
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(0) + getMinEpochPeriod(),
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(0) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(0) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev revert condition being verified
    require getEpochNonce() == 0, "current epoch nonce is zero";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the previous nonzero epoch is not claimable.
/// @dev Verifies the targeted revert independently of competing conditions.
rule EPOCH_003_closeEpoch_RevertWhen_PreviousEpochNotClaimable() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() > 1, "previous epoch nonce is nonzero";

    uint256 previousEpochNonce = getPreviousEpochNonce();
    uint256 epochNonce = getEpochNonce();

    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "current epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - getMinEpochPeriod(),
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + getMinEpochPeriod(),
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev revert condition being verified
    require getEpochStatus(previousEpochNonce) != Types.EpochStatus.CLAIMABLE, "previous epoch is not claimable";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the current epoch is not open.
/// @dev Verifies the targeted revert independently of competing conditions.
rule closeEpoch_RevertWhen_EpochNotOpen() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();

    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - getMinEpochPeriod(),
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + getMinEpochPeriod(),
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the open timestamp plus the minimum period overflows.
/// @dev Verifies the targeted revert independently of competing conditions.
rule closeEpoch_RevertWhen_EpochOpenTimestampOverflows() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) > max_uint256 - getMinEpochPeriod(),
        "minimum epoch period addition overflows";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the minimum epoch period has not elapsed.
/// @dev Verifies the targeted revert independently of competing conditions.
rule closeEpoch_RevertWhen_EpochTooShort() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp < getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has not elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when it has no deposits and no share burns.
/// @dev Verifies the targeted revert independently of competing conditions.
rule closeEpoch_RevertWhen_EmptyEpoch() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 0, "total deposit amount is zero";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "total share burn amount is zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require tvl == 0, "bootstrap tvl is zero";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when TVL is zero while shares are outstanding.
/// @dev Verifies the targeted revert independently of competing conditions.
rule closeEpoch_RevertWhen_ZeroTvlWithOutstandingShares() {
    env e;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() != 0, "shares are outstanding";
    require sharePrecision == 1, "share precision is one";
    require minDepositAmount == 1, "minimum deposit amount is one";
    uint256 tvl = 0;

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when deposits would mint zero shares.
/// @dev Verifies the explicit zero-share deposit guard, not fee collection behavior.
rule closeEpoch_RevertWhen_DepositWouldMintZeroShares() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) != 0, "total deposit amount is nonzero";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 / 2, "deposit amount fits int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    mathint grossPricePerShare = tvl * sharePrecision / totalShares;
    require grossPricePerShare != 0, "gross price per share is nonzero";
    require getPerformanceFeeHighWaterMark() >= grossPricePerShare, "performance fee is not collected";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 / totalShares,
        "new share calculation does not overflow";
    mathint newShares = getEpochTotalDepositAmount(epochNonce) * totalShares / tvl;

    uint256 minDepositAmount = 1000000;
    require newShares <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";
    require totalShares <= max_uint256 - newShares, "total shares addition does not overflow";
    require newShares * minDepositAmount < getEpochTotalDepositAmount(epochNonce), "deposits mint zero shares";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when share precision is zero.
/// @dev Verifies the total-withdraw mulDiv denominator guard even when no shares are burned.
rule closeEpoch_RevertWhen_SharePrecisionIsZero() {
    env e;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) != 0, "total deposit amount is nonzero";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 / 2, "deposit amount fits int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    uint256 tvl = 0;
    uint256 sharePrecision = 0;
    uint256 assetPrecision = 1;
    require getPerformanceFeeHighWaterMark() >= assetPrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing a bootstrap epoch reverts when asset precision is zero.
/// @dev Verifies the new-share mulDiv denominator guard independently of share precision.
rule closeEpoch_RevertWhen_AssetPrecisionIsZero() {
    env e;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) != 0, "total deposit amount is nonzero";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 / 2, "deposit amount fits int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    uint256 tvl = 0;
    uint256 sharePrecision = 1;
    uint256 assetPrecision = 0;

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the full-precision gross price per share exceeds uint256.
/// @dev Verifies the price-per-share mulDiv result-overflow path.
rule closeEpoch_RevertWhen_GrossPricePerShareOverflows() {
    env e;
    uint256 tvl = max_uint256;
    uint256 sharePrecision = max_uint256;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) != 0 || getEpochTotalShareBurnAmount(epochNonce) != 0,
        "epoch is not empty";
    require getTotalShares() == 1, "one share is outstanding";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the full-precision total withdraw exceeds uint256.
/// @dev Verifies the share-burn settlement mulDiv result-overflow path.
rule closeEpoch_RevertWhen_TotalWithdrawOverflows() {
    env e;
    uint256 tvl = max_uint256;
    uint256 sharePrecision = 1;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require shareBurnAmount == 2, "two shares are burned";
    require totalShares == 1, "one share is outstanding";
    require getPerformanceFeeHighWaterMark() == max_uint256, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the full-precision new-share amount exceeds uint256.
/// @dev Verifies the deposit-share mulDiv result-overflow path.
rule closeEpoch_RevertWhen_NewSharesOverflows() {
    env e;
    uint256 sharePrecision = max_uint256;
    uint256 assetPrecision = 1;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require depositAmount == max_uint256 / 2, "deposit amount is the maximum positive int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= assetPrecision, "performance fee is not collected";

    uint256 tvl = 0;
    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when settlement price per share is zero.
/// @dev Verifies the explicit zero-price-per-share guard before new-share calculation.
rule closeEpoch_RevertWhen_SettlementPricePerShareIsZero() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require depositAmount != 0, "total deposit amount is nonzero";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    require tvl * sharePrecision < totalShares, "settlement price per share is zero";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when the zero-share guard multiplication overflows.
/// @dev Verifies the explicit min-deposit multiplication overflow path.
rule closeEpoch_RevertWhen_ZeroShareGuardMultiplicationOverflows() {
    env e;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 sharePrecision = 1;
    uint256 minDepositAmount = 1000000;

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require depositAmount != 0, "total deposit amount is nonzero";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require depositAmount > max_uint256 / minDepositAmount, "zero-share guard multiplication overflows";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    uint256 tvl = 0;
    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when total share addition overflows.
/// @dev Verifies s_totalShares + newShares overflow before share burns are subtracted.
rule closeEpoch_RevertWhen_TotalSharesAdditionOverflows() {
    env e;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 sharePrecision = 1;
    uint256 minDepositAmount = 1000000;

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require totalShares != 0, "shares are outstanding";
    require depositAmount != 0, "total deposit amount is nonzero";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require depositAmount <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";
    require totalShares > max_uint256 - depositAmount, "total shares addition overflows";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// @notice Closing an epoch reverts when total share subtraction underflows.
/// @dev Verifies s_totalShares + newShares - burned shares underflow.
rule closeEpoch_RevertWhen_TotalSharesSubtractionUnderflows() {
    env e;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);
    uint256 sharePrecision = 1;
    uint256 minDepositAmount = 1000000;

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require totalShares != 0, "shares are outstanding";
    require depositAmount == 0, "no deposits were made";
    require shareBurnAmount != 0, "shares are burned";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require shareBurnAmount > totalShares, "total shares subtraction underflows";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";

    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert EpochLifecycleEventCountsAreZero();
}

/// ─────────────────── CLOSE EPOCH SUCCESS ────────────────────

/// @dev Performance-fee-specific reverts and high-water-mark behavior are verified in
/// ParentVaultFeesLib.spec. The rules below verify closeEpoch's integration with that library.

/// @notice Closing a balanced epoch makes it claimable and returns no external action.
/// @dev Verifies the net-zero branch with a concrete non-fee arithmetic witness.
rule closeEpoch_Success_WhenNetFlowIsZero() {
    env e;
    uint256 sharePrecision = 1;
    bool isLocalStrategy = false;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require totalShares == 2, "two shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = 2;
    require getPerformanceFeeHighWaterMark() == 1, "performance fee is not collected";
    require depositAmount == 1, "one asset unit is deposited";
    require shareBurnAmount == 1, "one share is burned";
    require depositAmount <= max_uint256 / sharePrecision, "share calculation does not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares <= max_uint256 - depositAmount, "total shares addition does not overflow";
    uint256 minDepositAmount = 1;
    require depositAmount <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
    closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_NONE();
    assert returnedAmount == 0;
    assert returnedTotalDepositAmount == depositAmount;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == totalShares;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmount;
    assert getEpochTotalShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert getEpochPricePerShare(epochNonce) == sharePrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_EpochDepositExecuting_EventCount == 0;
    assert ghost_EpochWithdrawExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == shareBurnAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// @notice Closing an epoch folds performance-fee shares into the epoch's sole total-share write.
/// @dev Verifies fee minting, dilution, epoch accounting, action, and both emitted events.
rule closeEpoch_Success_WhenPerformanceFeeIsCollected() {
    env e;
    uint256 tvl = 2;
    uint256 sharePrecision = 10000;
    uint256 assetPrecision = 1;
    uint256 minDepositAmount = 1;
    bool isLocalStrategy = true;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 feeShares = 10000;
    uint256 newShares = 10000;
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getEpochTotalDepositAmount(epochNonce) == 1, "one asset unit is deposited";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require getTotalShares() == 10000, "ten thousand shares are outstanding";
    require getPerformanceFeeHighWaterMark() == 1, "gross price exceeds the high-water mark";
    require treasuryBalanceBefore <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require totalSupplyBefore <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_DEPOSIT_TO_LOCAL_STRATEGY();
    assert returnedAmount == 1;
    assert returnedTotalDepositAmount == 1;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == 10000 + feeShares + newShares;
    assert getPerformanceFeeHighWaterMark() == 1;
    assert getEpochTotalDepositAmount(epochNonce) == 1;
    assert getEpochTotalShareBurnAmount(epochNonce) == 0;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert getEpochPricePerShare(epochNonce) == 1;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == 1;
    assert getEpochRemainingShareMintAmount(epochNonce) == newShares;
    assert getEpochRemainingShareBurnAmount(epochNonce) == 0;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == 0;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == 0;
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert share.totalSupply() == totalSupplyBefore + feeShares;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_EventCount == 1;
    assert ghost_PerformanceFeeCollected_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_Param_feeShares == feeShares;
    assert ghost_PerformanceFeeCollected_Param_settlementPricePerShare == 1;
    assert ghost_EpochDepositExecuting_EventCount == 0;
    assert ghost_EpochWithdrawExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == 10000 + feeShares + newShares;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == 0;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// @notice Closing a net-deposit epoch returns a local strategy deposit action when the strategy is local.
/// @dev Verifies the positive-net-flow local branch with production share/asset precisions.
rule closeEpoch_Success_WhenLocalNetDeposit() {
    env e;
    uint256 sharePrecision = 1000000000000000000;
    uint256 assetPrecision = 1000000;
    uint256 minDepositAmount = 1000000;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= assetPrecision, "performance fee is not collected";
    require depositAmount == assetPrecision, "deposit is one whole asset token";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bool isLocalStrategy = true;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
        closeEpoch@withrevert(e, 0, sharePrecision, assetPrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_DEPOSIT_TO_LOCAL_STRATEGY();
    assert returnedAmount == depositAmount;
    assert returnedTotalDepositAmount == depositAmount;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == sharePrecision;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmount;
    assert getEpochTotalShareBurnAmount(epochNonce) == 0;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert getEpochPricePerShare(epochNonce) == assetPrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == sharePrecision;
    assert getEpochRemainingShareBurnAmount(epochNonce) == 0;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == 0;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == 0;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_EpochDepositExecuting_EventCount == 0;
    assert ghost_EpochWithdrawExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == sharePrecision;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == 0;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// @notice Closing a net-deposit epoch returns a remote strategy deposit action when the strategy is remote.
/// @dev Verifies the positive-net-flow remote branch while fee collection is not active.
rule closeEpoch_Success_WhenRemoteNetDeposit() {
    env e;
    uint256 sharePrecision;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require sharePrecision != 0, "share precision is nonzero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";
    require depositAmount != 0, "net deposit amount is nonzero";
    require depositAmount <= max_uint256 / sharePrecision, "share calculation does not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require minDepositAmount == 1000000, "minimum deposit amount matches production";
    require depositAmount <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochDepositExecuting_EventCount == 0,
        "EpochDepositExecuting event count starts at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bool isLocalStrategy = false;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
        closeEpoch@withrevert(e, 0, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_SEND_DEPOSIT_TO_REMOTE_STRATEGY();
    assert returnedAmount == depositAmount;
    assert returnedTotalDepositAmount == depositAmount;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == depositAmount;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmount;
    assert getEpochTotalShareBurnAmount(epochNonce) == 0;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING;
    assert getEpochPricePerShare(epochNonce) == sharePrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareBurnAmount(epochNonce) == 0;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == 0;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == 0;
    assert ghost_EpochDepositExecuting_EventCount == 1;
    assert ghost_EpochDepositExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochDepositExecuting_Param_amount == depositAmount;
    assert ghost_EpochClaimable_EventCount == 0;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_EpochWithdrawExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == depositAmount;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == 0;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.EXECUTING;
}

/// @notice Closing a net-withdraw epoch returns a local strategy withdraw action when the strategy is local.
/// @dev Verifies the negative-net-flow local branch with a concrete non-fee arithmetic witness.
rule closeEpoch_Success_WhenLocalNetWithdraw() {
    env e;
    uint256 sharePrecision = 1;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();
    uint256 totalWithdrawClaimAmountBefore = getEpochTotalWithdrawClaimAmount(epochNonce);
    uint256 remainingWithdrawClaimAmountBefore = getEpochRemainingWithdrawClaimAmount(epochNonce);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require totalShares == 2, "two shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = 2;
    require getPerformanceFeeHighWaterMark() == 1, "performance fee is not collected";
    require depositAmount == 1, "one asset unit is deposited";
    require shareBurnAmount == 2, "two shares are burned";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require shareBurnAmount <= max_uint256 / sharePrecision, "withdraw calculation does not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares <= max_uint256 - depositAmount, "total shares addition does not overflow";
    require totalShares + depositAmount >= shareBurnAmount, "total shares subtraction does not underflow";
    mathint netWithdrawAmount = shareBurnAmount - depositAmount;
    uint256 minDepositAmount = 1;
    require depositAmount <= max_uint256 / minDepositAmount,
        "zero-share guard multiplication does not overflow";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_EpochDepositExecuting_EventCount == 0,
        "EpochDepositExecuting event count starts at zero";
    require ghost_EpochWithdrawExecuting_EventCount == 0,
        "EpochWithdrawExecuting event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bool isLocalStrategy = true;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_WITHDRAW_FROM_LOCAL_STRATEGY();
    assert returnedAmount == netWithdrawAmount;
    assert returnedTotalDepositAmount == depositAmount;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == totalShares + depositAmount - shareBurnAmount;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmount;
    assert getEpochTotalShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.OPEN;
    assert getEpochPricePerShare(epochNonce) == sharePrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == totalWithdrawClaimAmountBefore;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == remainingWithdrawClaimAmountBefore;
    assert ghost_EpochClaimable_EventCount == 0;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_EpochDepositExecuting_EventCount == 0;
    assert ghost_EpochWithdrawExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + depositAmount - shareBurnAmount;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0;
    assert ghost_epoch_status_StoreCount == 0;
}

/// @notice Closing a net-withdraw epoch returns a remote wait action when the strategy is remote.
/// @dev Verifies the remote branch, executing status, and event with a concrete non-fee arithmetic witness.
rule closeEpoch_Success_WhenRemoteNetWithdraw() {
    env e;
    uint256 sharePrecision = 1;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";
    require getEpochNonce() == 1 || getPreviousEpochStatus() == Types.EpochStatus.CLAIMABLE,
        "previous epoch is claimable when required";

    uint256 epochNonce = getEpochNonce();
    uint256 minEpochPeriod = getMinEpochPeriod();
    uint256 totalShares = getTotalShares();
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require totalShares == 2, "two shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = 2;
    require getPerformanceFeeHighWaterMark() == 1, "performance fee is not collected";
    require getEpochTotalDepositAmount(epochNonce) == 0, "no deposits were made";
    require shareBurnAmount == 1, "one share is burned";
    require shareBurnAmount <= max_uint256 / sharePrecision, "withdraw calculation does not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares >= shareBurnAmount, "total shares subtraction does not underflow";

    /// @dev ghost starting values
    require EpochLifecycleEventCountsAreZero(), "epoch lifecycle event counts start at zero";
    require ghost_EpochWithdrawExecuting_EventCount == 0,
        "EpochWithdrawExecuting event count starts at zero";
    require ghost_PerformanceFeeCollected_EventCount == 0,
        "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bool isLocalStrategy = false;
    uint256 minDepositAmount = 1;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount; uint256 returnedTotalDepositAmount;
    (returnedEpochNonce, returnedAction, returnedAmount, returnedTotalDepositAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_WAIT_FOR_REMOTE_WITHDRAW();
    assert returnedAmount == shareBurnAmount;
    assert returnedTotalDepositAmount == 0;
    assert getEpochNonce() == epochNonce;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalDepositAmount(epochNonce) == 0;
    assert getEpochTotalShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING;
    assert getEpochPricePerShare(epochNonce) == sharePrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == 0;
    assert getEpochRemainingShareMintAmount(epochNonce) == 0;
    assert getEpochRemainingShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert ghost_EpochWithdrawExecuting_EventCount == 1;
    assert ghost_EpochWithdrawExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawExecuting_Param_amount == shareBurnAmount;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_EpochClaimable_EventCount == 0;
    assert ghost_EpochDepositExecuting_EventCount == 0;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares - shareBurnAmount;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == shareBurnAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.EXECUTING;
}

/// ─────────────── COMPLETE EPOCH DEPOSIT ───────────────

/// @notice Completing an epoch deposit reverts when the current epoch nonce is zero.
/// @dev Verifies the checked subtraction used to access the previous epoch.
rule completeEpochDeposit_RevertWhen_CurrentEpochNonceIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "completeEpochDeposit is nonpayable";

    /// @dev revert condition being verified
    require getEpochNonce() == 0, "current epoch nonce is zero";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
}

/// @notice Completing an epoch deposit reverts before any epoch has completed.
/// @dev Verifies the no-completed-epoch guard independently of later conditions.
rule completeEpochDeposit_RevertWhen_NoCompletedEpoch() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "completeEpochDeposit is nonpayable";

    /// @dev revert condition being verified
    require getEpochNonce() == 1, "current epoch nonce is one";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
}

/// @notice Completing an epoch deposit reverts when the previous epoch is not a net deposit.
/// @dev Verifies the net-deposit guard independently of the executing-status guard.
rule completeEpochDeposit_RevertWhen_PreviousEpochIsNotNetDeposit() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "completeEpochDeposit is nonpayable";
    require getEpochNonce() > 1, "at least one epoch has completed";
    require getPreviousEpochStatus() == Types.EpochStatus.EXECUTING, "previous epoch is executing";

    uint256 epochNonce = getPreviousEpochNonce();

    /// @dev revert condition being verified
    require getEpochTotalDepositAmount(epochNonce) <= getEpochTotalWithdrawClaimAmount(epochNonce),
        "previous epoch is not a net deposit";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
}

/// @notice Completing an epoch deposit reverts when the previous net-deposit epoch is not executing.
/// @dev Verifies the shared epoch-finalization status guard.
rule completeEpochDeposit_RevertWhen_PreviousEpochIsNotExecuting() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "completeEpochDeposit is nonpayable";
    require getEpochNonce() > 1, "at least one epoch has completed";

    uint256 epochNonce = getPreviousEpochNonce();
    require getEpochTotalDepositAmount(epochNonce) > getEpochTotalWithdrawClaimAmount(epochNonce),
        "previous epoch is a net deposit";

    /// @dev revert condition being verified
    require getPreviousEpochStatus() != Types.EpochStatus.EXECUTING, "previous epoch is not executing";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
}

/// @notice Completing the previous remote net-deposit epoch makes it claimable.
/// @dev Verifies status transition and EpochClaimable event parameters.
rule completeEpochDeposit_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "completeEpochDeposit is nonpayable";
    require getEpochNonce() > 1, "at least one epoch has completed";

    uint256 currentEpochNonce = getEpochNonce();
    uint256 epochNonce = getPreviousEpochNonce();
    uint256 depositAmountBefore = getEpochTotalDepositAmount(epochNonce);
    uint256 withdrawClaimAmountBefore = getEpochTotalWithdrawClaimAmount(epochNonce);
    uint256 totalSharesBefore = getTotalShares();
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev success conditions being verified
    require getEpochTotalDepositAmount(epochNonce) > getEpochTotalWithdrawClaimAmount(epochNonce),
        "previous epoch is a net deposit";
    require getPreviousEpochStatus() == Types.EpochStatus.EXECUTING, "previous epoch is executing";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    completeEpochDeposit@withrevert(e);

    assert !lastReverted;
    assert getEpochNonce() == currentEpochNonce;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmountBefore;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == withdrawClaimAmountBefore;
    assert getTotalShares() == totalSharesBefore;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// ─────────────────── FINALIZE LOCAL WITHDRAW ────────────────

/// @notice Finalizing local net-withdraw reverts when settled withdraw accounting overflows.
/// @dev Verifies the targeted revert independently of competing conditions.
rule finalizeLocalNetWithdraw_RevertWhen_SettledAmountOverflows() {
    env e;
    uint256 epochNonce;
    uint256 totalDepositAmount;
    uint256 amountOut;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeLocalNetWithdraw is nonpayable";

    /// @dev revert condition being verified
    require totalDepositAmount > max_uint256 - amountOut,
        "settled withdraw claim amount overflows";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";

    finalizeLocalNetWithdraw@withrevert(e, epochNonce, totalDepositAmount, amountOut);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
}

/// @notice Finalizing local net-withdraw makes the epoch claimable with actual adapter output.
/// @dev Verifies settled withdraw accounting, claimable status, and EpochClaimable event.
rule finalizeLocalNetWithdraw_Success() {
    env e;
    uint256 epochNonce;
    uint256 totalDepositAmount;
    uint256 amountOut;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeLocalNetWithdraw is nonpayable";
    require totalDepositAmount <= max_uint256 - amountOut,
        "settled withdraw claim amount does not overflow";

    mathint settledAmount = totalDepositAmount + amountOut;
    uint256 currentEpochNonce = getEpochNonce();
    uint256 depositAmountBefore = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmountBefore = getEpochTotalShareBurnAmount(epochNonce);
    uint256 totalSharesBefore = getTotalShares();
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    finalizeLocalNetWithdraw@withrevert(e, epochNonce, totalDepositAmount, amountOut);

    assert !lastReverted;
    assert getEpochNonce() == currentEpochNonce;
    assert getEpochTotalDepositAmount(epochNonce) == depositAmountBefore;
    assert getEpochTotalShareBurnAmount(epochNonce) == shareBurnAmountBefore;
    assert getTotalShares() == totalSharesBefore;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == settledAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// ─────────────────── OPEN NEXT EPOCH ────────────────────────

/// @notice Opening the next epoch reverts when epoch nonce increment overflows.
/// @dev Verifies the targeted revert independently of competing conditions.
rule openNextEpoch_RevertWhen_EpochNonceOverflows() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "openNextEpoch is nonpayable";

    /// @dev revert condition being verified
    uint256 epochNonce = max_uint256;

    /// @dev ghost starting values
    require ghost_EpochOpen_EventCount == 0, "EpochOpen event count starts at zero";

    openNextEpoch@withrevert(e, epochNonce);

    assert lastReverted;
    assert ghost_EpochOpen_EventCount == 0;
}

/// @notice Opening the next epoch increments the nonce and marks the new epoch open.
/// @dev Verifies nonce write, epoch status, opened timestamp, and EpochOpen event.
rule openNextEpoch_Success() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "openNextEpoch is nonpayable";
    require epochNonce < max_uint256, "epoch nonce increment does not overflow";

    mathint nextEpochNonce = epochNonce + 1;
    uint256 totalSharesBefore = getTotalShares();
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();

    /// @dev ghost starting values
    require ghost_EpochOpen_EventCount == 0, "EpochOpen event count starts at zero";
    require ghost_epochNonce_StoreCount == 0, "epoch nonce store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    openNextEpoch@withrevert(e, epochNonce);

    assert !lastReverted;
    assert getTotalShares() == totalSharesBefore;
    assert getPerformanceFeeHighWaterMark() == highWaterMarkBefore;
    assert getEpochNonce() == nextEpochNonce;
    assert getEpochStatus(getEpochNonce()) == Types.EpochStatus.OPEN;
    assert getEpochOpenedAtTimestamp(getEpochNonce()) == e.block.timestamp;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == nextEpochNonce;
    assert ghost_epochNonce_StoreCount == 1;
    assert ghost_epochNonce_StoredValue == nextEpochNonce;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == nextEpochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.OPEN;
}
