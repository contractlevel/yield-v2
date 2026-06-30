/// Verification of ParentVaultCcipLib
/// @author @contractlevel
/// @notice ParentVaultCcipLib handles ParentVault-specific CCIP message decoding, validation, and epoch settlement.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getEpochNonce() external returns (uint256) envfree;
    function getEpochTotalDepositAmount(uint256) external returns (uint256) envfree;
    function getEpochTotalWithdrawClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingWithdrawClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochStatus(uint256) external returns (Types.EpochStatus) envfree;
    function getRebalanceNonce() external returns (uint256) envfree;
    function getRebalanceState() external returns (Types.RebalanceState) envfree;
    function getPendingStrategyProtocolId() external returns (bytes32) envfree;

    // Library internal wrappers
    function receiveCcip(Types.CcipTx, bytes, uint256) external returns (uint256, bytes32);
    function finalizeEpoch(uint256) external;

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function encodeEpochNonce(uint256) external returns (bytes) envfree;
    function encodeRebalanceData(uint256, bytes32) external returns (bytes) envfree;
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition EpochClaimableEvent() returns bytes32 =
// keccak256("EpochClaimable(uint256)")
    to_bytes32(0x45d9681f238e455170e797872754deaef148c9e7836f9949104764a4f4cfae8a);

definition EpochWithdrawAmountShortEvent() returns bytes32 =
// keccak256("EpochWithdrawAmountShort(uint256,uint256,uint256)")
    to_bytes32(0x9087919bbb431a8a7241eebf12465b469fe3f4f78eeda82d3e47d41378977695);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
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

/// @notice StoreCount: track writes to epoch.remainingWithdrawClaimAmount
ghost mathint ghost_epoch_remainingWithdrawClaimAmount_StoreCount {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0;
}

/// @notice StoredKey: track latest epoch key written for remainingWithdrawClaimAmount
ghost uint256 ghost_epoch_remainingWithdrawClaimAmount_StoredKey {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoredKey == 0;
}

/// @notice StoredValue: track latest value written to epoch.remainingWithdrawClaimAmount
ghost uint256 ghost_epoch_remainingWithdrawClaimAmount_StoredValue {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoredValue == 0;
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

/// @notice EventCount: track amount EpochClaimable event is emitted
ghost mathint ghost_EpochClaimable_EventCount {
    init_state axiom ghost_EpochClaimable_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochClaimable event
ghost uint256 ghost_EpochClaimable_Param_epochNonce {
    init_state axiom ghost_EpochClaimable_Param_epochNonce == 0;
}

/// @notice EventCount: track amount EpochWithdrawAmountShort event is emitted
ghost mathint ghost_EpochWithdrawAmountShort_EventCount {
    init_state axiom ghost_EpochWithdrawAmountShort_EventCount == 0;
}

/// @notice EmittedValue: track epochNonce param emitted in EpochWithdrawAmountShort event
ghost uint256 ghost_EpochWithdrawAmountShort_Param_epochNonce {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_epochNonce == 0;
}

/// @notice EmittedValue: track expectedAmount param emitted in EpochWithdrawAmountShort event
ghost uint256 ghost_EpochWithdrawAmountShort_Param_expectedAmount {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_expectedAmount == 0;
}

/// @notice EmittedValue: track actualAmount param emitted in EpochWithdrawAmountShort event
ghost uint256 ghost_EpochWithdrawAmountShort_Param_actualAmount {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_actualAmount == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto ParentVault epoch totalWithdrawClaimAmount storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].totalWithdrawClaimAmount uint256 newValue {
    ghost_epoch_totalWithdrawClaimAmount_StoreCount = ghost_epoch_totalWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_totalWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_totalWithdrawClaimAmount_StoredValue = newValue;
}

/// @notice hook onto ParentVault epoch remainingWithdrawClaimAmount storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingWithdrawClaimAmount uint256 newValue {
    ghost_epoch_remainingWithdrawClaimAmount_StoreCount = ghost_epoch_remainingWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_remainingWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_remainingWithdrawClaimAmount_StoredValue = newValue;
}

/// @notice hook onto ParentVault epoch status storage writes
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].status Types.EpochStatus newValue {
    ghost_epoch_status_StoreCount = ghost_epoch_status_StoreCount + 1;
    ghost_epoch_status_StoredKey = epochNonce;
    ghost_epoch_status_StoredValue = newValue;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == EpochClaimableEvent()) {
        ghost_EpochClaimable_EventCount = ghost_EpochClaimable_EventCount + 1;
        ghost_EpochClaimable_Param_epochNonce = bytes32ToUint256(t1);
    }
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == EpochWithdrawAmountShortEvent()) {
        ghost_EpochWithdrawAmountShort_EventCount = ghost_EpochWithdrawAmountShort_EventCount + 1;
        ghost_EpochWithdrawAmountShort_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawAmountShort_Param_expectedAmount = bytes32ToUint256(t2);
        ghost_EpochWithdrawAmountShort_Param_actualAmount = bytes32ToUint256(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── RECEIVE CCIP ───────────────────────────

/// @notice ParentVault CCIP receive reverts when the transaction type is unsupported.
/// @dev Verifies that unsupported valid enum values leave ParentVault storage unchanged.
rule receiveCcip_RevertWhen_TxTypeInvalid() {
    env e;
    bytes data;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";

    /// @dev revert condition being verified
    Types.CcipTx ccipTxType = Types.CcipTx.EPOCH_NET_DEPOSIT;

    storage before = lastStorage;

    receiveCcip@withrevert(e, ccipTxType, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── EPOCH NET WITHDRAW ─────────────────────

/// @notice Epoch net-withdraw handling reverts when the payload epoch nonce is not the most recently closed epoch.
/// @dev Verifies that epoch settlement storage is unchanged.
rule receiveCcip_EpochNetWithdraw_RevertWhen_EpochNonceInvalid() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() != 0, "current epoch nonce is nonzero";

    /// @dev revert condition being verified
    require epochNonce != getEpochNonce() - 1, "payload epoch nonce is invalid";

    bytes data = encodeEpochNonce(epochNonce);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling reverts when the current epoch nonce is zero.
/// @dev Verifies that the epoch nonce underflow path leaves ParentVault storage unchanged.
rule receiveCcip_EpochNetWithdraw_RevertWhen_CurrentEpochNonceIsZero() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";

    /// @dev revert condition being verified
    require getEpochNonce() == 0, "current epoch nonce is zero";

    bytes data = encodeEpochNonce(epochNonce);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling reverts when the epoch payload cannot decode to a uint256.
/// @dev Verifies that malformed payloads leave ParentVault storage unchanged.
rule receiveCcip_EpochNetWithdraw_RevertWhen_DataIsMalformed() {
    env e;
    bytes data;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";

    /// @dev revert condition being verified
    require data.length < 32, "payload is too short to decode uint256";

    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling reverts when the target epoch is not executing.
/// @dev Verifies that epoch settlement storage is unchanged after rollback.
rule receiveCcip_EpochNetWithdraw_RevertWhen_EpochNotExecuting() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() == epochNonce + 1, "payload epoch nonce is the previous epoch";

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.EXECUTING, "epoch is not executing";

    /// @dev arithmetic conditions NOT being verified
    require getEpochTotalWithdrawClaimAmount(epochNonce) >= getEpochTotalDepositAmount(epochNonce),
        "expected withdraw does not underflow";
    require getEpochTotalDepositAmount(epochNonce) <= max_uint256 - receivedAmount,
        "settled withdraw claim amount does not overflow";

    bytes data = encodeEpochNonce(epochNonce);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling reverts when expected withdraw arithmetic underflows.
/// @dev Verifies that invalid epoch accounting leaves ParentVault storage unchanged.
rule receiveCcip_EpochNetWithdraw_RevertWhen_ExpectedWithdrawUnderflows() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() == epochNonce + 1, "payload epoch nonce is the previous epoch";

    /// @dev revert condition being verified
    require getEpochTotalWithdrawClaimAmount(epochNonce) < getEpochTotalDepositAmount(epochNonce),
        "expected withdraw underflows";

    bytes data = encodeEpochNonce(epochNonce);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling reverts when settled withdraw accounting overflows.
/// @dev Verifies that overflow leaves ParentVault storage unchanged.
rule receiveCcip_EpochNetWithdraw_RevertWhen_SettledAmountOverflows() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() == epochNonce + 1, "payload epoch nonce is the previous epoch";
    require getEpochTotalWithdrawClaimAmount(epochNonce) >= getEpochTotalDepositAmount(epochNonce),
        "expected withdraw does not underflow";

    /// @dev revert condition being verified
    require getEpochTotalDepositAmount(epochNonce) > max_uint256 - receivedAmount,
        "settled withdraw claim amount overflows";

    bytes data = encodeEpochNonce(epochNonce);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Epoch net-withdraw handling succeeds and emits EpochWithdrawAmountShort when received amount is below expected.
/// @dev Verifies settled withdraw accounting, claimable status, and emitted event parameters.
rule receiveCcip_EpochNetWithdraw_Success_WhenReceivedAmountIsShort() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() == epochNonce + 1, "payload epoch nonce is the previous epoch";

    uint256 totalDepositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 totalWithdrawClaimAmount = getEpochTotalWithdrawClaimAmount(epochNonce);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING, "epoch is executing";
    require totalWithdrawClaimAmount >= totalDepositAmount, "expected withdraw does not underflow";
    mathint expectedWithdraw = totalWithdrawClaimAmount - totalDepositAmount;
    require receivedAmount < expectedWithdraw, "received amount is short";
    require totalDepositAmount <= max_uint256 - receivedAmount, "settled withdraw claim amount does not overflow";

    /// @dev ghost starting values
    require ghost_EpochWithdrawAmountShort_EventCount == 0, "EpochWithdrawAmountShort event count starts at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0,
        "remainingWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bytes data = encodeEpochNonce(epochNonce);

    uint256 returnedNonce; bytes32 returnedProtocolId;
    (returnedNonce, returnedProtocolId) =
        receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    mathint settledAmount = totalDepositAmount + receivedAmount;

    assert !lastReverted;
    assert returnedNonce == 0;
    assert returnedProtocolId == to_bytes32(0);
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochWithdrawAmountShort_EventCount == 1;
    assert ghost_EpochWithdrawAmountShort_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawAmountShort_Param_expectedAmount == expectedWithdraw;
    assert ghost_EpochWithdrawAmountShort_Param_actualAmount == receivedAmount;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == settledAmount;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoredValue == settledAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// @notice Epoch net-withdraw handling succeeds without a shortfall event when received amount covers expected.
/// @dev Verifies settled withdraw accounting, claimable status, and EpochClaimable event parameters.
rule receiveCcip_EpochNetWithdraw_Success_WhenReceivedAmountCoversExpected() {
    env e;
    uint256 epochNonce;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getEpochNonce() == epochNonce + 1, "payload epoch nonce is the previous epoch";

    uint256 totalDepositAmount = getEpochTotalDepositAmount(epochNonce);
    uint256 totalWithdrawClaimAmount = getEpochTotalWithdrawClaimAmount(epochNonce);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING, "epoch is executing";
    require totalWithdrawClaimAmount >= totalDepositAmount, "expected withdraw does not underflow";
    mathint expectedWithdraw = totalWithdrawClaimAmount - totalDepositAmount;
    require receivedAmount >= expectedWithdraw, "received amount covers expected";
    require totalDepositAmount <= max_uint256 - receivedAmount, "settled withdraw claim amount does not overflow";

    /// @dev ghost starting values
    require ghost_EpochWithdrawAmountShort_EventCount == 0, "EpochWithdrawAmountShort event count starts at zero";
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0,
        "totalWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0,
        "remainingWithdrawClaimAmount store count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    bytes data = encodeEpochNonce(epochNonce);

    uint256 returnedNonce; bytes32 returnedProtocolId;
    (returnedNonce, returnedProtocolId) =
        receiveCcip@withrevert(e, Types.CcipTx.EPOCH_NET_WITHDRAW, data, receivedAmount);

    mathint settledAmount = totalDepositAmount + receivedAmount;

    assert !lastReverted;
    assert returnedNonce == 0;
    assert returnedProtocolId == to_bytes32(0);
    assert getEpochTotalWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == settledAmount;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochWithdrawAmountShort_EventCount == 0;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_totalWithdrawClaimAmount_StoredValue == settledAmount;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 1;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoredKey == epochNonce;
    assert ghost_epoch_remainingWithdrawClaimAmount_StoredValue == settledAmount;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}

/// ─────────────────── REBALANCE VALIDATION ───────────────────

/// @notice Rebalance CCIP validation reverts when no rebalance is in progress.
/// @dev Verifies that no ParentVault storage is modified.
rule receiveCcip_Rebalance_RevertWhen_NoRebalanceInProgress() {
    env e;
    bytes data;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";

    /// @dev revert condition being verified
    require getRebalanceState() != Types.RebalanceState.REBALANCING, "rebalance is not in progress";

    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.REBALANCE, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Rebalance CCIP validation reverts when the rebalance payload cannot decode to nonce and protocol ID.
/// @dev Verifies that malformed payloads leave ParentVault storage unchanged.
rule receiveCcip_Rebalance_RevertWhen_DataIsMalformed() {
    env e;
    bytes data;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";

    /// @dev revert condition being verified
    require data.length < 64, "payload is too short to decode uint256 and bytes32";

    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.REBALANCE, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Rebalance CCIP validation reverts when the payload rebalance nonce is invalid.
/// @dev Verifies that no ParentVault storage is modified.
rule receiveCcip_Rebalance_RevertWhen_RebalanceNonceInvalid() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";

    /// @dev revert condition being verified
    require rebalanceNonce != getRebalanceNonce(), "payload rebalance nonce is invalid";

    bytes data = encodeRebalanceData(rebalanceNonce, protocolId);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.REBALANCE, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Rebalance CCIP validation reverts when the payload protocol ID is not the pending strategy.
/// @dev Verifies that no ParentVault storage is modified.
rule receiveCcip_Rebalance_RevertWhen_PendingProtocolIdInvalid() {
    env e;
    bytes32 protocolId;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";

    uint256 rebalanceNonce = getRebalanceNonce();

    /// @dev revert condition being verified
    require protocolId != getPendingStrategyProtocolId(), "payload protocol ID is invalid";

    bytes data = encodeRebalanceData(rebalanceNonce, protocolId);
    storage before = lastStorage;

    receiveCcip@withrevert(e, Types.CcipTx.REBALANCE, data, receivedAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Rebalance CCIP validation returns the payload nonce and pending protocol ID when they match storage.
/// @dev Verifies that no ParentVault storage is modified.
rule receiveCcip_Rebalance_Success() {
    env e;
    uint256 receivedAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "receiveCcip is nonpayable";

    /// @dev success conditions being verified
    require getRebalanceState() == Types.RebalanceState.REBALANCING, "rebalance is in progress";

    uint256 rebalanceNonce = getRebalanceNonce();
    bytes32 protocolId = getPendingStrategyProtocolId();
    bytes data = encodeRebalanceData(rebalanceNonce, protocolId);
    storage before = lastStorage;

    uint256 returnedNonce; bytes32 returnedProtocolId;
    (returnedNonce, returnedProtocolId) =
        receiveCcip@withrevert(e, Types.CcipTx.REBALANCE, data, receivedAmount);

    assert !lastReverted;
    assert returnedNonce == rebalanceNonce;
    assert returnedProtocolId == protocolId;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── FINALIZE EPOCH ─────────────────────────

/// @notice Finalizing an epoch reverts when the epoch is not executing.
/// @dev Verifies that the epoch status is unchanged and no EpochClaimable event is emitted.
rule finalizeEpoch_RevertWhen_EpochNotExecuting() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeEpoch is nonpayable";

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.EXECUTING, "epoch is not executing";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    finalizeEpoch@withrevert(e, epochNonce);

    assert lastReverted;
    assert ghost_EpochClaimable_EventCount == 0;
    assert ghost_epoch_status_StoreCount == 0;
}

/// @notice Finalizing an executing epoch makes it claimable.
/// @dev Verifies the epoch status write and EpochClaimable event parameter.
rule finalizeEpoch_Success() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "finalizeEpoch is nonpayable";

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.EXECUTING, "epoch is executing";

    /// @dev ghost starting values
    require ghost_EpochClaimable_EventCount == 0, "EpochClaimable event count starts at zero";
    require ghost_epoch_status_StoreCount == 0, "epoch status store count starts at zero";

    finalizeEpoch@withrevert(e, epochNonce);

    assert !lastReverted;
    assert getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert ghost_epoch_status_StoreCount == 1;
    assert ghost_epoch_status_StoredKey == epochNonce;
    assert ghost_epoch_status_StoredValue == Types.EpochStatus.CLAIMABLE;
}
