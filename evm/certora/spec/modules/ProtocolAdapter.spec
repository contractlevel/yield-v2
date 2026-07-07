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

rule ADAPTER_003_deposit_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require currentContract._status == 1, "deposit is nonReentrant";
    require getTVL() + amount <= max_uint256, "deposit does not overflow TVL";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Deposit_EventCount == 0;
}

rule deposit_Success_EmitsDepositEvent() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require getTVL() <= max_uint256 - amount, "deposit does not overflow TVL";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol asset balance can receive deposit";

    /// @dev ghost starting values
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_Deposit_EventParam_amount == 0, "Deposit amount ghost starts at zero";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
}

rule deposit_Success_IncreasesTVLByAmount() {
    env e;
    uint256 amount;
    uint256 preTVL = getTVL();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require preTVL <= max_uint256 - amount, "deposit does not overflow TVL";
    require asset.balanceOf(currentContract) >= amount, "adapter asset balance covers deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amount, "protocol asset balance can receive deposit";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getTVL() >= preTVL + amount;
}

rule ADAPTER_003_withdraw_RevertWhen_CallerIsNotVault() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require currentContract._status == 1, "withdraw is nonReentrant";

    /// @dev revert condition being verified
    require e.msg.sender != getVault(), "caller is not vault";

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


rule withdraw_Epoch_Success_ReturnsAtLeastAmountAndEmitsWithdrawEvent() {
    env e;
    uint256 amount;
    uint256 preTVL = getTVL();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount <= preTVL, "amount does not exceed TVL";
    require preTVL - amount >= 0, "should not underflow";
    uint256 adapterAssetBalanceBefore = getAsset().balanceOf(e, currentContract);
    uint256 vaultAssetBalanceBefore = getAsset().balanceOf(e, getVault());
    uint256 protocolAssetBalanceBefore = getAsset().balanceOf(e, getProtocolPool());
    require protocolAssetBalanceBefore >= amount, "protocol asset balance covers withdraw";
    require adapterAssetBalanceBefore <= max_uint256 - amount, "adapter asset balance can receive withdraw";
    require vaultAssetBalanceBefore <= max_uint256 - amount, "vault asset balance can receive withdraw";

    /// @dev epoch withdraw condition
    require amount != max_uint256, "amount is not max uint256";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";

    uint256 amountOut = withdraw@withrevert(e, amount);

    assert !lastReverted;
    assert amountOut >= amount;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
}

rule withdraw_Epoch_Success_DecreasesTVLByAmount() {
    env e;
    uint256 amount;
    uint256 preTVL = getTVL();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require amount <= preTVL, "amount does not exceed TVL";
    require preTVL - amount >= 0, "should not underflow";
    uint256 adapterAssetBalanceBefore = getAsset().balanceOf(e, currentContract);
    uint256 vaultAssetBalanceBefore = getAsset().balanceOf(e, getVault());
    uint256 protocolAssetBalanceBefore = getAsset().balanceOf(e, getProtocolPool());
    require protocolAssetBalanceBefore >= amount, "protocol asset balance covers withdraw";
    require adapterAssetBalanceBefore <= max_uint256 - amount, "adapter asset balance can receive withdraw";
    require vaultAssetBalanceBefore <= max_uint256 - amount, "vault asset balance can receive withdraw";

    /// @dev epoch withdraw condition
    require amount != max_uint256, "amount is not max uint256";

    uint256 amountOut = withdraw@withrevert(e, amount);

    assert !lastReverted;
    assert amountOut >= amount;
    assert getTVL() == preTVL - amount;
}

rule withdraw_Rebalance_Success_ReturnsAtLeastPreWithdrawTVLAndEmitsWithdrawEvent() {
    env e;
    uint256 preTVL = getTVL();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require preTVL > 0, "should not be 0";
    uint256 adapterAssetBalanceBefore = getAsset().balanceOf(e, currentContract);
    uint256 vaultAssetBalanceBefore = getAsset().balanceOf(e, getVault());
    uint256 protocolAssetBalanceBefore = getAsset().balanceOf(e, getProtocolPool());
    require protocolAssetBalanceBefore >= preTVL, "protocol asset balance covers withdraw";
    require adapterAssetBalanceBefore <= max_uint256 - preTVL, "adapter asset balance can receive withdraw";
    require vaultAssetBalanceBefore <= max_uint256 - preTVL, "vault asset balance can receive withdraw";

    /// @dev ghost starting values
    require ghost_Withdraw_EventCount == 0, "Withdraw event count starts at zero";
    require ghost_Withdraw_EventParam_amount == 0, "Withdraw amount ghost starts at zero";

    uint256 amountOut = withdraw@withrevert(e, max_uint256);

    assert !lastReverted;
    assert amountOut >= preTVL;
    assert ghost_Withdraw_EventCount == 1;
    assert ghost_Withdraw_EventParam_amount == amountOut;
}

rule withdraw_Success_IncreasesVaultBalances() {
    env e;
    uint256 preTVL = getTVL();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "withdraw is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "withdraw is nonReentrant";
    require preTVL > 0, "should not be 0";
    uint256 adapterBalanceBefore = asset.balanceOf(e, currentContract);
    uint256 protocolBalanceBefore = asset.balanceOf(e, getProtocolPool());
    require protocolBalanceBefore >= preTVL, "protocol asset balance covers withdraw";
    require adapterBalanceBefore <= max_uint256 - preTVL, "adapter asset balance can receive withdraw";

    uint256 vaultBalanceBefore = asset.balanceOf(getVault());
    require vaultBalanceBefore <= max_uint256 - preTVL, "vault asset balance can receive withdraw";

    uint256 amountOut = withdraw@withrevert(e, max_uint256);

    assert !lastReverted;

    assert asset.balanceOf(getVault()) == vaultBalanceBefore + amountOut;
}
