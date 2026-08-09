using MockAaveV3PoolAddressesProvider as poolAddressesProvider;
using MockAaveV3Pool as pool;
using MockAToken as aToken;

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

    function poolAddressesProvider.getPool() external returns (address) envfree;
    function pool.getReserveData(address) external returns (DataTypes.ReserveDataLegacy memory) envfree;
    function aToken.balanceOf(address) external returns (uint256) envfree;
}

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

rule getTVL_EqualsATokenBalance() {
    assert getTVL() == aToken.balanceOf(currentContract);
}
