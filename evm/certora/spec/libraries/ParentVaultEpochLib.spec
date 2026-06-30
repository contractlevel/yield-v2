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
    function getEpochClosedAtTimestamp(uint256) external returns (uint256) envfree;
    function getEpochStatus(uint256) external returns (Types.EpochStatus) envfree;

    // Library internal wrappers
    function closeEpoch(uint256, uint256, uint256, bool) external returns (uint256, uint8, uint256);
    function finalizeLocalNetWithdraw(uint256, uint256) external;
    function openNextEpoch() external;

    // Mock methods
    function share.balanceOf(address) external returns (uint256) envfree;

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

definition EpochExecutingEvent() returns bytes32 =
// keccak256("EpochExecuting(uint256,uint256)")
    to_bytes32(0x30e0436ea7b69c1a8f2e5bb2b2257e44265bbf353d198f3823c1726fe558f0cd);

definition EpochClaimableEvent() returns bytes32 =
// keccak256("EpochClaimable(uint256)")
    to_bytes32(0x45d9681f238e455170e797872754deaef148c9e7836f9949104764a4f4cfae8a);

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

/// @notice EventCount: track amount EpochExecuting event is emitted
ghost mathint ghost_EpochExecuting_EventCount {
    init_state axiom ghost_EpochExecuting_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochExecuting event
ghost uint256 ghost_EpochExecuting_Param_epochNonce {
    init_state axiom ghost_EpochExecuting_Param_epochNonce == 0;
}

/// @notice EmittedValue: track amount param emitted in EpochExecuting event
ghost uint256 ghost_EpochExecuting_Param_amount {
    init_state axiom ghost_EpochExecuting_Param_amount == 0;
}

/// @notice EventCount: track amount EpochClaimable event is emitted
ghost mathint ghost_EpochClaimable_EventCount {
    init_state axiom ghost_EpochClaimable_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochClaimable event
ghost uint256 ghost_EpochClaimable_Param_epochNonce {
    init_state axiom ghost_EpochClaimable_Param_epochNonce == 0;
}

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
    if (t0 == EpochExecutingEvent()) {
        ghost_EpochExecuting_EventCount = ghost_EpochExecuting_EventCount + 1;
        ghost_EpochExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochExecuting_Param_amount = bytes32ToUint256(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── CLOSE EPOCH REVERTS ────────────────────

/// @notice Closing an epoch reverts when a rebalance is in progress.
/// @dev Verifies that ParentVault storage is unchanged.
rule closeEpoch_RevertWhen_RebalanceInProgress() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";

    /// @dev revert condition being verified
    require getRebalanceState() != Types.RebalanceState.NONE, "rebalance is in progress";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the current epoch nonce is zero.
/// @dev Verifies that previous epoch nonce arithmetic underflow leaves ParentVault storage unchanged.
rule closeEpoch_RevertWhen_CurrentEpochNonceIsZero() {
    env e;
    uint256 tvl;
    uint256 sharePrecision;
    uint256 minDepositAmount;
    bool isLocalStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "closeEpoch is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "rebalance is not in progress";

    /// @dev revert condition being verified
    require getEpochNonce() == 0, "current epoch nonce is zero";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the previous nonzero epoch is not claimable.
/// @dev Verifies that ParentVault storage is unchanged.
rule closeEpoch_RevertWhen_PreviousEpochNotClaimable() {
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

    /// @dev revert condition being verified
    require getEpochStatus(previousEpochNonce) != Types.EpochStatus.CLAIMABLE, "previous epoch is not claimable";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the current epoch is not open.
/// @dev Verifies that ParentVault storage is unchanged.
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

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the open timestamp plus the minimum period overflows.
/// @dev Verifies that ParentVault storage is unchanged.
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the minimum epoch period has not elapsed.
/// @dev Verifies that ParentVault storage is unchanged.
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when it has no deposits and no share burns.
/// @dev Verifies that ParentVault storage is unchanged.
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when TVL is zero while shares are outstanding.
/// @dev Verifies that ParentVault storage is unchanged.
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
    require getEpochTotalDepositAmount(epochNonce) != 0 || getEpochTotalShareBurnAmount(epochNonce) != 0,
        "epoch is not empty";
    require getTotalShares() != 0, "shares are outstanding";
    require sharePrecision != 0, "share precision is nonzero";
    uint256 tvl = 0;

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    mathint grossPricePerShare = tvl * sharePrecision / totalShares;
    require grossPricePerShare != 0, "gross price per share is nonzero";
    require getPerformanceFeeHighWaterMark() >= grossPricePerShare, "performance fee is not collected";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 / sharePrecision,
        "new share calculation does not overflow";
    mathint newShares = getEpochTotalDepositAmount(epochNonce) * sharePrecision / grossPricePerShare;

    uint256 minDepositAmount = 1000000;
    require newShares <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";
    require newShares * minDepositAmount < getEpochTotalDepositAmount(epochNonce), "deposits mint zero shares";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when share precision is zero.
/// @dev Verifies the division-by-zero path after early epoch preconditions pass.
rule closeEpoch_RevertWhen_SharePrecisionIsZero() {
    env e;
    uint256 tvl;
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
    require getTotalShares() == 0, "bootstrap price per share path";
    uint256 sharePrecision = 0;

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when gross price per share multiplication overflows.
/// @dev Verifies the price-per-share arithmetic overflow path.
rule closeEpoch_RevertWhen_GrossPricePerShareOverflows() {
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
    require getEpochTotalDepositAmount(epochNonce) != 0 || getEpochTotalShareBurnAmount(epochNonce) != 0,
        "epoch is not empty";
    require getTotalShares() != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require sharePrecision != 0, "share precision is nonzero";
    require tvl > max_uint256 / sharePrecision, "gross price per share multiplication overflows";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when total withdraw calculation overflows.
/// @dev Verifies the share-burn settlement multiplication overflow path.
rule closeEpoch_RevertWhen_TotalWithdrawOverflows() {
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
    uint256 totalShares = getTotalShares();
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require shareBurnAmount != 0, "shares are burned";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";
    require shareBurnAmount > max_uint256 / sharePrecision, "total withdraw multiplication overflows";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when new-share calculation overflows.
/// @dev Verifies deposit share mint calculation multiplication overflow.
rule closeEpoch_RevertWhen_NewSharesOverflows() {
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
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require depositAmount != 0, "total deposit amount is nonzero";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require getEpochTotalShareBurnAmount(epochNonce) == 0, "no shares are burned";
    require sharePrecision != 0, "share precision is nonzero";
    require depositAmount > max_uint256 / sharePrecision, "new share calculation overflows";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    uint256 tvl = 0;
    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when settlement price per share is zero.
/// @dev Verifies the new-share division-by-zero path.
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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
    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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
    require getEpochTotalDepositAmount(epochNonce) == 0, "no deposits were made";
    require shareBurnAmount != 0, "shares are burned";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require shareBurnAmount > totalShares, "total shares subtraction underflows";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── CLOSE EPOCH SUCCESS ────────────────────

/// @notice Closing a balanced epoch makes it claimable and returns no external action.
/// @dev Verifies the net-zero branch while fee collection is not active.
rule closeEpoch_Success_WhenNetFlowIsZero() {
    env e;
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
    uint256 depositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 shareBurnAmount = getEpochTotalShareBurnAmount(epochNonce);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";
    require depositAmount != 0, "epoch is not empty";
    require depositAmount == shareBurnAmount, "net flow is zero";
    require depositAmount <= max_uint256 / sharePrecision, "share calculation does not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount fits int256";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares <= max_uint256 - depositAmount, "total shares addition does not overflow";
    uint256 minDepositAmount = 1000000;
    require depositAmount <= max_uint256 / minDepositAmount, "zero-share guard multiplication does not overflow";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount;
    (returnedEpochNonce, returnedAction, returnedAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_NONE();
    assert returnedAmount == 0;
    assert getTotalShares() == totalShares;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert getEpochPricePerShare(epochNonce) == sharePrecision;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == depositAmount;
    assert getEpochRemainingShareBurnAmount(epochNonce) == shareBurnAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == shareBurnAmount;
    assert getEpochClosedAtTimestamp(epochNonce) == e.block.timestamp;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// @notice Closing a net-deposit epoch returns a local strategy deposit action when the strategy is local.
/// @dev Verifies the positive-net-flow local branch while fee collection is not active.
rule closeEpoch_Success_WhenLocalNetDeposit() {
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

    bool isLocalStrategy = true;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount;
    (returnedEpochNonce, returnedAction, returnedAmount) =
        closeEpoch@withrevert(e, 0, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_DEPOSIT_TO_LOCAL_STRATEGY();
    assert returnedAmount == depositAmount;
    assert getTotalShares() == depositAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
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

    bool isLocalStrategy = false;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount;
    (returnedEpochNonce, returnedAction, returnedAmount) =
        closeEpoch@withrevert(e, 0, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_SEND_DEPOSIT_TO_REMOTE_STRATEGY();
    assert returnedAmount == depositAmount;
    assert getTotalShares() == depositAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
}

/// @notice Closing a net-withdraw epoch returns a local strategy withdraw action when the strategy is local.
/// @dev Verifies the negative-net-flow local branch while fee collection is not active.
rule closeEpoch_Success_WhenLocalNetWithdraw() {
    env e;
    uint256 sharePrecision;

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

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";
    require getEpochTotalDepositAmount(epochNonce) == 0, "no deposits were made";
    require shareBurnAmount != 0, "shares are burned";
    require shareBurnAmount <= max_uint256 / sharePrecision, "withdraw calculation does not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares >= shareBurnAmount, "total shares subtraction does not underflow";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_EpochExecuting_EventCount == 0, "EpochExecuting event count starts at zero";

    bool isLocalStrategy = true;
    uint256 minDepositAmount = 1000000;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount;
    (returnedEpochNonce, returnedAction, returnedAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_WITHDRAW_FROM_LOCAL_STRATEGY();
    assert returnedAmount == shareBurnAmount;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.OPEN;
    assert ghost_EpochClaimable_EventCount == 0;
    assert ghost_EpochExecuting_EventCount == 0;
}

/// @notice Closing a net-withdraw epoch returns a remote wait action when the strategy is remote.
/// @dev Verifies the negative-net-flow remote branch, executing status, and EpochExecuting event.
rule closeEpoch_Success_WhenRemoteNetWithdraw() {
    env e;
    uint256 sharePrecision;

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

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getEpochOpenedAtTimestamp(epochNonce) <= max_uint256 - minEpochPeriod,
        "minimum epoch period addition does not overflow";
    require e.block.timestamp >= getEpochOpenedAtTimestamp(epochNonce) + minEpochPeriod,
        "minimum epoch period has elapsed";
    require sharePrecision != 0, "share precision is nonzero";
    require totalShares != 0, "shares are outstanding";
    require totalShares <= max_uint256 / sharePrecision, "gross price per share does not overflow";
    uint256 tvl = totalShares;
    require getPerformanceFeeHighWaterMark() >= sharePrecision, "performance fee is not collected";
    require getEpochTotalDepositAmount(epochNonce) == 0, "no deposits were made";
    require shareBurnAmount != 0, "shares are burned";
    require shareBurnAmount <= max_uint256 / sharePrecision, "withdraw calculation does not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount fits int256";
    require totalShares >= shareBurnAmount, "total shares subtraction does not underflow";

    /// @dev ghost starting values
    require ghost_EpochExecuting_EventCount == 0, "EpochExecuting event count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bool isLocalStrategy = false;
    uint256 minDepositAmount = 1000000;
    uint256 returnedEpochNonce; uint8 returnedAction; uint256 returnedAmount;
    (returnedEpochNonce, returnedAction, returnedAmount) =
        closeEpoch@withrevert(e, tvl, sharePrecision, minDepositAmount, isLocalStrategy);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert returnedAction == ACTION_WAIT_FOR_REMOTE_WITHDRAW();
    assert returnedAmount == shareBurnAmount;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING;
    assert ghost_EpochExecuting_EventCount == 1;
    assert ghost_EpochExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochExecuting_Param_amount == shareBurnAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.EXECUTING;
}

/// ─────────────────── FINALIZE LOCAL WITHDRAW ────────────────

/// @notice Finalizing local net-withdraw reverts when settled withdraw accounting overflows.
/// @dev Verifies that ParentVault storage is unchanged.
rule finalizeLocalNetWithdraw_RevertWhen_SettledAmountOverflows() {
    env e;
    uint256 epochNonce;
    uint256 amountOut;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeLocalNetWithdraw is nonpayable";

    /// @dev revert condition being verified
    require getEpochTotalDepositAmount(epochNonce) > max_uint256 - amountOut,
        "settled withdraw claim amount overflows";

    storage before = lastStorage;

    finalizeLocalNetWithdraw@withrevert(e, epochNonce, amountOut);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Finalizing local net-withdraw makes the epoch claimable with actual adapter output.
/// @dev Verifies settled withdraw accounting, claimable status, and EpochClaimable event.
rule finalizeLocalNetWithdraw_Success() {
    env e;
    uint256 epochNonce;
    uint256 amountOut;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeLocalNetWithdraw is nonpayable";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 - amountOut,
        "settled withdraw claim amount does not overflow";

    mathint settledAmount = getEpochTotalDepositAmount(epochNonce) + amountOut;

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    finalizeLocalNetWithdraw@withrevert(e, epochNonce, amountOut);

    assert !lastReverted;
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
/// @dev Verifies that ParentVault storage is unchanged.
rule openNextEpoch_RevertWhen_EpochNonceOverflows() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "openNextEpoch is nonpayable";

    /// @dev revert condition being verified
    require getEpochNonce() == max_uint256, "epoch nonce increment overflows";

    storage before = lastStorage;

    openNextEpoch@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Opening the next epoch increments the nonce and marks the new epoch open.
/// @dev Verifies nonce write, epoch status, opened timestamp, and EpochOpen event.
rule openNextEpoch_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "openNextEpoch is nonpayable";
    require getEpochNonce() < max_uint256, "epoch nonce increment does not overflow";

    uint256 previousEpochNonce = getEpochNonce();
    mathint nextEpochNonce = previousEpochNonce + 1;

    /// @dev ghost starting values
    require ghost_EpochOpen_EventCount == 0, "EpochOpen event count starts at zero";
    require ghost_epochNonce_StoreCount == 0, "epoch nonce store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    openNextEpoch@withrevert(e);

    assert !lastReverted;
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
