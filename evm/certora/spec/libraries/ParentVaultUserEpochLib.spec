using MockUSDC as asset;
using MockYieldcoinShare as share;

/// Verification of ParentVaultUserEpochLib
/// @author @contractlevel
/// @notice ParentVaultUserEpochLib handles user-level ParentVault epoch deposits, withdrawals, claims, and cancellations.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getAsset() external returns (address) envfree;
    function getShare() external returns (address) envfree;
    function getEpochNonce() external returns (uint256) envfree;
    function getDeposit(address, uint256) external returns (uint256) envfree;
    function getWithdraw(address, uint256) external returns (uint256) envfree;
    function getEpochTotalDepositAmount(uint256) external returns (uint256) envfree;
    function getEpochTotalShareBurnAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingDepositClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingShareMintAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingShareBurnAmount(uint256) external returns (uint256) envfree;
    function getEpochRemainingWithdrawClaimAmount(uint256) external returns (uint256) envfree;
    function getEpochStatus(uint256) external returns (Types.EpochStatus) envfree;

    // Library internal wrappers
    function deposit(address, uint256, uint256) external returns (uint256);
    function withdraw(address, uint256) external returns (uint256);
    function claimShares(address, uint256) external returns (uint256);
    function claimAsset(address, uint256) external returns (uint256);
    function cancelDeposit(address) external;
    function cancelWithdraw(address) external;
    function proportionalAmount(uint256, uint256, uint256) external returns (uint256) envfree;

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;

    // Mock methods
    function asset.balanceOf(address) external returns (uint256) envfree;
    function asset.allowance(address, address) external returns (uint256) envfree;
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.allowance(address, address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;

    // Dispatcher summaries
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.burn(address, uint256) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition DepositSubmittedEvent() returns bytes32 =
// keccak256("DepositSubmitted(uint256,address,uint256)")
    to_bytes32(0x6dbddde512af7c9b1f7d0a592199a3c85ceac007416f229dd16872d0024343c1);

definition WithdrawSubmittedEvent() returns bytes32 =
// keccak256("WithdrawSubmitted(uint256,address,uint256)")
    to_bytes32(0x4e28329a81623da3184e5f894334e11904009d4148c66bb1ea19eb28478b6351);

definition DepositClaimedEvent() returns bytes32 =
// keccak256("DepositClaimed(uint256,address,uint256)")
    to_bytes32(0xacb5e5700b5a312da42fca897046d87226094d7032852cc1a3cd9e4c54538b2c);

definition WithdrawClaimedEvent() returns bytes32 =
// keccak256("WithdrawClaimed(uint256,address,uint256)")
    to_bytes32(0xd652eec1c58b4b6f74acf69b1c7bd8163c76712b2c9547f6f2d7b14a88bd7f45);

definition DepositCancelledEvent() returns bytes32 =
// keccak256("DepositCancelled(uint256,address,uint256)")
    to_bytes32(0x24c9e122007bd4087408943168fbcd65248594530e482b6a9abe4484767eb0c3);

definition WithdrawCancelledEvent() returns bytes32 =
// keccak256("WithdrawCancelled(uint256,address,uint256)")
    to_bytes32(0x769d7210521411ed9ffb77cf3eacdd55cfde3d8dd5f99d7a6a908969b327b06f);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_DepositSubmitted_EventCount {
    init_state axiom ghost_DepositSubmitted_EventCount == 0;
}

ghost uint256 ghost_DepositSubmitted_Param_epochNonce {
    init_state axiom ghost_DepositSubmitted_Param_epochNonce == 0;
}

ghost address ghost_DepositSubmitted_Param_depositor {
    init_state axiom ghost_DepositSubmitted_Param_depositor == 0;
}

ghost uint256 ghost_DepositSubmitted_Param_amount {
    init_state axiom ghost_DepositSubmitted_Param_amount == 0;
}

ghost mathint ghost_WithdrawSubmitted_EventCount {
    init_state axiom ghost_WithdrawSubmitted_EventCount == 0;
}

ghost uint256 ghost_WithdrawSubmitted_Param_epochNonce {
    init_state axiom ghost_WithdrawSubmitted_Param_epochNonce == 0;
}

ghost address ghost_WithdrawSubmitted_Param_withdrawer {
    init_state axiom ghost_WithdrawSubmitted_Param_withdrawer == 0;
}

ghost uint256 ghost_WithdrawSubmitted_Param_shareBurnAmount {
    init_state axiom ghost_WithdrawSubmitted_Param_shareBurnAmount == 0;
}

ghost mathint ghost_DepositClaimed_EventCount {
    init_state axiom ghost_DepositClaimed_EventCount == 0;
}

ghost uint256 ghost_DepositClaimed_Param_epochNonce {
    init_state axiom ghost_DepositClaimed_Param_epochNonce == 0;
}

ghost address ghost_DepositClaimed_Param_depositor {
    init_state axiom ghost_DepositClaimed_Param_depositor == 0;
}

ghost uint256 ghost_DepositClaimed_Param_shareMintAmount {
    init_state axiom ghost_DepositClaimed_Param_shareMintAmount == 0;
}

ghost mathint ghost_WithdrawClaimed_EventCount {
    init_state axiom ghost_WithdrawClaimed_EventCount == 0;
}

ghost uint256 ghost_WithdrawClaimed_Param_epochNonce {
    init_state axiom ghost_WithdrawClaimed_Param_epochNonce == 0;
}

ghost address ghost_WithdrawClaimed_Param_withdrawer {
    init_state axiom ghost_WithdrawClaimed_Param_withdrawer == 0;
}

ghost uint256 ghost_WithdrawClaimed_Param_amount {
    init_state axiom ghost_WithdrawClaimed_Param_amount == 0;
}

ghost mathint ghost_DepositCancelled_EventCount {
    init_state axiom ghost_DepositCancelled_EventCount == 0;
}

ghost uint256 ghost_DepositCancelled_Param_epochNonce {
    init_state axiom ghost_DepositCancelled_Param_epochNonce == 0;
}

ghost address ghost_DepositCancelled_Param_depositor {
    init_state axiom ghost_DepositCancelled_Param_depositor == 0;
}

ghost uint256 ghost_DepositCancelled_Param_amount {
    init_state axiom ghost_DepositCancelled_Param_amount == 0;
}

ghost mathint ghost_WithdrawCancelled_EventCount {
    init_state axiom ghost_WithdrawCancelled_EventCount == 0;
}

ghost uint256 ghost_WithdrawCancelled_Param_epochNonce {
    init_state axiom ghost_WithdrawCancelled_Param_epochNonce == 0;
}

ghost address ghost_WithdrawCancelled_Param_withdrawer {
    init_state axiom ghost_WithdrawCancelled_Param_withdrawer == 0;
}

ghost uint256 ghost_WithdrawCancelled_Param_shareBurnAmount {
    init_state axiom ghost_WithdrawCancelled_Param_shareBurnAmount == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == DepositSubmittedEvent()) {
        ghost_DepositSubmitted_EventCount = ghost_DepositSubmitted_EventCount + 1;
        ghost_DepositSubmitted_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositSubmitted_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositSubmitted_Param_amount = bytes32ToUint256(t3);
    }

    if (t0 == WithdrawSubmittedEvent()) {
        ghost_WithdrawSubmitted_EventCount = ghost_WithdrawSubmitted_EventCount + 1;
        ghost_WithdrawSubmitted_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawSubmitted_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawSubmitted_Param_shareBurnAmount = bytes32ToUint256(t3);
    }

    if (t0 == DepositClaimedEvent()) {
        ghost_DepositClaimed_EventCount = ghost_DepositClaimed_EventCount + 1;
        ghost_DepositClaimed_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositClaimed_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositClaimed_Param_shareMintAmount = bytes32ToUint256(t3);
    }

    if (t0 == WithdrawClaimedEvent()) {
        ghost_WithdrawClaimed_EventCount = ghost_WithdrawClaimed_EventCount + 1;
        ghost_WithdrawClaimed_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawClaimed_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawClaimed_Param_amount = bytes32ToUint256(t3);
    }

    if (t0 == DepositCancelledEvent()) {
        ghost_DepositCancelled_EventCount = ghost_DepositCancelled_EventCount + 1;
        ghost_DepositCancelled_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositCancelled_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositCancelled_Param_amount = bytes32ToUint256(t3);
    }

    if (t0 == WithdrawCancelledEvent()) {
        ghost_WithdrawCancelled_EventCount = ghost_WithdrawCancelled_EventCount + 1;
        ghost_WithdrawCancelled_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawCancelled_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawCancelled_Param_shareBurnAmount = bytes32ToUint256(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── PROPORTIONAL AMOUNT ────────────────────

/// @notice Proportional amount reverts when denominator is zero and numerator is nonzero.
/// @dev Verifies proportional division by zero.
rule proportionalAmount_RevertWhen_DenominatorIsZero() {
    env e;
    uint256 userAmount;
    uint256 remainingNumerator;
    uint256 remainingDenominator = 0;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "proportionalAmount is nonpayable";

    /// @dev revert condition being verified
    require userAmount != 0, "user amount is nonzero";
    require remainingNumerator != 0, "remaining numerator is nonzero";

    proportionalAmount@withrevert(e, userAmount, remainingNumerator, remainingDenominator);

    assert lastReverted;
}

/// @notice Proportional amount reverts when denominator is zero even when the product is zero.
/// @dev Verifies zero-product division by zero.
rule proportionalAmount_RevertWhen_ZeroProductAndDenominatorIsZero() {
    env e;
    uint256 userAmount;
    uint256 remainingNumerator;
    uint256 remainingDenominator = 0;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "proportionalAmount is nonpayable";

    /// @dev revert condition being verified
    require userAmount == 0 || remainingNumerator == 0, "proportional product is zero";

    proportionalAmount@withrevert(e, userAmount, remainingNumerator, remainingDenominator);

    assert lastReverted;
}

/// @notice Proportional amount reverts when multiplication overflows.
/// @dev Verifies userAmount * remainingNumerator overflow.
rule proportionalAmount_RevertWhen_MultiplicationOverflows() {
    env e;
    uint256 userAmount;
    uint256 remainingNumerator;
    uint256 remainingDenominator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "proportionalAmount is nonpayable";

    /// @dev revert condition being verified
    require remainingNumerator != 0, "remaining numerator is nonzero";
    require userAmount > max_uint256 / remainingNumerator, "proportional multiplication overflows";
    require remainingDenominator != 0, "remaining denominator is nonzero";

    proportionalAmount@withrevert(e, userAmount, remainingNumerator, remainingDenominator);

    assert lastReverted;
}

/// @notice Proportional amount returns user amount's floor share of the remaining numerator.
/// @dev Verifies the proportional calculation branch.
rule proportionalAmount_Success() {
    env e;
    uint256 userAmount;
    uint256 remainingNumerator;
    uint256 remainingDenominator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "proportionalAmount is nonpayable";
    require remainingNumerator == 0 || userAmount <= max_uint256 / remainingNumerator,
        "proportional multiplication does not overflow";

    /// @dev success conditions being verified
    require remainingDenominator != 0, "remaining denominator is nonzero";

    uint256 amount = proportionalAmount@withrevert(e, userAmount, remainingNumerator, remainingDenominator);
    mathint expectedAmount = userAmount * remainingNumerator / remainingDenominator;

    assert !lastReverted;
    assert amount == expectedAmount;
}

/// ─────────────────── DEPOSIT ────────────────────────────────

/// @notice Depositing reverts when amount is less than the minimum.
/// @dev Verifies minimum deposit guard.
rule deposit_RevertWhen_AmountTooSmall() {
    env e;
    address user;
    uint256 amount;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";

    /// @dev revert condition being verified
    require amount < minDepositAmount, "amount is below minimum";

    storage before = lastStorage;

    deposit@withrevert(e, user, amount, minDepositAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Depositing reverts when the current epoch is not open.
/// @dev Verifies current epoch open guard.
rule deposit_RevertWhen_EpochNotOpen() {
    env e;
    address user;
    uint256 amount;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require amount >= minDepositAmount, "amount meets minimum";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    storage before = lastStorage;

    deposit@withrevert(e, user, amount, minDepositAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Depositing reverts when adding to the user's deposit overflows.
/// @dev Verifies deposit mapping addition overflow.
rule deposit_RevertWhen_UserDepositAdditionOverflows() {
    env e;
    address user;
    uint256 amount;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require amount >= minDepositAmount, "amount meets minimum";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getDeposit(user, epochNonce) > max_uint256 - amount, "user deposit addition overflows";

    storage before = lastStorage;

    deposit@withrevert(e, user, amount, minDepositAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Depositing reverts when adding to the epoch total deposit overflows.
/// @dev Verifies epoch total deposit addition overflow.
rule deposit_RevertWhen_EpochTotalDepositAdditionOverflows() {
    env e;
    address user;
    uint256 amount;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require amount >= minDepositAmount, "amount meets minimum";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getDeposit(user, epochNonce) <= max_uint256 - amount, "user deposit addition does not overflow";
    require getEpochTotalDepositAmount(epochNonce) > max_uint256 - amount,
        "epoch total deposit addition overflows";

    storage before = lastStorage;

    deposit@withrevert(e, user, amount, minDepositAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Depositing succeeds and records asset deposit during an open epoch.
/// @dev Verifies deposit storage, epoch total, token transfer, and DepositSubmitted event.
rule deposit_Success() {
    env e;
    address user;
    uint256 amount;
    uint256 minDepositAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require amount >= minDepositAmount, "amount meets minimum";

    uint256 epochNonce = getEpochNonce();
    uint256 depositBefore = getDeposit(user, epochNonce);
    uint256 totalDepositBefore = getEpochTotalDepositAmount(epochNonce);
    uint256 userBalanceBefore = asset.balanceOf(user);
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require depositBefore <= max_uint256 - amount, "user deposit addition does not overflow";
    require totalDepositBefore <= max_uint256 - amount, "epoch total deposit addition does not overflow";
    require userBalanceBefore >= amount, "user has enough asset";
    require vaultBalanceBefore <= max_uint256 - amount, "vault asset balance does not overflow";
    require asset.allowance(user, currentContract) >= amount, "vault is approved to transfer asset";

    /// @dev ghost starting values
    require ghost_DepositSubmitted_EventCount == 0, "DepositSubmitted event count starts at zero";

    uint256 returnedEpochNonce = deposit@withrevert(e, user, amount, minDepositAmount);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert getDeposit(user, epochNonce) == depositBefore + amount;
    assert getEpochTotalDepositAmount(epochNonce) == totalDepositBefore + amount;
    assert asset.balanceOf(user) == userBalanceBefore - amount;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amount;
    assert ghost_DepositSubmitted_EventCount == 1;
    assert ghost_DepositSubmitted_Param_epochNonce == epochNonce;
    assert ghost_DepositSubmitted_Param_depositor == user;
    assert ghost_DepositSubmitted_Param_amount == amount;
}

/// ─────────────────── WITHDRAW ───────────────────────────────

/// @notice Withdrawing reverts when share burn amount is zero.
/// @dev Verifies no-zero-amount guard.
rule withdraw_RevertWhen_AmountIsZero() {
    env e;
    address user;
    uint256 shareBurnAmount = 0;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";

    /// @dev revert condition being verified
    require shareBurnAmount == 0, "share burn amount is zero";

    storage before = lastStorage;

    withdraw@withrevert(e, user, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdrawing reverts when the current epoch is not open.
/// @dev Verifies current epoch open guard.
rule withdraw_RevertWhen_EpochNotOpen() {
    env e;
    address user;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require shareBurnAmount != 0, "share burn amount is nonzero";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    storage before = lastStorage;

    withdraw@withrevert(e, user, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdrawing reverts when adding to the user's withdraw intent overflows.
/// @dev Verifies withdraw mapping addition overflow.
rule withdraw_RevertWhen_UserWithdrawAdditionOverflows() {
    env e;
    address user;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require shareBurnAmount != 0, "share burn amount is nonzero";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getWithdraw(user, epochNonce) > max_uint256 - shareBurnAmount,
        "user withdraw addition overflows";

    storage before = lastStorage;

    withdraw@withrevert(e, user, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdrawing reverts when adding to the epoch total share burn overflows.
/// @dev Verifies epoch total share burn addition overflow.
rule withdraw_RevertWhen_EpochTotalShareBurnAdditionOverflows() {
    env e;
    address user;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require shareBurnAmount != 0, "share burn amount is nonzero";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getWithdraw(user, epochNonce) <= max_uint256 - shareBurnAmount,
        "user withdraw addition does not overflow";
    require getEpochTotalShareBurnAmount(epochNonce) > max_uint256 - shareBurnAmount,
        "epoch total share burn addition overflows";

    storage before = lastStorage;

    withdraw@withrevert(e, user, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdrawing succeeds and records share burn intent during an open epoch.
/// @dev Verifies withdraw storage, epoch total, token transfer, and WithdrawSubmitted event.
rule withdraw_Success() {
    env e;
    address user;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require shareBurnAmount != 0, "share burn amount is nonzero";

    uint256 epochNonce = getEpochNonce();
    uint256 withdrawBefore = getWithdraw(user, epochNonce);
    uint256 totalShareBurnBefore = getEpochTotalShareBurnAmount(epochNonce);
    uint256 userBalanceBefore = share.balanceOf(user);
    uint256 vaultBalanceBefore = share.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require withdrawBefore <= max_uint256 - shareBurnAmount, "user withdraw addition does not overflow";
    require totalShareBurnBefore <= max_uint256 - shareBurnAmount, "epoch total share burn addition does not overflow";
    require userBalanceBefore >= shareBurnAmount, "user has enough shares";
    require vaultBalanceBefore <= max_uint256 - shareBurnAmount, "vault share balance does not overflow";
    require share.allowance(user, currentContract) >= shareBurnAmount, "vault is approved to transfer shares";

    /// @dev ghost starting values
    require ghost_WithdrawSubmitted_EventCount == 0, "WithdrawSubmitted event count starts at zero";

    uint256 returnedEpochNonce = withdraw@withrevert(e, user, shareBurnAmount);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert getWithdraw(user, epochNonce) == withdrawBefore + shareBurnAmount;
    assert getEpochTotalShareBurnAmount(epochNonce) == totalShareBurnBefore + shareBurnAmount;
    assert share.balanceOf(user) == userBalanceBefore - shareBurnAmount;
    assert share.balanceOf(currentContract) == vaultBalanceBefore + shareBurnAmount;
    assert ghost_WithdrawSubmitted_EventCount == 1;
    assert ghost_WithdrawSubmitted_Param_epochNonce == epochNonce;
    assert ghost_WithdrawSubmitted_Param_withdrawer == user;
    assert ghost_WithdrawSubmitted_Param_shareBurnAmount == shareBurnAmount;
}

/// ─────────────────── CLAIM SHARES ───────────────────────────

/// @notice Claiming shares reverts when the epoch is not claimable.
/// @dev Verifies claimable epoch guard.
rule claimShares_RevertWhen_EpochNotClaimable() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.CLAIMABLE, "epoch is not claimable";

    storage before = lastStorage;

    claimShares@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares reverts when the user has no deposit for the epoch.
/// @dev Verifies no-deposit guard.
rule claimShares_RevertWhen_NoDeposit() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";

    /// @dev revert condition being verified
    require getDeposit(user, epochNonce) == 0, "user has no deposit";

    storage before = lastStorage;

    claimShares@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares reverts when proportional deposit claim denominator is zero.
/// @dev Verifies proportional claim division by zero.
rule claimShares_RevertWhen_ProportionalDenominatorIsZero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    uint256 depositAmount = getDeposit(user, epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require depositAmount != 0, "user has a deposit";
    require depositAmount != getEpochRemainingDepositClaimAmount(epochNonce), "user is not final deposit claimant";
    require getEpochRemainingDepositClaimAmount(epochNonce) == 0, "remaining deposit denominator is zero";
    require getEpochRemainingShareMintAmount(epochNonce) != 0, "remaining share mint numerator is nonzero";

    storage before = lastStorage;

    claimShares@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares reverts when proportional share calculation overflows.
/// @dev Verifies proportional deposit claim multiplication overflow.
rule claimShares_RevertWhen_ProportionalMultiplicationOverflows() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    uint256 depositAmount = getDeposit(user, epochNonce);
    uint256 remainingShareMintAmount = getEpochRemainingShareMintAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require depositAmount != 0, "user has a deposit";
    require depositAmount != getEpochRemainingDepositClaimAmount(epochNonce), "user is not final deposit claimant";
    require getEpochRemainingDepositClaimAmount(epochNonce) != 0, "remaining deposit denominator is nonzero";
    require remainingShareMintAmount != 0, "remaining share mint amount is nonzero";
    require depositAmount > max_uint256 / remainingShareMintAmount, "proportional share calculation overflows";

    storage before = lastStorage;

    claimShares@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares reverts when remaining deposit claim amount underflows.
/// @dev Verifies remainingDepositClaimAmount subtraction underflow.
rule claimShares_RevertWhen_RemainingDepositClaimAmountUnderflows() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    uint256 depositAmount = getDeposit(user, epochNonce);
    uint256 remainingDepositClaimAmount = getEpochRemainingDepositClaimAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require depositAmount != 0, "user has a deposit";
    require depositAmount != remainingDepositClaimAmount, "user is not final deposit claimant";
    require remainingDepositClaimAmount != 0, "remaining deposit denominator is nonzero";
    require getEpochRemainingShareMintAmount(epochNonce) == 0, "proportional share amount is zero";
    require depositAmount > remainingDepositClaimAmount, "remaining deposit claim amount underflows";

    storage before = lastStorage;

    claimShares@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares succeeds for the final deposit claimant.
/// @dev Verifies final-claim branch using all remaining share mint amount.
rule claimShares_Success_WhenFinalDepositClaimant() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    uint256 depositAmount = getDeposit(user, epochNonce);
    uint256 remainingShareMintAmount = getEpochRemainingShareMintAmount(epochNonce);
    uint256 userBalanceBefore = share.balanceOf(user);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require depositAmount != 0, "user has a deposit";
    require depositAmount == getEpochRemainingDepositClaimAmount(epochNonce), "user is final deposit claimant";
    require userBalanceBefore <= max_uint256 - remainingShareMintAmount, "user share balance does not overflow";
    require share.totalSupply() <= max_uint256 - remainingShareMintAmount, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_DepositClaimed_EventCount == 0, "DepositClaimed event count starts at zero";

    uint256 shareMintAmount = claimShares@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert shareMintAmount == remainingShareMintAmount;
    assert getDeposit(user, epochNonce) == 0;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == 0;
    assert getEpochRemainingShareMintAmount(epochNonce) == 0;
    assert share.balanceOf(user) == userBalanceBefore + remainingShareMintAmount;
    assert ghost_DepositClaimed_EventCount == 1;
    assert ghost_DepositClaimed_Param_epochNonce == epochNonce;
    assert ghost_DepositClaimed_Param_depositor == user;
    assert ghost_DepositClaimed_Param_shareMintAmount == remainingShareMintAmount;
}

/// @notice Claiming shares succeeds for a proportional deposit claimant.
/// @dev Verifies proportional deposit claim branch.
rule claimShares_Success_WhenProportionalDepositClaimant() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimShares is nonpayable";

    uint256 depositAmount = getDeposit(user, epochNonce);
    uint256 remainingDepositClaimAmount = getEpochRemainingDepositClaimAmount(epochNonce);
    uint256 remainingShareMintAmount = getEpochRemainingShareMintAmount(epochNonce);
    uint256 userBalanceBefore = share.balanceOf(user);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require depositAmount != 0, "user has a deposit";
    require depositAmount != remainingDepositClaimAmount, "user is not final deposit claimant";
    require remainingDepositClaimAmount != 0, "remaining deposit denominator is nonzero";
    require remainingShareMintAmount == 0 || depositAmount <= max_uint256 / remainingShareMintAmount,
        "proportional share calculation does not overflow";
    mathint shareMintAmount = depositAmount * remainingShareMintAmount / remainingDepositClaimAmount;
    require depositAmount <= remainingDepositClaimAmount, "remaining deposit claim amount does not underflow";
    require shareMintAmount <= remainingShareMintAmount, "remaining share mint amount does not underflow";
    require userBalanceBefore <= max_uint256 - shareMintAmount, "user share balance does not overflow";
    require share.totalSupply() <= max_uint256 - shareMintAmount, "share total supply does not overflow";

    /// @dev ghost starting values
    require ghost_DepositClaimed_EventCount == 0, "DepositClaimed event count starts at zero";

    uint256 returnedShareMintAmount = claimShares@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert returnedShareMintAmount == shareMintAmount;
    assert getDeposit(user, epochNonce) == 0;
    assert getEpochRemainingDepositClaimAmount(epochNonce) == remainingDepositClaimAmount - depositAmount;
    assert getEpochRemainingShareMintAmount(epochNonce) == remainingShareMintAmount - shareMintAmount;
    assert share.balanceOf(user) == userBalanceBefore + shareMintAmount;
    assert ghost_DepositClaimed_EventCount == 1;
    assert ghost_DepositClaimed_Param_epochNonce == epochNonce;
    assert ghost_DepositClaimed_Param_depositor == user;
    assert ghost_DepositClaimed_Param_shareMintAmount == shareMintAmount;
}

/// ─────────────────── CLAIM ASSET ────────────────────────────

/// @notice Claiming asset reverts when the epoch is not claimable.
/// @dev Verifies claimable epoch guard.
rule claimAsset_RevertWhen_EpochNotClaimable() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.CLAIMABLE, "epoch is not claimable";

    storage before = lastStorage;

    claimAsset@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset reverts when the user has no withdraw intent for the epoch.
/// @dev Verifies no-withdraw guard.
rule claimAsset_RevertWhen_NoWithdraw() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";

    /// @dev revert condition being verified
    require getWithdraw(user, epochNonce) == 0, "user has no withdraw intent";

    storage before = lastStorage;

    claimAsset@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset reverts when proportional withdraw claim denominator is zero.
/// @dev Verifies proportional withdraw division by zero.
rule claimAsset_RevertWhen_ProportionalDenominatorIsZero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount != getEpochRemainingShareBurnAmount(epochNonce), "user is not final withdraw claimant";
    require getEpochRemainingShareBurnAmount(epochNonce) == 0, "remaining share burn denominator is zero";
    require getEpochRemainingWithdrawClaimAmount(epochNonce) != 0, "remaining withdraw numerator is nonzero";

    storage before = lastStorage;

    claimAsset@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset reverts when proportional withdraw calculation overflows.
/// @dev Verifies proportional withdraw claim multiplication overflow.
rule claimAsset_RevertWhen_ProportionalMultiplicationOverflows() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 remainingWithdrawClaimAmount = getEpochRemainingWithdrawClaimAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount != getEpochRemainingShareBurnAmount(epochNonce), "user is not final withdraw claimant";
    require getEpochRemainingShareBurnAmount(epochNonce) != 0, "remaining share burn denominator is nonzero";
    require remainingWithdrawClaimAmount != 0, "remaining withdraw amount is nonzero";
    require shareBurnAmount > max_uint256 / remainingWithdrawClaimAmount,
        "proportional withdraw calculation overflows";

    storage before = lastStorage;

    claimAsset@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset reverts when remaining share burn amount underflows.
/// @dev Verifies remainingShareBurnAmount subtraction underflow.
rule claimAsset_RevertWhen_RemainingShareBurnAmountUnderflows() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 remainingShareBurnAmount = getEpochRemainingShareBurnAmount(epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount != remainingShareBurnAmount, "user is not final withdraw claimant";
    require remainingShareBurnAmount != 0, "remaining share burn denominator is nonzero";
    require getEpochRemainingWithdrawClaimAmount(epochNonce) == 0, "proportional withdraw amount is zero";
    require shareBurnAmount > remainingShareBurnAmount, "remaining share burn amount underflows";

    storage before = lastStorage;

    claimAsset@withrevert(e, user, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset succeeds for the final withdraw claimant with nonzero asset amount.
/// @dev Verifies final-claim branch and asset transfer branch.
rule claimAsset_Success_WhenFinalWithdrawClaimantAndAmountNonzero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 remainingWithdrawClaimAmount = getEpochRemainingWithdrawClaimAmount(epochNonce);
    uint256 userAssetBalanceBefore = asset.balanceOf(user);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount == getEpochRemainingShareBurnAmount(epochNonce), "user is final withdraw claimant";
    require remainingWithdrawClaimAmount != 0, "withdraw amount is nonzero";
    require share.totalSupply() >= shareBurnAmount, "share total supply covers burn";
    require vaultAssetBalanceBefore >= remainingWithdrawClaimAmount, "vault has enough asset";
    require userAssetBalanceBefore <= max_uint256 - remainingWithdrawClaimAmount, "user asset balance does not overflow";

    /// @dev ghost starting values
    require ghost_WithdrawClaimed_EventCount == 0, "WithdrawClaimed event count starts at zero";

    uint256 withdrawAmount = claimAsset@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert withdrawAmount == remainingWithdrawClaimAmount;
    assert getWithdraw(user, epochNonce) == 0;
    assert getEpochRemainingShareBurnAmount(epochNonce) == 0;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == 0;
    assert asset.balanceOf(user) == userAssetBalanceBefore + remainingWithdrawClaimAmount;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - remainingWithdrawClaimAmount;
    assert ghost_WithdrawClaimed_EventCount == 1;
    assert ghost_WithdrawClaimed_Param_epochNonce == epochNonce;
    assert ghost_WithdrawClaimed_Param_withdrawer == user;
    assert ghost_WithdrawClaimed_Param_amount == remainingWithdrawClaimAmount;
}

/// @notice Claiming asset succeeds for the final withdraw claimant with zero asset amount.
/// @dev Verifies final-claim branch and skipped asset transfer branch.
rule claimAsset_Success_WhenFinalWithdrawClaimantAndAmountZero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 userAssetBalanceBefore = asset.balanceOf(user);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount == getEpochRemainingShareBurnAmount(epochNonce), "user is final withdraw claimant";
    require getEpochRemainingWithdrawClaimAmount(epochNonce) == 0, "withdraw amount is zero";
    require share.totalSupply() >= shareBurnAmount, "share total supply covers burn";

    /// @dev ghost starting values
    require ghost_WithdrawClaimed_EventCount == 0, "WithdrawClaimed event count starts at zero";

    uint256 withdrawAmount = claimAsset@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert withdrawAmount == 0;
    assert getWithdraw(user, epochNonce) == 0;
    assert getEpochRemainingShareBurnAmount(epochNonce) == 0;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == 0;
    assert asset.balanceOf(user) == userAssetBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert ghost_WithdrawClaimed_EventCount == 1;
    assert ghost_WithdrawClaimed_Param_epochNonce == epochNonce;
    assert ghost_WithdrawClaimed_Param_withdrawer == user;
    assert ghost_WithdrawClaimed_Param_amount == 0;
}

/// @notice Claiming asset succeeds for a proportional withdraw claimant with zero asset amount.
/// @dev Verifies proportional withdraw claim branch and skipped asset transfer branch.
rule claimAsset_Success_WhenProportionalWithdrawClaimantAndAmountZero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 remainingShareBurnAmount = getEpochRemainingShareBurnAmount(epochNonce);
    uint256 remainingWithdrawClaimAmount = getEpochRemainingWithdrawClaimAmount(epochNonce);
    uint256 userAssetBalanceBefore = asset.balanceOf(user);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount != remainingShareBurnAmount, "user is not final withdraw claimant";
    require remainingShareBurnAmount != 0, "remaining share burn denominator is nonzero";
    require remainingWithdrawClaimAmount == 0 || shareBurnAmount <= max_uint256 / remainingWithdrawClaimAmount,
        "proportional withdraw calculation does not overflow";
    mathint withdrawAmount = shareBurnAmount * remainingWithdrawClaimAmount / remainingShareBurnAmount;
    require withdrawAmount == 0, "withdraw amount is zero";
    require shareBurnAmount <= remainingShareBurnAmount, "remaining share burn amount does not underflow";
    require share.totalSupply() >= shareBurnAmount, "share total supply covers burn";

    /// @dev ghost starting values
    require ghost_WithdrawClaimed_EventCount == 0, "WithdrawClaimed event count starts at zero";

    uint256 returnedWithdrawAmount = claimAsset@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert returnedWithdrawAmount == 0;
    assert getWithdraw(user, epochNonce) == 0;
    assert getEpochRemainingShareBurnAmount(epochNonce) == remainingShareBurnAmount - shareBurnAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == remainingWithdrawClaimAmount;
    assert asset.balanceOf(user) == userAssetBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert ghost_WithdrawClaimed_EventCount == 1;
    assert ghost_WithdrawClaimed_Param_epochNonce == epochNonce;
    assert ghost_WithdrawClaimed_Param_withdrawer == user;
    assert ghost_WithdrawClaimed_Param_amount == 0;
}

/// @notice Claiming asset succeeds for a proportional withdraw claimant with nonzero asset amount.
/// @dev Verifies proportional withdraw claim branch and asset transfer branch.
rule claimAsset_Success_WhenProportionalWithdrawClaimantAndAmountNonzero() {
    env e;
    address user;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "claimAsset is nonpayable";

    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 remainingShareBurnAmount = getEpochRemainingShareBurnAmount(epochNonce);
    uint256 remainingWithdrawClaimAmount = getEpochRemainingWithdrawClaimAmount(epochNonce);
    uint256 userAssetBalanceBefore = asset.balanceOf(user);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.CLAIMABLE, "epoch is claimable";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require shareBurnAmount != remainingShareBurnAmount, "user is not final withdraw claimant";
    require remainingShareBurnAmount != 0, "remaining share burn denominator is nonzero";
    require remainingWithdrawClaimAmount == 0 || shareBurnAmount <= max_uint256 / remainingWithdrawClaimAmount,
        "proportional withdraw calculation does not overflow";
    mathint withdrawAmount = shareBurnAmount * remainingWithdrawClaimAmount / remainingShareBurnAmount;
    require withdrawAmount != 0, "withdraw amount is nonzero";
    require shareBurnAmount <= remainingShareBurnAmount, "remaining share burn amount does not underflow";
    require withdrawAmount <= remainingWithdrawClaimAmount, "remaining withdraw claim amount does not underflow";
    require share.totalSupply() >= shareBurnAmount, "share total supply covers burn";
    require vaultAssetBalanceBefore >= withdrawAmount, "vault has enough asset";
    require userAssetBalanceBefore <= max_uint256 - withdrawAmount, "user asset balance does not overflow";

    /// @dev ghost starting values
    require ghost_WithdrawClaimed_EventCount == 0, "WithdrawClaimed event count starts at zero";

    uint256 returnedWithdrawAmount = claimAsset@withrevert(e, user, epochNonce);

    assert !lastReverted;
    assert returnedWithdrawAmount == withdrawAmount;
    assert getWithdraw(user, epochNonce) == 0;
    assert getEpochRemainingShareBurnAmount(epochNonce) == remainingShareBurnAmount - shareBurnAmount;
    assert getEpochRemainingWithdrawClaimAmount(epochNonce) == remainingWithdrawClaimAmount - withdrawAmount;
    assert asset.balanceOf(user) == userAssetBalanceBefore + withdrawAmount;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - withdrawAmount;
    assert ghost_WithdrawClaimed_EventCount == 1;
    assert ghost_WithdrawClaimed_Param_epochNonce == epochNonce;
    assert ghost_WithdrawClaimed_Param_withdrawer == user;
    assert ghost_WithdrawClaimed_Param_amount == withdrawAmount;
}

/// ─────────────────── CANCELLATIONS ──────────────────────────

/// @notice Canceling a deposit reverts when the current epoch is not open.
/// @dev Verifies current epoch open guard.
rule cancelDeposit_RevertWhen_EpochNotOpen() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelDeposit is nonpayable";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    storage before = lastStorage;

    cancelDeposit@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a deposit reverts when the user has no deposit for the current epoch.
/// @dev Verifies no-deposit guard.
rule cancelDeposit_RevertWhen_NoDeposit() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelDeposit is nonpayable";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getDeposit(user, epochNonce) == 0, "user has no deposit";

    storage before = lastStorage;

    cancelDeposit@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a deposit reverts when epoch total deposit underflows.
/// @dev Verifies epoch total deposit subtraction underflow.
rule cancelDeposit_RevertWhen_EpochTotalDepositUnderflows() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelDeposit is nonpayable";

    uint256 epochNonce = getEpochNonce();
    uint256 depositAmount = getDeposit(user, epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require depositAmount != 0, "user has a deposit";
    require getEpochTotalDepositAmount(epochNonce) < depositAmount, "epoch total deposit underflows";

    storage before = lastStorage;

    cancelDeposit@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a deposit succeeds and returns the deposited asset.
/// @dev Verifies deposit deletion, epoch total decrease, asset transfer, and DepositCancelled event.
rule cancelDeposit_Success() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelDeposit is nonpayable";

    uint256 epochNonce = getEpochNonce();
    uint256 depositAmount = getDeposit(user, epochNonce);
    uint256 totalDepositBefore = getEpochTotalDepositAmount(epochNonce);
    uint256 userBalanceBefore = asset.balanceOf(user);
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require depositAmount != 0, "user has a deposit";
    require totalDepositBefore >= depositAmount, "epoch total deposit does not underflow";
    require vaultBalanceBefore >= depositAmount, "vault has enough asset";
    require userBalanceBefore <= max_uint256 - depositAmount, "user asset balance does not overflow";

    /// @dev ghost starting values
    require ghost_DepositCancelled_EventCount == 0, "DepositCancelled event count starts at zero";

    cancelDeposit@withrevert(e, user);

    assert !lastReverted;
    assert getDeposit(user, epochNonce) == 0;
    assert getEpochTotalDepositAmount(epochNonce) == totalDepositBefore - depositAmount;
    assert asset.balanceOf(user) == userBalanceBefore + depositAmount;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - depositAmount;
    assert ghost_DepositCancelled_EventCount == 1;
    assert ghost_DepositCancelled_Param_epochNonce == epochNonce;
    assert ghost_DepositCancelled_Param_depositor == user;
    assert ghost_DepositCancelled_Param_amount == depositAmount;
}

/// @notice Canceling a withdraw reverts when the current epoch is not open.
/// @dev Verifies current epoch open guard.
rule cancelWithdraw_RevertWhen_EpochNotOpen() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelWithdraw is nonpayable";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) != Types.EpochStatus.OPEN, "epoch is not open";

    storage before = lastStorage;

    cancelWithdraw@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a withdraw reverts when the user has no withdraw intent for the current epoch.
/// @dev Verifies no-withdraw guard.
rule cancelWithdraw_RevertWhen_NoWithdraw() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelWithdraw is nonpayable";

    uint256 epochNonce = getEpochNonce();

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require getWithdraw(user, epochNonce) == 0, "user has no withdraw intent";

    storage before = lastStorage;

    cancelWithdraw@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a withdraw reverts when epoch total share burn underflows.
/// @dev Verifies epoch total share burn subtraction underflow.
rule cancelWithdraw_RevertWhen_EpochTotalShareBurnUnderflows() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelWithdraw is nonpayable";

    uint256 epochNonce = getEpochNonce();
    uint256 shareBurnAmount = getWithdraw(user, epochNonce);

    /// @dev revert condition being verified
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require getEpochTotalShareBurnAmount(epochNonce) < shareBurnAmount, "epoch total share burn underflows";

    storage before = lastStorage;

    cancelWithdraw@withrevert(e, user);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Canceling a withdraw succeeds and returns the escrowed shares.
/// @dev Verifies withdraw deletion, epoch total decrease, share transfer, and WithdrawCancelled event.
rule cancelWithdraw_Success() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "cancelWithdraw is nonpayable";

    uint256 epochNonce = getEpochNonce();
    uint256 shareBurnAmount = getWithdraw(user, epochNonce);
    uint256 totalShareBurnBefore = getEpochTotalShareBurnAmount(epochNonce);
    uint256 userBalanceBefore = share.balanceOf(user);
    uint256 vaultBalanceBefore = share.balanceOf(currentContract);

    /// @dev success conditions being verified
    require user != currentContract, "user is not the vault";
    require getEpochStatus(epochNonce) == Types.EpochStatus.OPEN, "epoch is open";
    require shareBurnAmount != 0, "user has a withdraw intent";
    require totalShareBurnBefore >= shareBurnAmount, "epoch total share burn does not underflow";
    require vaultBalanceBefore >= shareBurnAmount, "vault has enough shares";
    require userBalanceBefore <= max_uint256 - shareBurnAmount, "user share balance does not overflow";

    /// @dev ghost starting values
    require ghost_WithdrawCancelled_EventCount == 0, "WithdrawCancelled event count starts at zero";

    cancelWithdraw@withrevert(e, user);

    assert !lastReverted;
    assert getWithdraw(user, epochNonce) == 0;
    assert getEpochTotalShareBurnAmount(epochNonce) == totalShareBurnBefore - shareBurnAmount;
    assert share.balanceOf(user) == userBalanceBefore + shareBurnAmount;
    assert share.balanceOf(currentContract) == vaultBalanceBefore - shareBurnAmount;
    assert ghost_WithdrawCancelled_EventCount == 1;
    assert ghost_WithdrawCancelled_Param_epochNonce == epochNonce;
    assert ghost_WithdrawCancelled_Param_withdrawer == user;
    assert ghost_WithdrawCancelled_Param_shareBurnAmount == shareBurnAmount;
}
