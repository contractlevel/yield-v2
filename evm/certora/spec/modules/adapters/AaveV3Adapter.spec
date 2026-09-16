using MockAaveV3PoolAddressesProvider as poolAddressesProvider;
using MockAaveV3Pool as pool;
using MockAToken as aToken;
using MockUSDC as asset;

/// Verification of AaveV3Adapter protocol-specific behavior
/// @author @contractlevel

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getTVL() external returns (uint256) envfree;
    function getProtocolPool() external returns (address) envfree;
    function getPoolAddressesProvider() external returns (address) envfree;
    function getAsset() external returns (address) envfree;
    function getVault() external returns (address) envfree;
    function getBufferedAssets() external returns (uint256) envfree;

    function poolAddressesProvider.getPool() external returns (address) envfree;
    function pool.getReserveData(address) external returns (DataTypes.ReserveDataLegacy memory) envfree;
    function pool.s_reserveNormalizedIncome() external returns (uint256) envfree;
    function pool.s_normalizedIncomeReverts() external returns (bool) envfree;
    function pool.s_supplyReverts() external returns (bool) envfree;
    function pool.s_decreaseTVLOnSupply() external returns (bool) envfree;
    function pool.s_supplyTVLChange() external returns (uint256) envfree;
    function pool.s_supplyCalled() external returns (bool) envfree;
    function pool.s_supplyCaller() external returns (address) envfree;
    function pool.s_supplyAsset() external returns (address) envfree;
    function pool.s_supplyAmount() external returns (uint256) envfree;
    function pool.s_supplyOnBehalfOf() external returns (address) envfree;
    function pool.s_supplyReferralCode() external returns (uint16) envfree;
    function aToken.balanceOf(address) external returns (uint256) envfree;
    function asset.balanceOf(address) external returns (uint256) envfree;
    function asset.allowance(address, address) external returns (uint256) envfree;

    // Wildcard dispatcher summaries
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition RayPrecision() returns mathint = 1000000000000000000000000000;

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule getProtocolPool_EqualsProviderPool() {
    assert getProtocolPool() == poolAddressesProvider.getPool();
}

rule CFG_001_getPoolAddressesProvider_ReturnsConfiguredProvider() {
    assert getPoolAddressesProvider() == poolAddressesProvider;
}

rule ADAPTER_006_assetHasListedReserve() {
    assert pool.getReserveData(getAsset()).aTokenAddress != 0;
}

rule getTVL_EqualsATokenBalancePlusBufferedAssets() {
    uint256 protocolTVL = aToken.balanceOf(currentContract);
    uint256 bufferedAssets = getBufferedAssets();

    /// @dev revert conditions NOT being verified
    require protocolTVL <= max_uint256 - bufferedAssets, "total TVL should not overflow";

    assert getTVL() == protocolTVL + bufferedAssets;
}

/// @dev The mathematical floor check includes amounts that half-up rounding would represent.
rule ADAPTER_007_deposit_BuffersWhenScaledUnitsRoundDownToZero() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 index = pool.s_reserveNormalizedIncome();
    uint256 protocolTVLBefore = aToken.balanceOf(currentContract);
    uint256 creditedAmount = pool.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require index != 0, "normalized income subtraction should not underflow";
    require !pool.s_supplyReverts(), "protocol supply should not revert";
    require !pool.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require amountToSupply <= 50, "combined buffered assets are within the limit";
    require !pool.s_normalizedIncomeReverts(), "normalized income read should not revert";

    /// @dev conditions being verified
    require amountToSupply * RayPrecision() < index, "scaled units round down to zero";

    /// @dev conditions for tracking protocol calls
    require !pool.s_supplyCalled(), "protocol supply has not been called";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getBufferedAssets() == amountToSupply;
    assert aToken.balanceOf(currentContract) == protocolTVLBefore;
    assert getTVL() == protocolTVLBefore + amountToSupply;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert !pool.s_supplyCalled();
}

/// @dev Equality at combined assets * RAY == index is representable and must supply.
rule ADAPTER_007_deposit_SuppliesWhenScaledUnitsAreRepresentable() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 index = pool.s_reserveNormalizedIncome();
    uint256 protocolTVLBefore = aToken.balanceOf(currentContract);
    uint256 creditedAmount = pool.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require index != 0, "normalized income subtraction should not underflow";
    require !pool.s_supplyReverts(), "protocol supply should not revert";
    require !pool.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require !pool.s_normalizedIncomeReverts(), "normalized income read should not revert";

    /// @dev conditions being verified
    require amountToSupply * RayPrecision() >= index, "scaled units are representable";

    /// @dev conditions for tracking protocol calls
    require !pool.s_supplyCalled(), "protocol supply has not been called";

    deposit@withrevert(e, amount);

    assert !lastReverted;
    assert getBufferedAssets() == 0;
    assert aToken.balanceOf(currentContract) == protocolTVLBefore + creditedAmount;
    assert getTVL() == protocolTVLBefore + creditedAmount;
    assert asset.allowance(currentContract, getProtocolPool()) == amountToSupply;
    assert pool.s_supplyCalled();
    assert pool.s_supplyCaller() == currentContract;
    assert pool.s_supplyAsset() == getAsset();
    assert pool.s_supplyAmount() == amountToSupply;
    assert pool.s_supplyOnBehalfOf() == currentContract;
    assert pool.s_supplyReferralCode() == 0;
}

/// @dev A failed index read must revert before supplying, approving, or changing the buffer.
rule ADAPTER_007_deposit_RevertWhen_NormalizedIncomeReadFails() {
    env e;
    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 index = pool.s_reserveNormalizedIncome();
    uint256 protocolTVLBefore = aToken.balanceOf(currentContract);
    uint256 creditedAmount = pool.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require e.msg.sender == getVault(), "caller is vault";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require index != 0, "normalized income subtraction should not underflow";
    require !pool.s_supplyReverts(), "protocol supply should not revert";
    require !pool.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require asset.balanceOf(getProtocolPool()) <= max_uint256 - amountToSupply,
        "protocol can receive combined deposited asset";
    require amountToSupply <= 50, "combined buffered assets are within the limit";

    /// @dev revert condition being verified
    require pool.s_normalizedIncomeReverts(), "normalized income read should revert";

    /// @dev conditions for tracking protocol calls
    require !pool.s_supplyCalled(), "protocol supply has not been called";

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert aToken.balanceOf(currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert !pool.s_supplyCalled();
}
