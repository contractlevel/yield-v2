using MockAaveV4Spoke as aaveV4Spoke;

/// Verification of AaveV4Adapter protocol-specific behavior
/// @author @contractlevel

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getTVL() external returns (uint256) envfree;
    function getProtocolPool() external returns (address) envfree;
    function getReserveId() external returns (uint256) envfree;
    function getAsset() external returns (address) envfree;

    function aaveV4Spoke.getUserSuppliedAssets(uint256, address) external returns (uint256) envfree;
    function aaveV4Spoke.getReserve(uint256) external returns (IAaveV4Spoke.Reserve memory) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule getProtocolPool_EqualsSpoke() {
    assert getProtocolPool() == aaveV4Spoke;
}

rule getReserveId_ResolvesAssetReserve() {
    uint256 reserveId = getReserveId();

    assert aaveV4Spoke.getReserve(reserveId).underlying == getAsset();
}

rule getTVL_EqualsSpokeSuppliedAssets() {
    uint256 reserveId = getReserveId();

    assert getTVL() == aaveV4Spoke.getUserSuppliedAssets(reserveId, currentContract);
}
