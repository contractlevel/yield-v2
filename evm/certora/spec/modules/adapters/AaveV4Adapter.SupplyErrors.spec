import "AaveV4AdapterCommon.spec";

using MockAaveV4SupplyErrorSpoke as aaveV4Spoke;

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

// Arbitrary payload matching is verified independently of the fixed branch fixtures.
// Exact byte preservation is covered by the deposit Foundry fuzz tests.
rule ADAPTER_007_revertMatcher_RejectsNonSelectorLength() {
    bytes reason;
    bytes4 selector;
    require reason.length != 4, "payload is not exactly a selector";

    assert !isExactRevert(reason, selector);
}

rule ADAPTER_007_revertMatcher_AcceptsExactSelector() {
    bytes4 selector;
    bytes empty;
    require empty.length == 0, "payload has no trailing data";

    assert isExactRevert(buildRevertReason(selector, empty), selector);
}

rule ADAPTER_007_revertMatcher_RejectsDifferentSelector() {
    bytes4 actualSelector;
    bytes4 expectedSelector;
    bytes empty;
    require empty.length == 0, "payload has no trailing data";
    require actualSelector != expectedSelector, "selectors differ";

    assert !isExactRevert(buildRevertReason(actualSelector, empty), expectedSelector);
}


rule ADAPTER_007_deposit_RevertWhen_SupplyReturnsOtherError() {
    env e;

    /// @dev Use a fixed payload to verify this adapter branch.
    aaveV4Spoke.setSupplyError(e, 0, to_bytes3(0), 0);

    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 protocolTVLBefore = aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract);
    uint256 creditedAmount = aaveV4Spoke.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 poolBalanceBefore = asset.balanceOf(getProtocolPool());
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !aaveV4Spoke.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require poolBalanceBefore <= max_uint256 - amountToSupply, "protocol can receive combined deposited asset";
    require amountToSupply <= 50, "combined buffered assets are within the limit";
    require !hub.s_previewReverts(), "Hub preview should not revert";
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == true, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";

    /// @dev conditions for tracking protocol calls and events
    require !aaveV4Spoke.s_supplyCalled(), "protocol supply has not been called";
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    bool reverted;
    bytes actualReason;
    // The vault forwards the call so the adapter's onlyVault guard uses the actual vault.
    (reverted, actualReason) = vault.depositAndGetRevertData(e, currentContract, amount);

    assert reverted;
    assert currentContract._status == 1;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert aaveV4Spoke.s_supplyCalled() == false;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_RevertWhen_InvalidSharesHasTrailingData() {
    env e;

    /// @dev Use a fixed payload to verify this adapter branch.
    aaveV4Spoke.setSupplyError(e, 1, to_bytes3(0), 0);

    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 protocolTVLBefore = aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract);
    uint256 creditedAmount = aaveV4Spoke.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 poolBalanceBefore = asset.balanceOf(getProtocolPool());
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !aaveV4Spoke.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require poolBalanceBefore <= max_uint256 - amountToSupply, "protocol can receive combined deposited asset";
    require amountToSupply <= 50, "combined buffered assets are within the limit";
    require !hub.s_previewReverts(), "Hub preview should not revert";
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == true, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";

    /// @dev conditions for tracking protocol calls and events
    require !aaveV4Spoke.s_supplyCalled(), "protocol supply has not been called";
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    bool reverted;
    bytes actualReason;
    // The vault forwards the call so the adapter's onlyVault guard uses the actual vault.
    (reverted, actualReason) = vault.depositAndGetRevertData(e, currentContract, amount);

    assert reverted;
    assert currentContract._status == 1;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert aaveV4Spoke.s_supplyCalled() == false;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}

rule ADAPTER_007_deposit_RevertWhen_SupplyReturnsShortData() {
    env e;

    /// @dev The fixture emits any zero-to-three-byte payload from scalar fields.
    bytes3 prefix;
    uint8 length;
    require length < 4, "supply error is shorter than a selector";
    aaveV4Spoke.setSupplyError(e, 2, prefix, length);

    uint256 amount;
    uint256 bufferedAssetsBefore = getBufferedAssets();
    mathint amountToSupply = bufferedAssetsBefore + amount;
    uint256 protocolTVLBefore = aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract);
    uint256 creditedAmount = aaveV4Spoke.s_supplyTVLChange();
    uint256 adapterBalanceBefore = asset.balanceOf(currentContract);
    uint256 poolBalanceBefore = asset.balanceOf(getProtocolPool());
    uint256 allowanceBefore = asset.allowance(currentContract, getProtocolPool());

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "deposit is nonpayable";
    require currentContract._status == 1, "deposit is nonReentrant";
    require amount != 0, "deposit amount is nonzero";
    require bufferedAssetsBefore <= 50, "existing buffered assets are within the limit";
    require amountToSupply <= max_uint256, "combined deposit should not overflow";
    require !aaveV4Spoke.s_decreaseTVLOnSupply(), "protocol TVL should not decrease during deposit";
    require creditedAmount >= bufferedAssetsBefore, "flushing buffered assets should not decrease TVL";
    require creditedAmount >= amountToSupply || amountToSupply - creditedAmount <= 100,
        "combined deposit credited shortfall is within tolerance";
    require protocolTVLBefore <= max_uint256 - creditedAmount, "protocol TVL increase should not overflow";
    require protocolTVLBefore <= max_uint256 - amountToSupply, "buffered TVL increase should not overflow";
    require adapterBalanceBefore >= amountToSupply, "adapter asset balance covers combined deposit";
    require poolBalanceBefore <= max_uint256 - amountToSupply, "protocol can receive combined deposited asset";
    require amountToSupply <= 50, "combined buffered assets are within the limit";
    require !hub.s_previewReverts(), "Hub preview should not revert";
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == true, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";

    /// @dev conditions for tracking protocol calls and events
    require !aaveV4Spoke.s_supplyCalled(), "protocol supply has not been called";
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    bool reverted;
    bytes actualReason;
    // The vault forwards the call so the adapter's onlyVault guard uses the actual vault.
    (reverted, actualReason) = vault.depositAndGetRevertData(e, currentContract, amount);

    assert reverted;
    assert currentContract._status == 1;
    assert getBufferedAssets() == bufferedAssetsBefore;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert aaveV4Spoke.s_supplyCalled() == false;
    assert ghost_Deposit_EventCount == 0;
    assert ghost_DepositBuffered_EventCount == 0;
}
