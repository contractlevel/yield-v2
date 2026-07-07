using MockYieldcoinShare as share;

/// Verification of ParentVaultRebalanceLib
/// @author @contractlevel
/// @notice ParentVaultRebalanceLib handles ParentVault rebalance validation and state transitions.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getRebalanceNonce() external returns (uint256) envfree;
    function getRebalanceState() external returns (Types.RebalanceState) envfree;
    function getActiveStrategyProtocolId() external returns (bytes32) envfree;
    function getActiveStrategyChainSelector() external returns (uint64) envfree;
    function getPendingStrategyProtocolId() external returns (bytes32) envfree;
    function getPendingStrategyChainSelector() external returns (uint64) envfree;
    function getLastRebalanceInitiatedTimestamp() external returns (uint256) envfree;
    function getLastRebalanceCompletedTimestamp() external returns (uint256) envfree;
    function getEpochNonce() external returns (uint256) envfree;
    function getPreviousEpochStatus() external returns (Types.EpochStatus) envfree;
    function getSupportedProtocol(bytes32) external returns (bool) envfree;
    function getTotalShares() external returns (uint256) envfree;
    function getTreasury() external returns (address) envfree;

    // Library internal wrappers
    function initiateRebalance(bytes32, uint64, uint64, bool) external returns (uint256, uint8);
    function finalizeRebalance() external;

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;

    // Mock methods
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;

    // Dispatcher summaries
    function _.mint(address, uint256) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition REBALANCE_ACTION_NONE() returns uint8 = 0;
definition REBALANCE_ACTION_WITHDRAW_LOCAL_TO_LOCAL() returns uint8 = 1;
definition REBALANCE_ACTION_WITHDRAW_LOCAL_TO_REMOTE() returns uint8 = 2;
definition BPS_DENOMINATOR() returns uint256 = 10000;
definition MANAGEMENT_FEE_BPS() returns uint256 = 100;
definition YEAR() returns uint256 = 31536000;

definition RebalanceInitiatedEvent() returns bytes32 =
// keccak256("RebalanceInitiated(uint256,uint64,bytes32)")
    to_bytes32(0x504cda215d13450a995b166366ceb2adb48e0ff5c4068d0d8e4208011f32972a);

definition RebalanceCompletedEvent() returns bytes32 =
// keccak256("RebalanceCompleted(uint256,bytes32,uint64)")
    to_bytes32(0x1b4570cbee52a827424cbed197d0efe2173b0a28c7ba636e76aefb0ad38b3467);

definition ManagementFeeCollectedEvent() returns bytes32 =
// keccak256("ManagementFeeCollected(uint256,uint256)")
    to_bytes32(0x6f4a589972e181c1010960e6cb88e05776a4f3a28373e49c69ffdf8cc30f1a31);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount RebalanceInitiated event is emitted
ghost mathint ghost_RebalanceInitiated_EventCount {
    init_state axiom ghost_RebalanceInitiated_EventCount == 0;
}

/// @notice EmittedValue: track rebalanceNonce param emitted in RebalanceInitiated event
ghost uint256 ghost_RebalanceInitiated_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceInitiated_Param_rebalanceNonce == 0;
}

/// @notice EmittedValue: track chainSelector param emitted in RebalanceInitiated event
ghost uint64 ghost_RebalanceInitiated_Param_chainSelector {
    init_state axiom ghost_RebalanceInitiated_Param_chainSelector == 0;
}

/// @notice EmittedValue: track protocolId param emitted in RebalanceInitiated event
ghost bytes32 ghost_RebalanceInitiated_Param_protocolId {
    init_state axiom ghost_RebalanceInitiated_Param_protocolId == to_bytes32(0);
}

/// @notice EventCount: track amount RebalanceCompleted event is emitted
ghost mathint ghost_RebalanceCompleted_EventCount {
    init_state axiom ghost_RebalanceCompleted_EventCount == 0;
}

/// @notice EmittedValue: track rebalanceNonce param emitted in RebalanceCompleted event
ghost uint256 ghost_RebalanceCompleted_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceCompleted_Param_rebalanceNonce == 0;
}

/// @notice EmittedValue: track newProtocolId param emitted in RebalanceCompleted event
ghost bytes32 ghost_RebalanceCompleted_Param_newProtocolId {
    init_state axiom ghost_RebalanceCompleted_Param_newProtocolId == to_bytes32(0);
}

/// @notice EmittedValue: track newChainSelector param emitted in RebalanceCompleted event
ghost uint64 ghost_RebalanceCompleted_Param_newChainSelector {
    init_state axiom ghost_RebalanceCompleted_Param_newChainSelector == 0;
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
    if (t0 == RebalanceInitiatedEvent()) {
        ghost_RebalanceInitiated_EventCount = ghost_RebalanceInitiated_EventCount + 1;
        ghost_RebalanceInitiated_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceInitiated_Param_chainSelector = bytes32ToUint64(t2);
        ghost_RebalanceInitiated_Param_protocolId = t3;
    }

    if (t0 == RebalanceCompletedEvent()) {
        ghost_RebalanceCompleted_EventCount = ghost_RebalanceCompleted_EventCount + 1;
        ghost_RebalanceCompleted_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceCompleted_Param_newProtocolId = t2;
        ghost_RebalanceCompleted_Param_newChainSelector = bytes32ToUint64(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── INITIATE REBALANCE ─────────────────────

/// @notice Initiating a rebalance reverts when another rebalance is already in progress.
/// @dev Verifies active rebalance guard.
rule REBAL_002_initiateRebalance_RevertWhen_RebalanceInProgress() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;
    bool isSupportedChain;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";

    /// @dev revert condition being verified
    require getRebalanceState() != Types.RebalanceState.NONE, "rebalance is in progress";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the new strategy equals the active strategy.
/// @dev Verifies same strategy guard.
rule REBAL_003_initiateRebalance_RevertWhen_SameStrategy() {
    env e;
    uint64 thisChainSelector;
    bool isSupportedChain;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";

    bytes32 protocolId = getActiveStrategyProtocolId();
    uint64 chainSelector = getActiveStrategyChainSelector();

    /// @dev revert condition being verified
    require protocolId == getActiveStrategyProtocolId(), "protocol matches active strategy";
    require chainSelector == getActiveStrategyChainSelector(), "chain selector matches active strategy";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the target chain is unsupported.
/// @dev Verifies invalid chain selector guard.
rule initiateRebalance_RevertWhen_InvalidChainSelector() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";

    /// @dev revert condition being verified
    bool isSupportedChain = false;

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the target protocol is unsupported.
/// @dev Verifies invalid protocol ID guard.
rule initiateRebalance_RevertWhen_InvalidProtocolId() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;

    /// @dev revert condition being verified
    require !getSupportedProtocol(protocolId), "protocol is unsupported";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts before any epoch has completed.
/// @dev Verifies no completed epoch guard.
rule initiateRebalance_RevertWhen_NoCompletedEpoch() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;
    require getSupportedProtocol(protocolId), "protocol is supported";

    /// @dev revert condition being verified
    require getEpochNonce() == 1, "current epoch nonce is one";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts while the previous epoch is still executing.
/// @dev Verifies prior executing epoch guard.
rule initiateRebalance_RevertWhen_PreviousEpochExecuting() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;
    require getSupportedProtocol(protocolId), "protocol is supported";

    /// @dev revert condition being verified
    require getEpochNonce() > 1, "current epoch nonce is greater than one";
    require getPreviousEpochStatus() == Types.EpochStatus.EXECUTING, "previous epoch is executing";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance returns the local withdraw action.
/// @dev Verifies state writes, RebalanceInitiated event, and WITHDRAW_LOCAL_TO_LOCAL action.
rule initiateRebalance_Success_WhenLocalToLocal() {
    env e;
    bytes32 protocolId;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";

    uint64 chainSelector = thisChainSelector;
    uint256 rebalanceNonce = getRebalanceNonce();

    /// @dev success conditions being verified
    require getActiveStrategyChainSelector() == thisChainSelector, "active strategy is local";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;
    require getSupportedProtocol(protocolId), "protocol is supported";
    require getEpochNonce() > 1, "at least one epoch has completed";
    require getPreviousEpochStatus() != Types.EpochStatus.EXECUTING, "previous epoch is not executing";

    /// @dev ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0, "RebalanceInitiated event count starts at zero";

    uint256 returnedNonce;
    uint8 action;
    (returnedNonce, action) =
        initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert !lastReverted;
    assert returnedNonce == rebalanceNonce;
    assert action == REBALANCE_ACTION_WITHDRAW_LOCAL_TO_LOCAL();
    assert getRebalanceState() == Types.RebalanceState.REBALANCING;
    assert getPendingStrategyProtocolId() == protocolId;
    assert getPendingStrategyChainSelector() == chainSelector;
    assert getLastRebalanceInitiatedTimestamp() == e.block.timestamp;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == protocolId;
}

/// @notice Initiating a local-to-remote rebalance returns the local-to-remote withdraw action.
/// @dev Verifies state writes, RebalanceInitiated event, and WITHDRAW_LOCAL_TO_REMOTE action.
rule initiateRebalance_Success_WhenLocalToRemote() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";

    uint256 rebalanceNonce = getRebalanceNonce();

    /// @dev success conditions being verified
    require getActiveStrategyChainSelector() == thisChainSelector, "active strategy is local";
    require chainSelector != thisChainSelector, "new strategy is remote";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;
    require getSupportedProtocol(protocolId), "protocol is supported";
    require getEpochNonce() > 1, "at least one epoch has completed";
    require getPreviousEpochStatus() != Types.EpochStatus.EXECUTING, "previous epoch is not executing";

    /// @dev ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0, "RebalanceInitiated event count starts at zero";

    uint256 returnedNonce;
    uint8 action;
    (returnedNonce, action) =
        initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert !lastReverted;
    assert returnedNonce == rebalanceNonce;
    assert action == REBALANCE_ACTION_WITHDRAW_LOCAL_TO_REMOTE();
    assert getRebalanceState() == Types.RebalanceState.REBALANCING;
    assert getPendingStrategyProtocolId() == protocolId;
    assert getPendingStrategyChainSelector() == chainSelector;
    assert getLastRebalanceInitiatedTimestamp() == e.block.timestamp;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == protocolId;
}

/// @notice Initiating a rebalance from a remote active strategy returns no immediate local action.
/// @dev Verifies state writes, RebalanceInitiated event, and NONE action.
rule initiateRebalance_Success_WhenActiveStrategyIsRemote() {
    env e;
    bytes32 protocolId;
    uint64 chainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initiateRebalance is nonpayable";
    require getRebalanceState() == Types.RebalanceState.NONE, "no rebalance is in progress";

    uint256 rebalanceNonce = getRebalanceNonce();

    /// @dev success conditions being verified
    require getActiveStrategyChainSelector() != thisChainSelector, "active strategy is remote";
    require protocolId != getActiveStrategyProtocolId() || chainSelector != getActiveStrategyChainSelector(),
        "new strategy differs from active strategy";
    bool isSupportedChain = true;
    require getSupportedProtocol(protocolId), "protocol is supported";
    require getEpochNonce() > 1, "at least one epoch has completed";
    require getPreviousEpochStatus() != Types.EpochStatus.EXECUTING, "previous epoch is not executing";

    /// @dev ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0, "RebalanceInitiated event count starts at zero";

    uint256 returnedNonce;
    uint8 action;
    (returnedNonce, action) =
        initiateRebalance@withrevert(e, protocolId, chainSelector, thisChainSelector, isSupportedChain);

    assert !lastReverted;
    assert returnedNonce == rebalanceNonce;
    assert action == REBALANCE_ACTION_NONE();
    assert getRebalanceState() == Types.RebalanceState.REBALANCING;
    assert getPendingStrategyProtocolId() == protocolId;
    assert getPendingStrategyChainSelector() == chainSelector;
    assert getLastRebalanceInitiatedTimestamp() == e.block.timestamp;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == protocolId;
}

/// ─────────────────── FINALIZE REBALANCE ─────────────────────

/// @notice Finalizing a rebalance reverts when no rebalance is in progress.
/// @dev Verifies no rebalance in progress guard.
rule finalizeRebalance_RevertWhen_NoRebalanceInProgress() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeRebalance is nonpayable";

    /// @dev revert condition being verified
    require getRebalanceState() != Types.RebalanceState.REBALANCING, "no rebalance is in progress";

    storage before = lastStorage;

    finalizeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Finalizing a rebalance reverts when the nonce increment overflows.
/// @dev Verifies rebalance nonce overflow.
rule finalizeRebalance_RevertWhen_RebalanceNonceOverflows() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeRebalance is nonpayable";
    require getLastRebalanceCompletedTimestamp() <= e.block.timestamp, "management fee elapsed time does not underflow";

    /// @dev revert condition being verified
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";
    require getRebalanceNonce() == max_uint256, "rebalance nonce increment overflows";

    storage before = lastStorage;

    finalizeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Finalizing a rebalance reverts when management fee elapsed time underflows.
/// @dev Verifies last completed timestamp future branch in the delegated management fee collection.
rule finalizeRebalance_RevertWhen_LastCompletedTimestampIsFuture() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeRebalance is nonpayable";
    require getRebalanceNonce() < max_uint256, "rebalance nonce increment does not overflow";

    /// @dev revert condition being verified
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";
    require getLastRebalanceCompletedTimestamp() > e.block.timestamp, "last completed timestamp is in the future";

    storage before = lastStorage;

    finalizeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Finalizing a rebalance completes the pending strategy without collecting fees when no shares exist.
/// @dev Verifies active strategy update, pending strategy delete, nonce increment, timestamp write, and RebalanceCompleted event.
rule finalizeRebalance_Success_WhenNoManagementFeeShares() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeRebalance is nonpayable";
    require getRebalanceNonce() < max_uint256, "rebalance nonce increment does not overflow";
    require getLastRebalanceCompletedTimestamp() <= e.block.timestamp, "management fee elapsed time does not underflow";

    uint256 rebalanceNonce = getRebalanceNonce();
    bytes32 pendingProtocolId = getPendingStrategyProtocolId();
    uint64 pendingChainSelector = getPendingStrategyChainSelector();

    /// @dev success conditions being verified
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";
    require getTotalShares() == 0, "no management fee shares are collected";

    /// @dev ghost starting values
    require ghost_RebalanceCompleted_EventCount == 0, "RebalanceCompleted event count starts at zero";
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";

    finalizeRebalance@withrevert(e);

    assert !lastReverted;
    assert getRebalanceNonce() == rebalanceNonce + 1;
    assert getRebalanceState() == Types.RebalanceState.NONE;
    assert getActiveStrategyProtocolId() == pendingProtocolId;
    assert getActiveStrategyChainSelector() == pendingChainSelector;
    assert getPendingStrategyProtocolId() == to_bytes32(0);
    assert getPendingStrategyChainSelector() == 0;
    assert getLastRebalanceCompletedTimestamp() == e.block.timestamp;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 0;
}

/// @notice Finalizing a rebalance completes the pending strategy and collects management fee shares.
/// @dev Verifies the nonzero management fee branch during rebalance finalization.
rule finalizeRebalance_Success_WhenManagementFeeSharesAreCollected() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeRebalance is nonpayable";
    require getRebalanceNonce() < max_uint256, "rebalance nonce increment does not overflow";
    require getLastRebalanceCompletedTimestamp() <= e.block.timestamp, "management fee elapsed time does not underflow";

    uint256 rebalanceNonce = getRebalanceNonce();
    bytes32 pendingProtocolId = getPendingStrategyProtocolId();
    uint64 pendingChainSelector = getPendingStrategyChainSelector();
    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();

    /// @dev success conditions being verified
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";
    mathint elapsed = e.block.timestamp - getLastRebalanceCompletedTimestamp();
    require elapsed <= YEAR(), "elapsed time is not capped";
    require elapsed != 0, "elapsed time is nonzero";
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(), "total shares fee bps multiplication does not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / elapsed,
        "elapsed fee multiplication does not overflow";
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * elapsed;
    require numerator <= max_uint256 - (denominator - 1), "ceil numerator addition does not overflow";
    mathint feeShares = (numerator + denominator - 1) / denominator;
    require feeShares != 0, "fee shares are nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition does not overflow";
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    require treasuryBalanceBefore <= max_uint256 - feeShares, "treasury share balance does not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_RebalanceCompleted_EventCount == 0, "RebalanceCompleted event count starts at zero";
    require ghost_ManagementFeeCollected_EventCount == 0, "ManagementFeeCollected event count starts at zero";

    finalizeRebalance@withrevert(e);

    assert !lastReverted;
    assert getRebalanceNonce() == rebalanceNonce + 1;
    assert getRebalanceState() == Types.RebalanceState.NONE;
    assert getActiveStrategyProtocolId() == pendingProtocolId;
    assert getActiveStrategyChainSelector() == pendingChainSelector;
    assert getPendingStrategyProtocolId() == to_bytes32(0);
    assert getPendingStrategyChainSelector() == 0;
    assert getLastRebalanceCompletedTimestamp() == e.block.timestamp;
    assert getTotalShares() == totalShares + feeShares;
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
}
