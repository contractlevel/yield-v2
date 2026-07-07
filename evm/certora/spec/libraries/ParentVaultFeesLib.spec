using MockYieldcoinShare as share;

/// Verification of ParentVaultFeesLib
/// @author @contractlevel
/// @notice ParentVaultFeesLib handles ParentVault price-per-share calculation and fee accounting.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getTotalShares() external returns (uint256) envfree;
    function getPerformanceFeeHighWaterMark() external returns (uint256) envfree;
    function getTreasury() external returns (address) envfree;

    // Library internal wrappers
    function calculatePricePerShare(uint256, uint256) external returns (uint256) envfree;
    function collectManagementFee(uint256, uint256) external;
    function collectPerformanceFee(uint256, uint256, uint256, uint256) external returns (uint256);

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;

    // Mock methods
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;

    // Dispatcher summaries
    function _.mint(address, uint256) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition BPS_DENOMINATOR() returns uint256 = 10000;
definition PERFORMANCE_FEE_BPS() returns uint256 = 777;
definition MANAGEMENT_FEE_BPS() returns uint256 = 100;
definition YEAR() returns uint256 = 31536000;
definition SHARE_PRECISION() returns uint256 = 1000000000000;

definition ManagementFeeCollectedEvent() returns bytes32 =
// keccak256("ManagementFeeCollected(uint256,uint256)")
    to_bytes32(0x6f4a589972e181c1010960e6cb88e05776a4f3a28373e49c69ffdf8cc30f1a31);

definition PerformanceFeeCollectedEvent() returns bytes32 =
// keccak256("PerformanceFeeCollected(uint256,uint256,uint256)")
    to_bytes32(0xdc4f167bfca42a54abc7c7dd90ec178ea116a54329d32a1a6cb1c6208d17177c);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice StoreCount: track writes to s_totalShares
ghost mathint ghost_totalShares_StoreCount {
    init_state axiom ghost_totalShares_StoreCount == 0;
}

/// @notice StoredValue: track latest value written to s_totalShares
ghost uint256 ghost_totalShares_StoredValue {
    init_state axiom ghost_totalShares_StoredValue == 0;
}

/// @notice StoreCount: track writes to s_performanceFeeHighWaterMark
ghost mathint ghost_performanceFeeHighWaterMark_StoreCount {
    init_state axiom ghost_performanceFeeHighWaterMark_StoreCount == 0;
}

/// @notice StoredValue: track latest value written to s_performanceFeeHighWaterMark
ghost uint256 ghost_performanceFeeHighWaterMark_StoredValue {
    init_state axiom ghost_performanceFeeHighWaterMark_StoredValue == 0;
}

/// @notice EventCount: track amount ManagementFeeCollected event is emitted
ghost mathint ghost_ManagementFeeCollected_EventCount {
    init_state axiom ghost_ManagementFeeCollected_EventCount == 0;
}

/// @notice EmittedValue: track rebalanceNonce param emitted in ManagementFeeCollected event
ghost uint256 ghost_ManagementFeeCollected_Param_rebalanceNonce {
    init_state axiom ghost_ManagementFeeCollected_Param_rebalanceNonce == 0;
}

/// @notice EmittedValue: track feeShares param emitted in ManagementFeeCollected event
ghost uint256 ghost_ManagementFeeCollected_Param_feeShares {
    init_state axiom ghost_ManagementFeeCollected_Param_feeShares == 0;
}

/// @notice EventCount: track amount PerformanceFeeCollected event is emitted
ghost mathint ghost_PerformanceFeeCollected_EventCount {
    init_state axiom ghost_PerformanceFeeCollected_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in PerformanceFeeCollected event
ghost uint256 ghost_PerformanceFeeCollected_Param_epochNonce {
    init_state axiom ghost_PerformanceFeeCollected_Param_epochNonce == 0;
}

/// @notice EmittedValue: track feeShares param emitted in PerformanceFeeCollected event
ghost uint256 ghost_PerformanceFeeCollected_Param_feeShares {
    init_state axiom ghost_PerformanceFeeCollected_Param_feeShares == 0;
}

/// @notice EmittedValue: track highWaterMark param emitted in PerformanceFeeCollected event
ghost uint256 ghost_PerformanceFeeCollected_Param_highWaterMark {
    init_state axiom ghost_PerformanceFeeCollected_Param_highWaterMark == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto total shares storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_totalShares uint256 newValue {
    ghost_totalShares_StoreCount = ghost_totalShares_StoreCount + 1;
    ghost_totalShares_StoredValue = newValue;
}

/// @notice hook onto performance fee high-water mark storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_performanceFeeHighWaterMark uint256 newValue {
    ghost_performanceFeeHighWaterMark_StoreCount = ghost_performanceFeeHighWaterMark_StoreCount + 1;
    ghost_performanceFeeHighWaterMark_StoredValue = newValue;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == ManagementFeeCollectedEvent()) {
        ghost_ManagementFeeCollected_EventCount = ghost_ManagementFeeCollected_EventCount + 1;
        ghost_ManagementFeeCollected_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_ManagementFeeCollected_Param_feeShares = bytes32ToUint256(t2);
    }
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == PerformanceFeeCollectedEvent()) {
        ghost_PerformanceFeeCollected_EventCount = ghost_PerformanceFeeCollected_EventCount + 1;
        ghost_PerformanceFeeCollected_Param_epochNonce = bytes32ToUint256(t1);
        ghost_PerformanceFeeCollected_Param_feeShares = bytes32ToUint256(t2);
        ghost_PerformanceFeeCollected_Param_highWaterMark = bytes32ToUint256(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── PRICE PER SHARE ────────────────────────

/// @notice Price per share returns share precision when no shares exist.
/// @dev Verifies the bootstrap price branch.
rule calculatePricePerShare_Success_WhenNoShares() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev success conditions being verified
    require getTotalShares() == 0, "no shares exist";

    uint256 pricePerShare = calculatePricePerShare@withrevert(e, tvl, sharePrecision);

    assert !lastReverted;
    assert pricePerShare == sharePrecision;
}

/// @notice Price per share reverts when TVL is zero while shares are outstanding.
/// @dev Verifies the explicit zero-TVL-with-shares branch.
rule calculatePricePerShare_RevertWhen_ZeroTvlWithOutstandingShares() {
    env e;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev revert condition being verified
    require getTotalShares() != 0, "shares are outstanding";
    uint256 tvl = 0;

    storage before = lastStorage;

    calculatePricePerShare@withrevert(e, tvl, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Price per share reverts when TVL and share precision multiplication overflows.
/// @dev Verifies arithmetic overflow in the calculated price branch.
rule calculatePricePerShare_RevertWhen_PriceMultiplicationOverflows() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev revert condition being verified
    require getTotalShares() != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl > max_uint256 / sharePrecision, "price multiplication overflows";

    storage before = lastStorage;

    calculatePricePerShare@withrevert(e, tvl, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Price per share divides TVL value by total shares when both are nonzero.
/// @dev Verifies the calculated price branch.
rule calculatePricePerShare_Success_WhenSharesAndTvlExist() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    uint256 totalShares = getTotalShares();

    /// @dev success conditions being verified
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl <= max_uint256 / sharePrecision, "price multiplication does not overflow";

    uint256 pricePerShare = calculatePricePerShare@withrevert(e, tvl, sharePrecision);
    mathint expectedPricePerShare = tvl * sharePrecision / totalShares;

    assert !lastReverted;
    assert pricePerShare == expectedPricePerShare;
}

/// ─────────────────── MANAGEMENT FEE ─────────────────────────

/// @notice Management fee collection reverts when the completed timestamp is in the future.
/// @dev Verifies elapsed time subtraction underflow.
rule collectManagementFee_RevertWhen_LastCompletedTimestampIsFuture() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";

    /// @dev revert condition being verified
    require lastRebalanceCompletedTimestamp > e.block.timestamp, "last completed timestamp is in the future";

    storage before = lastStorage;

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Management fee collection reverts when initial fee multiplication overflows.
/// @dev Verifies totalShares * MANAGEMENT_FEE_BPS overflow.
rule collectManagementFee_RevertWhen_TotalSharesTimesFeeBpsOverflows() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    /// @dev revert condition being verified
    require getTotalShares() > max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication overflows";

    storage before = lastStorage;

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Management fee collection reverts when elapsed fee multiplication overflows.
/// @dev Verifies totalShares * MANAGEMENT_FEE_BPS * elapsed overflow.
rule collectManagementFee_RevertWhen_TotalSharesFeeProductTimesElapsedOverflows() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    uint256 totalShares = getTotalShares();
    mathint elapsed = e.block.timestamp - lastRebalanceCompletedTimestamp;
    require elapsed <= YEAR(), "elapsed time is not capped";

    /// @dev revert condition being verified
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    mathint product = totalShares * MANAGEMENT_FEE_BPS();
    require elapsed != 0, "elapsed time is nonzero";
    require product > max_uint256 / elapsed, "elapsed fee multiplication overflows";

    storage before = lastStorage;

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Management fee collection reverts when ceil numerator addition overflows.
/// @dev Verifies product + denominator - 1 overflow.
rule collectManagementFee_RevertWhen_CeilNumeratorOverflows() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    uint256 totalShares = getTotalShares();
    mathint elapsed = e.block.timestamp - lastRebalanceCompletedTimestamp;
    require elapsed <= YEAR(), "elapsed time is not capped";

    /// @dev revert condition being verified
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    mathint product = totalShares * MANAGEMENT_FEE_BPS();
    require elapsed == 0 || product <= max_uint256 / elapsed, "elapsed fee multiplication does not overflow";
    mathint numerator = product * elapsed;
    require numerator > max_uint256 - (BPS_DENOMINATOR() * YEAR() - 1), "ceil numerator addition overflows";

    storage before = lastStorage;

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Management fee collection succeeds without minting when calculated fee shares are zero.
/// @dev Verifies no storage write and no event when elapsed time is zero.
rule collectManagementFee_Success_WhenFeeSharesAreZero() {
    env e;
    uint256 rebalanceNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require getTotalShares() <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";

    uint256 totalSharesBefore = getTotalShares();
    uint256 lastRebalanceCompletedTimestamp = e.block.timestamp;

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == totalSharesBefore;
    assert ghost_ManagementFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
}

/// @notice Management fee collection caps elapsed time at one year.
/// @dev Verifies fee shares use the one-year cap and emit ManagementFeeCollected when nonzero.
rule collectManagementFee_Success_WhenElapsedTimeExceedsOneYear() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";
    require e.block.timestamp - lastRebalanceCompletedTimestamp > YEAR(), "elapsed time exceeds one year";

    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * YEAR();
    mathint feeShares = (numerator + denominator - 1) / denominator;

    /// @dev success conditions being verified
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / YEAR(), "elapsed fee multiplication does not overflow";
    require numerator <= max_uint256 - (denominator - 1), "ceil numerator addition does not overflow";
    require feeShares != 0, "fee shares are nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    require share.balanceOf(treasury) <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == totalShares + feeShares;
    assert share.balanceOf(treasury) >= feeShares;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + feeShares;
}

/// @notice Management fee collection succeeds for uncapped elapsed time when fee shares are nonzero.
/// @dev Verifies storage write and ManagementFeeCollected event parameters.
rule collectManagementFee_Success_WhenFeeSharesAreNonzero() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    mathint elapsed = e.block.timestamp - lastRebalanceCompletedTimestamp;
    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * elapsed;
    mathint feeShares = (numerator + denominator - 1) / denominator;

    /// @dev success conditions being verified
    require elapsed <= YEAR(), "elapsed time is not capped";
    require elapsed != 0, "elapsed time is nonzero";
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / elapsed,
        "elapsed fee multiplication does not overflow";
    require numerator <= max_uint256 - (denominator - 1), "ceil numerator addition does not overflow";
    require feeShares != 0, "fee shares are nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    require share.balanceOf(treasury) <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == totalShares + feeShares;
    assert share.balanceOf(treasury) >= feeShares;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + feeShares;
}

/// ─────────────────── PERFORMANCE FEE ────────────────────────

/// @notice Performance fee collection returns the gross price when it does not exceed the high-water mark.
/// @dev Verifies no fee storage or event side effects.
rule collectPerformanceFee_Success_WhenGrossPriceDoesNotExceedHighWaterMark() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    /// @dev success conditions being verified
    require grossPricePerShare <= getPerformanceFeeHighWaterMark(), "gross price does not exceed high-water mark";

    /// @dev ghost starting values
    require ghost_PerformanceFeeCollected_EventCount == 0, "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_performanceFeeHighWaterMark_StoreCount == 0,
        "performance fee high-water mark store count starts at zero";

    uint256 settlementPricePerShare =
        collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert !lastReverted;
    assert settlementPricePerShare == grossPricePerShare;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
    assert ghost_performanceFeeHighWaterMark_StoreCount == 0;
}

/// @notice Performance fee collection reverts when yield value multiplication overflows.
/// @dev Verifies yieldPerShare * totalShares overflow.
rule collectPerformanceFee_RevertWhen_TotalYieldMultiplicationOverflows() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev revert condition being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare > max_uint256 / totalShares, "total yield multiplication overflows";

    storage before = lastStorage;

    collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Performance fee collection returns gross price when the fee would consume TVL.
/// @dev Verifies fee >= tvl branch skips minting and high-water mark update.
rule collectPerformanceFee_Success_WhenFeeConsumesTvl() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev success conditions being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare <= max_uint256 / totalShares, "total yield multiplication does not overflow";
    mathint totalYield = (yieldPerShare * totalShares + sharePrecision - 1) / sharePrecision;
    require totalYield <= max_uint256 / PERFORMANCE_FEE_BPS(), "fee multiplication does not overflow";
    mathint fee = (totalYield * PERFORMANCE_FEE_BPS() + BPS_DENOMINATOR() - 1) / BPS_DENOMINATOR();
    require fee >= tvl, "fee consumes TVL";

    /// @dev ghost starting values
    require ghost_PerformanceFeeCollected_EventCount == 0, "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_performanceFeeHighWaterMark_StoreCount == 0,
        "performance fee high-water mark store count starts at zero";

    uint256 settlementPricePerShare =
        collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert !lastReverted;
    assert settlementPricePerShare == grossPricePerShare;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
    assert ghost_performanceFeeHighWaterMark_StoreCount == 0;
}

/// @notice Performance fee collection reverts when fee share calculation multiplication overflows.
/// @dev Verifies fee * totalShares overflow.
rule collectPerformanceFee_RevertWhen_FeeSharesMultiplicationOverflows() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev revert condition being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare <= max_uint256 / totalShares, "total yield multiplication does not overflow";
    mathint totalYield = (yieldPerShare * totalShares + sharePrecision - 1) / sharePrecision;
    require totalYield <= max_uint256 / PERFORMANCE_FEE_BPS(), "fee multiplication does not overflow";
    mathint fee = (totalYield * PERFORMANCE_FEE_BPS() + BPS_DENOMINATOR() - 1) / BPS_DENOMINATOR();
    require fee < tvl, "fee is below TVL";
    require fee > max_uint256 / totalShares, "fee shares multiplication overflows";

    storage before = lastStorage;

    collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Performance fee collection succeeds without minting when fee shares are zero.
/// @dev Verifies high-water mark update without total share write or event.
rule collectPerformanceFee_Success_WhenFeeSharesAreZero() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev success conditions being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares == 0, "no shares are outstanding";
    require tvl != 0, "tvl is nonzero";

    /// @dev ghost starting values
    require ghost_PerformanceFeeCollected_EventCount == 0, "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_performanceFeeHighWaterMark_StoreCount == 0,
        "performance fee high-water mark store count starts at zero";

    uint256 settlementPricePerShare =
        collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert !lastReverted;
    assert settlementPricePerShare == sharePrecision;
    assert getPerformanceFeeHighWaterMark() == sharePrecision;
    assert ghost_PerformanceFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
    assert ghost_performanceFeeHighWaterMark_StoreCount == 1;
    assert ghost_performanceFeeHighWaterMark_StoredValue == sharePrecision;
}

/// @notice Performance fee collection reverts when total shares plus fee shares overflows.
/// @dev Verifies fee share minting total share overflow.
rule collectPerformanceFee_RevertWhen_TotalSharesAdditionOverflows() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev revert condition being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare <= max_uint256 / totalShares, "total yield multiplication does not overflow";
    mathint totalYield = (yieldPerShare * totalShares + sharePrecision - 1) / sharePrecision;
    require totalYield <= max_uint256 / PERFORMANCE_FEE_BPS(), "fee multiplication does not overflow";
    mathint fee = (totalYield * PERFORMANCE_FEE_BPS() + BPS_DENOMINATOR() - 1) / BPS_DENOMINATOR();
    require fee < tvl, "fee is below TVL";
    require fee <= max_uint256 / totalShares, "fee share multiplication does not overflow";
    mathint feeShares = (fee * totalShares + (tvl - fee) - 1) / (tvl - fee);
    require feeShares != 0, "fee shares are nonzero";
    require totalShares > max_uint256 - feeShares, "total shares addition overflows";

    storage before = lastStorage;

    collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Performance fee collection reverts when settlement price multiplication overflows.
/// @dev Verifies the final price-per-share calculation overflow after fee shares are applied.
rule collectPerformanceFee_RevertWhen_SettlementPriceMultiplicationOverflows() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();

    /// @dev revert condition being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare <= max_uint256 / totalShares, "total yield multiplication does not overflow";
    mathint totalYield = (yieldPerShare * totalShares + sharePrecision - 1) / sharePrecision;
    require totalYield <= max_uint256 / PERFORMANCE_FEE_BPS(), "fee multiplication does not overflow";
    mathint fee = (totalYield * PERFORMANCE_FEE_BPS() + BPS_DENOMINATOR() - 1) / BPS_DENOMINATOR();
    require fee < tvl, "fee is below TVL";
    require fee <= max_uint256 / totalShares, "fee share multiplication does not overflow";
    mathint feeShares = (fee * totalShares + (tvl - fee) - 1) / (tvl - fee);
    require feeShares != 0, "fee shares are nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    require share.balanceOf(treasury) <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";
    require tvl > max_uint256 / sharePrecision, "settlement price multiplication overflows";

    storage before = lastStorage;

    collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Performance fee collection succeeds when fee shares are minted.
/// @dev Verifies returned settlement price, storage writes, minting, and PerformanceFeeCollected event.
rule collectPerformanceFee_Success_WhenFeeSharesAreNonzero() {
    env e;
    uint256 epochNonce;
    uint256 tvl;
    uint256 grossPricePerShare;
    uint256 sharePrecision = SHARE_PRECISION();
    address treasury = getTreasury();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectPerformanceFee is nonpayable";

    uint256 highWaterMark = getPerformanceFeeHighWaterMark();
    uint256 totalShares = getTotalShares();

    /// @dev success conditions being verified
    require grossPricePerShare > highWaterMark, "gross price exceeds high-water mark";
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    mathint yieldPerShare = grossPricePerShare - highWaterMark;
    require yieldPerShare <= max_uint256 / totalShares, "total yield multiplication does not overflow";
    mathint totalYield = (yieldPerShare * totalShares + sharePrecision - 1) / sharePrecision;
    require totalYield <= max_uint256 / PERFORMANCE_FEE_BPS(), "fee multiplication does not overflow";
    mathint fee = (totalYield * PERFORMANCE_FEE_BPS() + BPS_DENOMINATOR() - 1) / BPS_DENOMINATOR();
    require fee < tvl, "fee is below TVL";
    require fee <= max_uint256 / totalShares, "fee share multiplication does not overflow";
    mathint feeShares = (fee * totalShares + (tvl - fee) - 1) / (tvl - fee);
    require feeShares != 0, "fee shares are nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    mathint newTotalShares = totalShares + feeShares;
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    require treasuryBalanceBefore <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";
    require tvl <= max_uint256 / sharePrecision, "settlement price multiplication does not overflow";

    /// @dev ghost starting values
    require ghost_PerformanceFeeCollected_EventCount == 0, "PerformanceFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";
    require ghost_performanceFeeHighWaterMark_StoreCount == 0,
        "performance fee high-water mark store count starts at zero";

    uint256 returnedSettlementPricePerShare =
        collectPerformanceFee@withrevert(e, epochNonce, tvl, grossPricePerShare, sharePrecision);

    assert !lastReverted;
    assert getTotalShares() == newTotalShares;
    assert getPerformanceFeeHighWaterMark() == returnedSettlementPricePerShare;
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == newTotalShares;
    assert ghost_performanceFeeHighWaterMark_StoreCount == 1;
    assert ghost_performanceFeeHighWaterMark_StoredValue == returnedSettlementPricePerShare;
    assert ghost_PerformanceFeeCollected_EventCount == 1;
    assert ghost_PerformanceFeeCollected_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_Param_feeShares == feeShares;
    assert ghost_PerformanceFeeCollected_Param_highWaterMark == returnedSettlementPricePerShare;
}
