using MockUSDC as asset;

/// Verification of ProtocolAdapter
/// @author @contractlevel
/// @notice ProtocolAdapter is the base contract for all protocol adapters - 
///         modular contracts that interact with yield generating strategy protocols like AaveV3, V4, CompoundV3 etc.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // ProtocolAdapter methods
    function deposit(uint256) external;
    function withdraw(uint256) external returns (uint256);
    function getTVL() external returns (uint256) envfree;
    function getProtocolPool() external returns (address) envfree;
    function getVault() external returns (address) envfree;
    function getAsset() external returns (address) envfree;

    // Adapter-agnostic harness helper methods
    function mockDepositDecreasesTVL() external returns (bool) envfree;
    function mockDepositTVLChange() external returns (uint256) envfree;
    function mockWithdrawAmount() external returns (uint256) envfree;

    // External methods
    function asset.balanceOf(address) external returns (uint256) envfree;

    // Wildcard dispatcher summaries
    function _.getAsset() external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);

    // HelperHarness methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition DepositEvent() returns bytes32 =
// keccak256("Deposit(uint256)")
    to_bytes32(0x4d6ce1e535dbade1c23defba91e23b8f791ce5edc0cc320257a2b364e4e38426);

definition WithdrawEvent() returns bytes32 =
// keccak256("Withdraw(uint256)")
    to_bytes32(0x5b6b431d4476a211bb7d41c20d1aab9ae2321deee0d20be3d9fc9b1093fa6e3d);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount Deposit event is emitted
ghost mathint ghost_Deposit_EventCount {
    init_state axiom ghost_Deposit_EventCount == 0;
}

/// @notice EmittedValue: track amount emitted in Deposit event
ghost mathint ghost_Deposit_EventParam_amount {
    init_state axiom ghost_Deposit_EventParam_amount == 0;
}

/// @notice EventCount: track amount Withdraw event is emitted
ghost mathint ghost_Withdraw_EventCount {
    init_state axiom ghost_Withdraw_EventCount == 0;
}

/// @notice EmittedValue: track amount emitted in Withdraw event
ghost mathint ghost_Withdraw_EventParam_amount {
    init_state axiom ghost_Withdraw_EventParam_amount == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == DepositEvent()) {
        ghost_Deposit_EventCount = ghost_Deposit_EventCount + 1;
        ghost_Deposit_EventParam_amount = bytes32ToUint256(t1);
    }

    if (t0 == WithdrawEvent()) {
        ghost_Withdraw_EventCount = ghost_Withdraw_EventCount + 1;
        ghost_Withdraw_EventParam_amount = bytes32ToUint256(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule noZero() {
    assert currentContract.i_asset != 0 && currentContract.i_vault != 0;
}

rule assetConsistency(env e) {
    assert currentContract.i_asset == currentContract.i_vault.getAsset(e);
}

rule ADAPTER_004_deposit_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require currentContract._status == 1, "deposit is nonReentrant";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore <= max_uint256 - tvlChange, "TVL increase should not overflow";
    require tvlChange >= amount || amount - tvlChange <= 100, "exclude incomplete deposit revert";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
}

rule deposit_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore <= max_uint256 - tvlChange, "TVL increase should not overflow";
    require tvlChange >= amount || amount - tvlChange <= 100, "exclude incomplete deposit revert";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require currentContract._status == 2, "reentrancy guard is entered";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
}

rule deposit_RevertWhen_TVLDecreases() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require mockDepositDecreasesTVL(), "TVL decreases during deposit";
    require tvlChange > 0, "TVL decrease is nonzero";
    require tvlChange <= tvlBefore, "mock TVL decrease should not underflow";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
}

rule deposit_RevertWhen_CreditedShortfallExceedsRoundingTolerance() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore <= max_uint256 - creditedAmount, "TVL increase should not overflow";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require creditedAmount < amount, "credited amount is less than requested amount";
    require amount - creditedAmount > 100, "credited shortfall exceeds rounding tolerance";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
}

rule deposit_Success() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore <= max_uint256 - creditedAmount, "TVL increase should not overflow";
    require creditedAmount >= amount || amount - creditedAmount <= 100, "credited shortfall is within tolerance";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getTVL() == tvlBefore + creditedAmount;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
}

rule ADAPTER_004_withdraw_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "exercise epoch withdraw path";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require amountOut >= amount, "actual withdraw amount is sufficient";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule withdraw_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require amount != max_uint256, "exercise epoch withdraw path";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require amountOut >= amount, "actual withdraw amount is sufficient";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require currentContract._status == 2, "reentrancy guard is entered";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule withdraw_Epoch_RevertWhen_AmountExceedsTVL() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require asset.balanceOf(currentContract) <= max_uint256 - mockWithdrawAmount(),
        "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - mockWithdrawAmount(), "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= mockWithdrawAmount(), "protocol asset balance covers withdraw";

    /// @dev epoch withdraw condition
    require amount != max_uint256, "amount is not max uint256";

    /// @dev revert condition being verified
    require amount > getTVL(), "amount exceeds TVL";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule withdraw_Epoch_RevertWhen_ActualWithdrawnAmountIsInsufficient() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "amount is not max uint256";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut < amount, "actual withdrawn amount is insufficient";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule withdraw_Epoch_Success() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 expectedAmountOut = mockWithdrawAmount();
    uint256 adapterBalanceBefore = asset.balanceOf(e, currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(e, getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "amount is not max uint256";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require expectedAmountOut >= amount, "actual withdrawn amount is sufficient";
    require adapterBalanceBefore <= max_uint256 - expectedAmountOut, "adapter can receive withdrawn asset";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= expectedAmountOut, "protocol asset balance covers withdraw";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";

    uint256 amountOut = withdraw@withrevert(e, amount);

    assert !lastReverted;
    assert amountOut == expectedAmountOut;
    assert getTVL() == tvlBefore - amount;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
}

rule withdraw_Rebalance_RevertWhen_ActualWithdrawnAmountIsInsufficient() {
    env e;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut < tvlBefore, "actual withdrawn amount is less than pre-withdraw TVL";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, max_uint256);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule withdraw_Rebalance_Success() {
    env e;
    uint256 tvlBefore = getTVL();
    uint256 expectedAmountOut = mockWithdrawAmount();
    uint256 adapterBalanceBefore = asset.balanceOf(e, currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(e, getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require expectedAmountOut >= tvlBefore, "actual withdrawn amount covers pre-withdraw TVL";
    require adapterBalanceBefore <= max_uint256 - expectedAmountOut, "adapter can receive withdrawn asset";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= expectedAmountOut, "protocol asset balance covers withdraw";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";

    uint256 amountOut = withdraw@withrevert(e, max_uint256);

    assert !lastReverted;
    assert amountOut == expectedAmountOut;
    assert getTVL() == 0;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
}
