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
    function getTreasury() external returns (address) envfree;

    // Library internal wrappers
    function calculatePricePerShare(uint256, uint256, uint256) external returns (uint256) envfree;
    function calculatePricePerSharePublic(uint256, uint256, uint256) external returns (uint256) envfree;
    function calculateNewShares(uint256, uint256, uint256, uint256, uint256)
        external returns (uint256) envfree;
    function collectManagementFee(uint256, uint256) external;
    function collectManagementFeePublic(uint256, uint256) external;

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
definition MANAGEMENT_FEE_BPS() returns uint256 = 100;
definition YEAR() returns uint256 = 31536000;
definition SHARE_PRECISION() returns uint256 = 1000000000000;
definition ASSET_PRECISION() returns uint256 = 1000000;
definition ASSET_PRECISION_PLUS_ONE() returns uint256 = 1000001;

definition ManagementFeeCollectedEvent() returns bytes32 =
// keccak256("ManagementFeeCollected(uint256,uint256)")
    to_bytes32(0x6f4a589972e181c1010960e6cb88e05776a4f3a28373e49c69ffdf8cc30f1a31);

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

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto total shares storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_totalShares uint256 newValue {
    ghost_totalShares_StoreCount = ghost_totalShares_StoreCount + 1;
    ghost_totalShares_StoredValue = newValue;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == ManagementFeeCollectedEvent()) {
        ghost_ManagementFeeCollected_EventCount = ghost_ManagementFeeCollected_EventCount + 1;
        ghost_ManagementFeeCollected_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_ManagementFeeCollected_Param_feeShares = bytes32ToUint256(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── PUBLIC FORWARDERS ──────────────────────

/// @notice The public price wrapper reads stored total shares and forwards both precisions.
/// @dev Verifies the public library boundary independently of the internal calculation rules.
rule calculatePricePerSharePublic_ForwardsStoredTotalSharesAndPrecisions() {
    env e;
    uint256 tvl = ASSET_PRECISION();
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerSharePublic is nonpayable";
    require getTotalShares() == sharePrecision, "stored total shares equal share precision";

    /// @dev ghost starting values
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    uint256 pricePerShare = calculatePricePerSharePublic@withrevert(e, tvl, sharePrecision, assetPrecision);

    assert !lastReverted;
    assert pricePerShare == assetPrecision;
    assert ghost_totalShares_StoreCount == 0;
}

/// @notice The public management-fee wrapper forwards nonce, timestamp, share, and vault storage.
/// @dev Verifies an exact one-year fee collection through the public library boundary.
rule collectManagementFeePublic_ForwardsParametersAndStorage() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;
    uint256 totalShares = BPS_DENOMINATOR();
    mathint feeShares = MANAGEMENT_FEE_BPS();
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFeePublic is nonpayable";
    require e.block.timestamp >= YEAR(), "timestamp covers one year";
    require lastRebalanceCompletedTimestamp == e.block.timestamp - YEAR(), "elapsed time is one year";
    require getTotalShares() == totalShares, "stored total shares are fixed";
    require treasury != 0, "treasury is configured";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    require treasuryBalanceBefore <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require totalSupplyBefore <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFeePublic@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == totalShares + feeShares;
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert share.totalSupply() == totalSupplyBefore + feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + feeShares;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
}

/// ─────────────────── PRICE PER SHARE ────────────────────────

/// @notice Price per share returns asset precision when no shares exist.
/// @dev Verifies the bootstrap price branch.
rule EPOCH_017_calculatePricePerShare_Success_WhenNoShares() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev success conditions being verified
    require getTotalShares() == 0, "no shares exist";

    /// @dev ghost starting values
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    uint256 pricePerShare = calculatePricePerShare@withrevert(e, tvl, sharePrecision, assetPrecision);

    assert !lastReverted;
    assert pricePerShare == assetPrecision;
    assert ghost_totalShares_StoreCount == 0;
}

/// @notice Price per share reverts when TVL is zero while shares are outstanding.
/// @dev Verifies the explicit zero-TVL-with-shares branch.
rule EPOCH_017_calculatePricePerShare_RevertWhen_ZeroTvlWithOutstandingShares() {
    env e;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev revert condition being verified
    require getTotalShares() != 0, "shares are outstanding";
    uint256 tvl = 0;

    calculatePricePerShare@withrevert(e, tvl, sharePrecision, assetPrecision);

    assert lastReverted;
}

/// @notice Price per share reverts when the calculated nonzero-TVL price rounds down to zero.
/// @dev Verifies ParentVault__ZeroPricePerShare independently of the zero-TVL guard.
rule EPOCH_017_calculatePricePerShare_RevertWhen_CalculatedPriceIsZero() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    /// @dev revert conditions NOT being verified
    require getTotalShares() != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    require tvl <= max_uint256 / sharePrecision, "price product does not overflow";

    /// @dev revert condition being verified
    require tvl * sharePrecision < getTotalShares(), "calculated price rounds down to zero";

    calculatePricePerShare@withrevert(e, tvl, sharePrecision, assetPrecision);

    assert lastReverted;
}

/// @notice Price per share reverts when the full-precision quotient exceeds uint256.
/// @dev Verifies the Solady fullMulDiv result-overflow branch with a concrete witness.
rule calculatePricePerShare_RevertWhen_ResultOverflows() {
    env e;
    uint256 tvl = max_uint256;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";
    require getTotalShares() == 1, "one share is outstanding";
    require tvl != 0, "tvl is nonzero";

    /// @dev revert condition being verified
    /// @dev Solady fullMulDiv reconstructs a 512-bit product in assembly using mulmod.
    ///      Certora does not reliably preserve that relationship for fully symbolic operands,
    ///      so this rule uses a concrete input whose quotient necessarily exceeds uint256.

    calculatePricePerShare@withrevert(e, tvl, sharePrecision, assetPrecision);

    assert lastReverted;
}

/// @notice Price per share divides TVL value by total shares when both are nonzero.
/// @dev Verifies the calculated price branch.
rule EPOCH_017_calculatePricePerShare_Success_WhenSharesAndTvlExist() {
    env e;
    uint256 tvl;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculatePricePerShare is nonpayable";

    uint256 totalShares = getTotalShares();

    /// @dev success conditions being verified
    require totalShares != 0, "shares are outstanding";
    require tvl != 0, "tvl is nonzero";
    /// @dev Restrict inputs to Solady fullMulDiv's directly modeled 256-bit multiplication path.
    ///      The 512-bit assembly path uses mulmod and cannot be reliably checked with arbitrary
    ///      symbolic operands.
    require tvl <= max_uint256 / sharePrecision, "price product does not overflow";
    require tvl * sharePrecision >= totalShares, "calculated price is nonzero";

    /// @dev ghost starting values
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    uint256 pricePerShare = calculatePricePerShare@withrevert(e, tvl, sharePrecision, assetPrecision);
    mathint expectedPricePerShare = tvl * sharePrecision / totalShares;

    assert !lastReverted;
    assert pricePerShare == expectedPricePerShare;
    assert ghost_totalShares_StoreCount == 0;
}

/// ─────────────────── NEW SHARE CALCULATION ──────────────────

/// @notice New shares use one full-precision deposit/share-supply division.
/// @dev The concrete witness has a price between asset units, where the former
///      chained floor divisions produced a materially larger mint amount.
rule calculateNewShares_Success_WhenSharesAndTvlExist() {
    env e;
    uint256 tvl;
    uint256 depositAmount;
    uint256 totalShares;
    uint256 sharePrecision = 1000000000000000000;
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculateNewShares is nonpayable";

    /// @dev success conditions being verified
    require tvl != 0, "tvl is nonzero";
    require totalShares != 0, "shares are outstanding";
    require depositAmount <= max_uint256 / totalShares, "share calculation does not overflow";
    mathint expectedNewShares = depositAmount * totalShares / tvl;

    uint256 newShares = calculateNewShares@withrevert(
        e, tvl, depositAmount, totalShares, sharePrecision, assetPrecision
    );

    assert !lastReverted;
    assert newShares == expectedNewShares;
}

/// @notice New shares use bootstrap pricing when no shares exist.
rule calculateNewShares_Success_WhenNoShares() {
    env e;
    uint256 tvl;
    uint256 depositAmount;
    uint256 totalShares = 0;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculateNewShares is nonpayable";

    /// @dev success conditions being verified
    require assetPrecision != 0, "bootstrap asset precision is nonzero";
    require depositAmount * sharePrecision / assetPrecision <= max_uint256,
        "bootstrap share calculation does not overflow";
    mathint expectedNewShares = depositAmount * sharePrecision / assetPrecision;
    uint256 newShares = calculateNewShares@withrevert(
        e, tvl, depositAmount, totalShares, sharePrecision, assetPrecision
    );

    assert !lastReverted;
    assert newShares == expectedNewShares;
}

/// @notice New-share calculation reverts when TVL is zero with outstanding shares.
rule EPOCH_017_calculateNewShares_RevertWhen_ZeroTvlWithOutstandingShares() {
    env e;
    uint256 tvl = 0;
    uint256 depositAmount;
    uint256 totalShares;
    uint256 sharePrecision = SHARE_PRECISION();
    uint256 assetPrecision = ASSET_PRECISION();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "calculateNewShares is nonpayable";

    /// @dev revert condition being verified
    require totalShares != 0, "shares should be outstanding";

    calculateNewShares@withrevert(e, tvl, depositAmount, totalShares, sharePrecision, assetPrecision);

    assert lastReverted;
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

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert ghost_ManagementFeeCollected_EventCount == 0;
}

/// @notice Management fee collection reverts when adding fee shares to total shares overflows.
/// @dev Verifies the checked s_totalShares ledger addition.
rule collectManagementFee_RevertWhen_TotalSharesAdditionOverflows() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    uint256 totalShares = getTotalShares();
    mathint elapsed = e.block.timestamp - lastRebalanceCompletedTimestamp;
    require totalShares == max_uint256, "total shares are maximal";
    require e.block.timestamp >= YEAR(), "timestamp covers one year";
    require elapsed == YEAR(), "elapsed time is one year";
    mathint multiplier = MANAGEMENT_FEE_BPS() * elapsed;
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint feeShares = (totalShares * multiplier + denominator - 1) / denominator;
    require share.balanceOf(getTreasury()) <= max_uint256 - feeShares,
        "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev revert condition being verified
    require feeShares != 0, "fee shares are nonzero";
    require totalShares > max_uint256 - feeShares, "total shares addition overflows";

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert lastReverted;
    assert ghost_ManagementFeeCollected_EventCount == 0;
}

/// @notice Management fee collection succeeds without minting when calculated fee shares are zero.
/// @dev Verifies no storage write and no event when elapsed time is zero.
rule FEE_002_collectManagementFee_Success_WhenFeeSharesAreZero() {
    env e;
    uint256 rebalanceNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    uint256 totalSharesBefore = getTotalShares();
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();
    uint256 lastRebalanceCompletedTimestamp = e.block.timestamp;

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == totalSharesBefore;
    assert share.balanceOf(treasury) == treasuryBalanceBefore;
    assert share.totalSupply() == totalSupplyBefore;
    assert ghost_ManagementFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
}

/// @notice Management fee collection succeeds without minting when no shares exist.
/// @dev Verifies a nonzero elapsed period still produces zero fee shares from a zero share ledger.
rule FEE_002_collectManagementFee_Success_WhenNoShares() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";
    require e.block.timestamp - lastRebalanceCompletedTimestamp != 0, "elapsed time is nonzero";

    uint256 totalSharesBefore = getTotalShares();
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();

    /// @dev success conditions being verified
    require totalSharesBefore == 0, "no shares exist";

    /// @dev ghost starting values
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";
    require ghost_totalShares_StoreCount == 0, "total shares store count starts at zero";

    collectManagementFee@withrevert(e, rebalanceNonce, lastRebalanceCompletedTimestamp);

    assert !lastReverted;
    assert getTotalShares() == 0;
    assert share.balanceOf(treasury) == treasuryBalanceBefore;
    assert share.totalSupply() == totalSupplyBefore;
    assert ghost_ManagementFeeCollected_EventCount == 0;
    assert ghost_totalShares_StoreCount == 0;
}

/// @notice Management fee collection caps elapsed time at one year.
/// @dev Verifies fee shares use the one-year cap and emit ManagementFeeCollected when nonzero.
rule FEE_001_FEE_002_collectManagementFee_Success_WhenElapsedTimeExceedsOneYear() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";
    require e.block.timestamp - lastRebalanceCompletedTimestamp > YEAR(), "elapsed time exceeds one year";

    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * YEAR();
    mathint feeShares = (numerator + denominator - 1) / denominator;

    /// @dev success conditions being verified
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / YEAR(), "elapsed fee multiplication does not overflow";
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
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert share.totalSupply() == totalSupplyBefore + feeShares;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + feeShares;
}

/// @notice Management fee collection succeeds for uncapped elapsed time when fee shares are nonzero.
/// @dev Verifies storage write and ManagementFeeCollected event parameters.
rule FEE_001_FEE_002_collectManagementFee_Success_WhenFeeSharesAreNonzero() {
    env e;
    uint256 rebalanceNonce;
    uint256 lastRebalanceCompletedTimestamp;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "collectManagementFee is nonpayable";
    require lastRebalanceCompletedTimestamp <= e.block.timestamp, "elapsed time does not underflow";

    mathint elapsed = e.block.timestamp - lastRebalanceCompletedTimestamp;
    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    uint256 totalSupplyBefore = share.totalSupply();
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * elapsed;
    mathint feeShares = (numerator + denominator - 1) / denominator;

    /// @dev success conditions being verified
    require elapsed <= YEAR(), "elapsed time is not capped";
    require elapsed != 0, "elapsed time is nonzero";
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / elapsed,
        "elapsed fee multiplication does not overflow";
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
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert share.totalSupply() == totalSupplyBefore + feeShares;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
    assert ghost_totalShares_StoreCount == 1;
    assert ghost_totalShares_StoredValue == totalShares + feeShares;
}
