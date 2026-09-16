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
    function getBufferedAssets() external returns (uint256) envfree;

    // Adapter-agnostic harness helper methods
    function mockDepositDecreasesTVL() external returns (bool) envfree;
    function mockDepositReverts() external returns (bool) envfree;
    function mockWithdrawReverts() external returns (bool) envfree;
    function mockDepositTVLChange() external returns (uint256) envfree;
    function mockWithdrawAmount() external returns (uint256) envfree;
    function mockUsesBufferedAssets() external returns (bool) envfree;
    function mockDepositCanSupply(uint256) external returns (bool) envfree;
    function mockDepositCanBuffer(uint256) external returns (bool) envfree;

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

definition DepositBufferedEvent() returns bytes32 =
// keccak256("DepositBuffered(uint256,uint256)")
    to_bytes32(0x9f8115ab397b99ef916b2f9345b529fe9caf2b784fe2aba7fa6f01f815deaa2a);

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

/// @notice EventCount: track amount DepositBuffered event is emitted
ghost mathint ghost_DepositBuffered_EventCount {
    init_state axiom ghost_DepositBuffered_EventCount == 0;
}

/// @notice EmittedValue: track amount emitted in DepositBuffered event
ghost mathint ghost_DepositBuffered_EventParam_amount {
    init_state axiom ghost_DepositBuffered_EventParam_amount == 0;
}

/// @notice EmittedValue: track total buffered assets emitted in DepositBuffered event
ghost mathint ghost_DepositBuffered_EventParam_totalBufferedAssets {
    init_state axiom ghost_DepositBuffered_EventParam_totalBufferedAssets == 0;
}

/// @notice StoreCount: track writes to s_bufferedAssets
ghost mathint ghost_BufferedAssets_StoreCount {
    init_state axiom ghost_BufferedAssets_StoreCount == 0;
}

/// @notice StoredValue: track the last value written to s_bufferedAssets
ghost uint256 ghost_BufferedAssets_StoredValue {
    init_state axiom ghost_BufferedAssets_StoredValue == 0;
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

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == DepositBufferedEvent()) {
        ghost_DepositBuffered_EventCount = ghost_DepositBuffered_EventCount + 1;
        ghost_DepositBuffered_EventParam_amount = bytes32ToUint256(t1);
        ghost_DepositBuffered_EventParam_totalBufferedAssets = bytes32ToUint256(t2);
    }
}

/// @notice hook onto s_bufferedAssets storage writes
hook Sstore s_bufferedAssets uint256 newValue (uint256 oldValue) {
    ghost_BufferedAssets_StoreCount = ghost_BufferedAssets_StoreCount + 1;
    ghost_BufferedAssets_StoredValue = newValue;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule noZero() {
    assert currentContract.i_asset != 0 && currentContract.i_vault != 0;
}

rule getBufferedAssets_ReturnsStoredBufferedAssets() {
    assert getBufferedAssets() == currentContract.s_bufferedAssets;
}

rule ADAPTER_006_assetConsistency(env e) {
    assert currentContract.i_asset == currentContract.i_vault.getAsset(e);
}

rule ADAPTER_004_deposit_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();
    uint256 bufferedAssetsBefore = mockUsesBufferedAssets() ? getBufferedAssets() : 0;
    mathint amountToSupply = bufferedAssetsBefore + amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "exclude zero Aave deposit revert";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent deposited amount";
    require currentContract._status == 1, "deposit is nonReentrant";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - tvlChange, "TVL increase should not overflow";
    require tvlChange >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlChange >= amountToSupply || amountToSupply - tvlChange <= 100, "exclude incomplete deposit revert";
    require asset.balanceOf(currentContract) >= amountToSupply, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule REENT_001_deposit_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();
    uint256 bufferedAssetsBefore = mockUsesBufferedAssets() ? getBufferedAssets() : 0;
    mathint amountToSupply = bufferedAssetsBefore + amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "exclude zero Aave deposit revert";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent deposited amount";
    require e.msg.sender == getVault(), "caller is vault";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - tvlChange, "TVL increase should not overflow";
    require tvlChange >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlChange >= amountToSupply || amountToSupply - tvlChange <= 100, "exclude incomplete deposit revert";
    require asset.balanceOf(currentContract) >= amountToSupply, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply, "protocol can receive deposited asset";

    /// @dev revert condition being verified
    require currentContract._status == 2, "reentrancy guard is entered";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_RevertWhen_TVLDecreases() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 tvlChange = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "exclude zero Aave deposit revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise deposit without buffered assets";
    require mockDepositCanSupply(amount), "protocol can represent deposited amount";
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
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_RevertWhen_CreditedShortfallExceedsRoundingTolerance() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "exclude zero Aave deposit revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise deposit without buffered assets";
    require mockDepositCanSupply(amount), "protocol can represent deposited amount";
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
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_Success() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "exclude zero Aave deposit revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise deposit without buffered assets";
    require mockDepositCanSupply(amount), "protocol can represent deposited amount";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore <= max_uint256 - creditedAmount, "TVL increase should not overflow";
    require creditedAmount >= amount || amount - creditedAmount <= 100, "credited shortfall is within tolerance";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol can receive deposited asset";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getTVL() == tvlBefore + creditedAmount;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_Deposit_EventParam_amount == amount;
}

rule ADAPTER_004_withdraw_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "Aave must withdraw a nonzero protocol amount";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "exercise epoch withdraw path";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require amountOut != 0, "actual withdraw amount is nonzero";
    require amountOut >= amount || amount - amountOut <= 100,
        "actual withdraw amount is sufficient or within tolerance";
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

rule REENT_001_withdraw_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "Aave must withdraw a nonzero protocol amount";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require amount != max_uint256, "exercise epoch withdraw path";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require amountOut != 0, "actual withdraw amount is nonzero";
    require amountOut >= amount || amount - amountOut <= 100,
        "actual withdraw amount is sufficient or within tolerance";
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

/// @notice Epoch withdrawals revert when the protocol returns zero assets.
/// @dev Zero is never accepted by the shared withdrawal tolerance check.
rule ADAPTER_008_withdraw_Epoch_RevertWhen_ActualWithdrawnAmountIsZero() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "amount is not max uint256";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut,
        "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut,
        "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut == 0, "actual withdrawn amount is zero";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule ADAPTER_008_withdraw_Epoch_RevertWhen_AmountExceedsTVL() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "Aave must withdraw a nonzero protocol amount";
    require !mockUsesBufferedAssets() || getBufferedAssets() <= 50, "buffered assets are within the limit";
    require !mockUsesBufferedAssets() || asset.balanceOf(currentContract) >= getBufferedAssets(),
        "adapter asset balance covers buffered assets";
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
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert ghost_Withdraw_EventCount == 0;
}

rule ADAPTER_008_withdraw_Epoch_RevertWhen_ActualWithdrawnAmountIsInsufficient() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "Aave must withdraw a nonzero protocol amount";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "amount is not max uint256";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut != 0, "actual withdrawn amount is nonzero";
    require amountOut < amount, "actual withdrawn amount is insufficient";
    require amount - amountOut > 100, "shortfall exceeds rounding tolerance";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule ADAPTER_008_ADAPTER_009_withdraw_Epoch_Success() {
    env e;
    uint256 amount;
    uint256 tvlBefore = getTVL();
    uint256 expectedAmountOut = mockWithdrawAmount();
    uint256 adapterBalanceBefore = asset.balanceOf(e, currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(e, getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || amount != 0, "Aave must withdraw a nonzero protocol amount";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount != max_uint256, "amount is not max uint256";
    require amount <= tvlBefore, "amount does not exceed TVL";
    require expectedAmountOut != 0, "actual withdrawn amount is nonzero";
    require expectedAmountOut >= amount || amount - expectedAmountOut <= 100,
        "actual withdrawn amount is sufficient or within tolerance";
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

rule ADAPTER_008_withdraw_Rebalance_RevertWhen_ActualWithdrawnAmountIsInsufficient() {
    env e;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut, "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut, "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut, "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut != 0, "actual withdrawn amount is nonzero";
    require amountOut < tvlBefore, "actual withdrawn amount is less than pre-withdraw TVL";
    require tvlBefore - amountOut > 100, "shortfall exceeds rounding tolerance";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, max_uint256);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

/// @notice Full-position withdrawals revert when the protocol returns zero assets.
/// @dev Zero is never accepted by the shared withdrawal tolerance check.
rule ADAPTER_008_withdraw_Rebalance_RevertWhen_ActualWithdrawnAmountIsZero() {
    env e;
    uint256 tvlBefore = getTVL();
    uint256 amountOut = mockWithdrawAmount();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "adapter can receive withdrawn asset";
    require asset.balanceOf(getVault()) <= max_uint256 - amountOut,
        "vault can receive withdrawn asset";
    require asset.balanceOf(getProtocolPool()) >= amountOut,
        "protocol asset balance covers withdraw";

    /// @dev revert condition being verified
    require amountOut == 0, "actual withdrawn amount is zero";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";

    withdraw@withrevert(e, max_uint256);

    assert lastReverted;
    assert ghost_Withdraw_EventCount == 0;
}

rule ADAPTER_008_ADAPTER_009_withdraw_Rebalance_Success() {
    env e;
    uint256 tvlBefore = getTVL();
    uint256 expectedAmountOut = mockWithdrawAmount();
    uint256 adapterBalanceBefore = asset.balanceOf(e, currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(e, getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require !mockUsesBufferedAssets() || getBufferedAssets() == 0, "exercise withdrawal without buffered assets";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require !mockUsesBufferedAssets() || tvlBefore != 0, "Aave must have a nonzero protocol position";
    require expectedAmountOut != 0, "actual withdrawn amount is nonzero";
    require expectedAmountOut >= tvlBefore || tvlBefore - expectedAmountOut <= 100,
        "actual withdrawn amount covers TVL or is within tolerance";
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

/// @dev Buffered deposit rules apply only to Aave adapters; exclude them from the Compound target.
rule ADAPTER_007_deposit_RevertWhen_AmountIsZero() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - bufferedAssetsBefore,
        "protocol can receive flushed buffered assets";
    require mockDepositCanBuffer(0), "protocol cannot represent a zero deposit";

    /// @dev revert condition being verified
    require amount == 0, "deposit amount is zero";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_Buffered_Success() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require tvlBefore <= max_uint256 - amount, "buffered TVL increase should not overflow";

    /// @dev conditions being verified
    require amountToSupply <= 50, "combined buffered assets are within the limit";
    require mockDepositCanBuffer(assert_uint256(amountToSupply)), "protocol cannot represent combined deposit";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getBufferedAssets() == amountToSupply;
    assert getTVL() == tvlBefore + amount;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventCount == 1;
    assert ghost_DepositBuffered_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventParam_totalBufferedAssets == amountToSupply;
    assert ghost_BufferedAssets_StoreCount == 1;
    assert ghost_BufferedAssets_StoredValue == amountToSupply;
}

rule ADAPTER_007_deposit_Buffered_RevertWhen_LimitExceeded() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require mockDepositCanBuffer(assert_uint256(amountToSupply)), "protocol cannot represent combined deposit";

    /// @dev revert condition being verified
    require amountToSupply > 50, "combined buffered assets exceed the limit";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

rule ADAPTER_007_deposit_Success_FlushesBufferedAssets() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent combined deposit";

    /// @dev conditions being verified
    require bufferedAssetsBefore != 0, "adapter has buffered assets to flush";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getBufferedAssets() == 0;
    assert getTVL() == tvlBefore - bufferedAssetsBefore + creditedAmount;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 1;
    assert ghost_BufferedAssets_StoredValue == 0;
}

rule ADAPTER_007_deposit_WithBufferedAssets_RevertWhen_TVLDecreases() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require amountToSupply - creditedAmount <= 100, "exclude excessive credited shortfall";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent combined deposit";

    /// @dev revert condition being verified
    require creditedAmount < bufferedAssetsBefore, "protocol credit does not cover flushed buffered assets";
    require bufferedAssetsBefore != 0, "adapter has buffered assets to flush";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

rule ADAPTER_007_deposit_WithBufferedAssets_RevertWhen_CreditedShortfallExceedsRoundingTolerance() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require !mockDepositReverts(), "protocol supply should not revert";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent combined deposit";

    /// @dev revert condition being verified
    require creditedAmount < amountToSupply, "combined deposit credit is insufficient";
    require amountToSupply - creditedAmount > 100, "combined deposit credited shortfall exceeds tolerance";
    require bufferedAssetsBefore != 0, "adapter has buffered assets to flush";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

rule ADAPTER_007_deposit_WithBufferedAssets_RevertWhen_ProtocolSupplyFails() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 tvlBefore = getTVL();
    uint256 creditedAmount = mockDepositTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !mockDepositDecreasesTVL(), "TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require tvlBefore - bufferedAssetsBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require mockDepositCanSupply(assert_uint256(amountToSupply)), "protocol can represent combined deposit";

    /// @dev revert condition being verified
    require mockDepositReverts(), "protocol supply should revert";
    require bufferedAssetsBefore != 0, "adapter has buffered assets to flush";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";
    require ghost_DepositBuffered_EventParam_amount == 0, "DepositBuffered amount ghost starts at zero";
    require ghost_DepositBuffered_EventParam_totalBufferedAssets == 0, "DepositBuffered total ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

/// @dev The protocol withdrawal is skipped when the buffer covers the entire requested amount.
rule ADAPTER_008_ADAPTER_009_withdraw_Epoch_Success_FromBufferedAssetsOnly() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore <= 50, "buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require vaultBalanceBefore <= max_uint256 - amount, "vault can receive withdrawn assets";

    /// @dev conditions being verified
    require amount != 0, "withdrawal amount is nonzero";
    require amount <= bufferedAssetsBefore, "buffer covers entire withdrawal";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, amount);

    assert !lastReverted;
    assert amountOut == amount;
    assert getBufferedAssets() == bufferedAssetsBefore - amount;
    assert getTVL() == tvlBefore - amount;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore - amountOut;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
    assert ghost_BufferedAssets_StoreCount == 1;
    assert ghost_BufferedAssets_StoredValue == bufferedAssetsBefore - amount;
}

/// @dev The protocol withdrawal is skipped when the buffer covers the entire requested amount.
rule ADAPTER_008_ADAPTER_009_withdraw_Rebalance_Success_FromBufferedAssetsOnly() {
    env e;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore <= 50, "buffered assets are within the limit";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require vaultBalanceBefore <= max_uint256 - bufferedAssetsBefore, "vault can receive withdrawn assets";

    /// @dev conditions being verified
    require bufferedAssetsBefore != 0, "buffered assets are nonzero";
    require tvlBefore == bufferedAssetsBefore, "protocol position is empty";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, max_uint256);

    assert !lastReverted;
    assert amountOut == bufferedAssetsBefore;
    assert getBufferedAssets() == 0;
    assert getTVL() == 0;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore - amountOut;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
    assert ghost_BufferedAssets_StoreCount == 1;
    assert ghost_BufferedAssets_StoredValue == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule ADAPTER_008_ADAPTER_009_withdraw_WithBufferedAssets_Success() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require protocolAmountOut != 0, "protocol withdrawal amount is nonzero";
    require protocolAmountOut >= protocolWithdrawAmount || protocolWithdrawAmount - protocolAmountOut <= 100,
        "protocol withdrawal shortfall is within tolerance";

    /// @dev conditions being verified
    require expectedAmountOut != 0, "combined withdrawal amount is nonzero";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert !lastReverted;
    assert amountOut == expectedAmountOut;
    assert getBufferedAssets() == 0;
    assert getTVL() == (isRebalance ? 0 : tvlBefore - amount);
    assert asset.balanceOf(currentContract) == adapterBalanceBefore - bufferedAssetsBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
    assert ghost_BufferedAssets_StoreCount == 1;
    assert ghost_BufferedAssets_StoredValue == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule ADAPTER_008_withdraw_WithBufferedAssets_RevertWhen_ProtocolReturnsZero() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";

    /// @dev revert condition being verified
    require protocolAmountOut == 0, "protocol returns zero despite the nonzero buffer";
    require protocolWithdrawAmount <= 100, "exclude excessive combined withdrawal shortfall";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule ADAPTER_008_withdraw_WithBufferedAssets_RevertWhen_ProtocolAmountIsInsufficient() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require protocolAmountOut != 0, "protocol withdrawal amount is nonzero";

    /// @dev revert condition being verified
    require protocolAmountOut < protocolWithdrawAmount, "protocol returns less than requested";
    require protocolWithdrawAmount - protocolAmountOut > 100, "protocol withdrawal shortfall exceeds tolerance";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule ADAPTER_008_withdraw_WithBufferedAssets_RevertWhen_ProtocolWithdrawalFails() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require protocolAmountOut != 0, "protocol withdrawal amount is nonzero";
    require protocolAmountOut >= protocolWithdrawAmount || protocolWithdrawAmount - protocolAmountOut <= 100,
        "protocol withdrawal shortfall is within tolerance";

    /// @dev revert condition being verified
    require mockWithdrawReverts(), "protocol withdrawal should revert";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule ADAPTER_004_withdraw_WithBufferedAssets_RevertWhen_CallerIsNotVault() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require protocolAmountOut != 0, "protocol withdrawal amount is nonzero";
    require protocolAmountOut >= protocolWithdrawAmount || protocolWithdrawAmount - protocolAmountOut <= 100,
        "protocol withdrawal shortfall is within tolerance";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

/// @dev Both epoch and max-sentinel withdrawals consume the buffer before withdrawing from the protocol.
rule REENT_001_withdraw_WithBufferedAssets_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    bool isRebalance;
    uint256 amount;
    uint256 requestedAmount = isRebalance ? max_uint256 : amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 protocolAmountOut = mockWithdrawAmount();
    mathint protocolWithdrawAmount = isRebalance ? tvlBefore - bufferedAssetsBefore : amount - bufferedAssetsBefore;
    mathint expectedAmountOut = bufferedAssetsBefore + protocolAmountOut;
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";
    require isRebalance || amount != max_uint256, "ordinary withdrawal does not use max sentinel";
    require isRebalance || amount <= tvlBefore, "ordinary withdrawal amount does not exceed total TVL";
    require protocolWithdrawAmount > 0, "withdrawal requires both buffer and protocol assets";
    require adapterBalanceBefore >= bufferedAssetsBefore, "adapter asset balance covers buffered assets";
    require expectedAmountOut <= max_uint256, "combined withdrawal amount should not overflow";
    require adapterBalanceBefore <= max_uint256 - protocolAmountOut, "adapter can receive protocol assets";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault can receive combined withdrawn assets";
    require asset.balanceOf(getProtocolPool()) >= protocolAmountOut, "protocol asset balance covers withdrawal";
    require !mockWithdrawReverts(), "protocol withdrawal should not revert";
    require protocolAmountOut != 0, "protocol withdrawal amount is nonzero";
    require protocolAmountOut >= protocolWithdrawAmount || protocolWithdrawAmount - protocolAmountOut <= 100,
        "protocol withdrawal shortfall is within tolerance";

    /// @dev revert condition being verified
    require currentContract._status == 2, "reentrancy guard is entered";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";
    require ghost_BufferedAssets_StoredValue == 0, "buffered assets stored value starts at zero";

    uint256 amountOut = withdraw@withrevert(e, requestedAmount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

rule ADAPTER_008_withdraw_WithBufferedAssets_RevertWhen_AmountIsZero() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore != 0 && bufferedAssetsBefore <= 50, "adapter has bounded buffered assets";
    require tvlBefore >= bufferedAssetsBefore, "total TVL covers buffered assets";

    /// @dev The protocol withdrawal is skipped, so its configured output and failure flag are irrelevant.
    /// @dev revert condition being verified
    require amount == 0, "withdrawal amount is zero";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";

    withdraw@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}

rule ADAPTER_008_withdraw_Rebalance_RevertWhen_AccountedTVLIsZero() {
    env e;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    uint256 tvlBefore = getTVL();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 vaultBalanceBefore = asset.balanceOf(getVault());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require mockUsesBufferedAssets(), "adapter supports buffered assets";
    require bufferedAssetsBefore == 0, "adapter has no buffered assets";

    /// @dev The protocol withdrawal is skipped, so its configured output and failure flag are irrelevant.
    /// @dev revert condition being verified
    require tvlBefore == 0, "adapter has no accounted assets";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_BufferedAssets_StoreCount == 0, "buffered assets store count starts at zero";

    withdraw@withrevert(e, max_uint256);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert getTVL() == tvlBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getVault()) == vaultBalanceBefore;
    assert ghost_Withdraw_EventCount == 0;
    assert ghost_BufferedAssets_StoreCount == 0;
}
