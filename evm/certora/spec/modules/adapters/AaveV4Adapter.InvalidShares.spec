import "AaveV4AdapterCommon.spec";

using MockAaveV4InvalidSharesSpoke as aaveV4Spoke;

methods {
    function aaveV4Spoke.getUserSuppliedAssets(uint256, address) external returns (uint256) envfree;
    function aaveV4Spoke.getReserve(uint256) external returns (IAaveV4Spoke.Reserve memory) envfree;
    function aaveV4Spoke.s_supplyReverts() external returns (bool) envfree;
    function aaveV4Spoke.s_supplyRevertReason() external returns (bytes) envfree;
    function aaveV4Spoke.s_decreaseTVLOnSupply() external returns (bool) envfree;
    function aaveV4Spoke.s_supplyTVLChange() external returns (uint256) envfree;
    function aaveV4Spoke.s_supplyCalled() external returns (bool) envfree;
    function aaveV4Spoke.s_supplyCaller() external returns (address) envfree;
    function aaveV4Spoke.s_supplyReserveId() external returns (uint256) envfree;
    function aaveV4Spoke.s_supplyAmount() external returns (uint256) envfree;
    function aaveV4Spoke.s_supplyOnBehalfOf() external returns (address) envfree;
}

use invariant ADAPTER_006_hubConfigurationMatchesAssetReserve;

use rule ADAPTER_007_deposit_BuffersWhenSupplyReturnsExactInvalidShares;
use rule ADAPTER_007_deposit_RevertWhen_InvalidSharesBufferExceedsLimit;
use rule ADAPTER_007_deposit_RevertWhen_InvalidSharesAllowanceClearFails;
