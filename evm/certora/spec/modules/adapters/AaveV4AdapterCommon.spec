using MockAaveV4Hub as hub;
using MockAaveV4Asset as asset;
using MockAaveV4Vault as vault;

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
    function getVault() external returns (address) envfree;
    function getBufferedAssets() external returns (uint256) envfree;
    function getHub() external returns (address) envfree;
    function getHubAssetId() external returns (uint256) envfree;
    function invalidSharesSelector() external returns (bytes4) envfree;
    function isExactRevert(bytes, bytes4) external returns (bool) envfree;
    function bufferedAssetsLimitExceededSelector() external returns (bytes4) envfree;
    function buildRevertReason(bytes4, bytes) external returns (bytes) envfree;
    function buildShortRevertReason(bytes3, uint8) external returns (bytes) envfree;
    function hashBytes(bytes) external returns (bytes32) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function hub.s_minimumAddAmount(uint256) external returns (uint256) envfree;
    function hub.s_previewReverts() external returns (bool) envfree;
    function asset.balanceOf(address) external returns (uint256) envfree;
    function asset.allowance(address, address) external returns (uint256) envfree;
    function asset.s_approveZeroReverts() external returns (bool) envfree;

    // Wildcard dispatcher summaries
    function _.getAsset() external => DISPATCHER(true);
    function _.getReserveCount() external => DISPATCHER(true);
    function _.getReserve(uint256) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.deposit(uint256) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                              GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_Deposit_EventCount {
    init_state axiom ghost_Deposit_EventCount == 0;
}
ghost mathint ghost_Deposit_EventParam_amount {
    init_state axiom ghost_Deposit_EventParam_amount == 0;
}
ghost mathint ghost_DepositBuffered_EventCount {
    init_state axiom ghost_DepositBuffered_EventCount == 0;
}
ghost mathint ghost_DepositBuffered_EventParam_amount {
    init_state axiom ghost_DepositBuffered_EventParam_amount == 0;
}
ghost mathint ghost_DepositBuffered_EventParam_totalBufferedAssets {
    init_state axiom ghost_DepositBuffered_EventParam_totalBufferedAssets == 0;
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == to_bytes32(0x4d6ce1e535dbade1c23defba91e23b8f791ce5edc0cc320257a2b364e4e38426)) {
        ghost_Deposit_EventCount = ghost_Deposit_EventCount + 1;
        ghost_Deposit_EventParam_amount = bytes32ToUint256(t1);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == to_bytes32(0x9f8115ab397b99ef916b2f9345b529fe9caf2b784fe2aba7fa6f01f815deaa2a)) {
        ghost_DepositBuffered_EventCount = ghost_DepositBuffered_EventCount + 1;
        ghost_DepositBuffered_EventParam_amount = bytes32ToUint256(t1);
        ghost_DepositBuffered_EventParam_totalBufferedAssets = bytes32ToUint256(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             INVARIANTS
//////////////////////////////////////////////////////////////*/
invariant ADAPTER_006_hubConfigurationMatchesAssetReserve()
    getHub() == aaveV4Spoke.getReserve(getReserveId()).hub
    && getHubAssetId() == aaveV4Spoke.getReserve(getReserveId()).assetId;

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule CFG_001_getProtocolPool_EqualsSpoke() {
    assert getProtocolPool() == aaveV4Spoke;
}

rule ADAPTER_006_getReserveId_ResolvesAssetReserve() {
    uint256 reserveId = getReserveId();

    assert aaveV4Spoke.getReserve(reserveId).underlying == getAsset();
}

rule getTVL_EqualsSpokeSuppliedAssetsPlusBufferedAssets() {
    uint256 protocolTVL = aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract);
    uint256 bufferedAssets = getBufferedAssets();

    /// @dev revert conditions NOT being verified
    require protocolTVL <= max_uint256 - bufferedAssets, "total TVL should not overflow";

    assert getTVL() == protocolTVL + bufferedAssets;
}

rule ADAPTER_007_deposit_BuffersWhenPreviewIsZero() {
    env e;
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
    require aaveV4Spoke.s_supplyReverts() == false, "protocol supply failure matches the execution path";
    require amountToSupply < hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";

    /// @dev conditions for tracking protocol calls and events
    require !aaveV4Spoke.s_supplyCalled(), "protocol supply has not been called";
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    bool reverted;
    bytes actualReason;
    // The vault forwards the call so the adapter's onlyVault guard uses the actual vault.
    (reverted, actualReason) = vault.depositAndGetRevertData(e, currentContract, amount);

    assert !reverted;
    assert getTVL() == protocolTVLBefore + amountToSupply;
    assert currentContract._status == 1;
    assert getBufferedAssets() == amountToSupply;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == allowanceBefore;
    assert aaveV4Spoke.s_supplyCalled() == false;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_DepositBuffered_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventParam_totalBufferedAssets == amountToSupply;
}

rule ADAPTER_007_deposit_SuppliesWhenPreviewIsPositive() {
    env e;
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
    require !hub.s_previewReverts(), "Hub preview should not revert";
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == false, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";

    /// @dev conditions for tracking protocol calls and events
    require !aaveV4Spoke.s_supplyCalled(), "protocol supply has not been called";
    require ghost_Deposit_EventCount == 0, "Deposit event count starts at zero";
    require ghost_DepositBuffered_EventCount == 0, "DepositBuffered event count starts at zero";

    bool reverted;
    bytes actualReason;
    // The vault forwards the call so the adapter's onlyVault guard uses the actual vault.
    (reverted, actualReason) = vault.depositAndGetRevertData(e, currentContract, amount);

    assert !reverted;
    assert getTVL() == protocolTVLBefore + creditedAmount;
    assert currentContract._status == 1;
    assert getBufferedAssets() == 0;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore + creditedAmount;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore - amountToSupply;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore + amountToSupply;
    assert asset.allowance(currentContract, getProtocolPool()) == (amountToSupply == max_uint256 ? max_uint256 : 0);
    assert aaveV4Spoke.s_supplyCalled() == true;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_DepositBuffered_EventCount == 0;
    assert ghost_Deposit_EventParam_amount == amount;
    assert aaveV4Spoke.s_supplyCaller() == currentContract;
    assert aaveV4Spoke.s_supplyReserveId() == getReserveId();
    assert aaveV4Spoke.s_supplyAmount() == amountToSupply;
    assert aaveV4Spoke.s_supplyOnBehalfOf() == currentContract;
}

rule ADAPTER_007_deposit_BuffersWhenSupplyReturnsExactInvalidShares() {
    env e;

    /// @dev Configure the mock before taking snapshots or assuming its state.
    bytes empty;
    require empty.length == 0, "error has no trailing data";
    bytes expectedReason = buildRevertReason(invalidSharesSelector(), empty);

    aaveV4Spoke.setSupplyRevertReason(e, expectedReason);

    require hashBytes(aaveV4Spoke.s_supplyRevertReason()) == hashBytes(expectedReason),
        "mock supply has the configured revert data";

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
    require protocolTVLBefore <= max_uint256 - bufferedAssetsBefore,
        "protocol TVL plus existing buffered assets should not overflow";
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

    assert !reverted;
    assert getTVL() == protocolTVLBefore + amountToSupply;
    assert currentContract._status == 1;
    assert getBufferedAssets() == amountToSupply;
    assert aaveV4Spoke.getUserSuppliedAssets(getReserveId(), currentContract) == protocolTVLBefore;
    assert asset.balanceOf(currentContract) == adapterBalanceBefore;
    assert asset.balanceOf(getProtocolPool()) == poolBalanceBefore;
    assert asset.allowance(currentContract, getProtocolPool()) == 0;
    assert aaveV4Spoke.s_supplyCalled() == false;
    assert ghost_Deposit_EventCount == 1;
    assert ghost_DepositBuffered_EventCount == 1;
    assert ghost_Deposit_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventParam_amount == amount;
    assert ghost_DepositBuffered_EventParam_totalBufferedAssets == amountToSupply;
}

rule ADAPTER_007_deposit_RevertWhen_InvalidSharesBufferExceedsLimit() {
    env e;

    /// @dev Configure the mock before taking snapshots or assuming its state.
    bytes empty;
    require empty.length == 0, "error has no trailing data";
    bytes expectedReason = buildRevertReason(invalidSharesSelector(), empty);

    aaveV4Spoke.setSupplyRevertReason(e, expectedReason);

    require hashBytes(aaveV4Spoke.s_supplyRevertReason()) == hashBytes(expectedReason),
        "mock supply has the configured revert data";

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
    require !hub.s_previewReverts(), "Hub preview should not revert";
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == true, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";
    require amountToSupply > 50, "InvalidShares fallback exceeds the buffer limit";

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
    assert hashBytes(actualReason) == hashBytes(buildRevertReason(bufferedAssetsLimitExceededSelector(), empty));
}

rule ADAPTER_007_deposit_RevertWhen_InvalidSharesAllowanceClearFails() {
    env e;

    /// @dev Configure the mock before taking snapshots or assuming its state.
    bytes empty;
    require empty.length == 0, "error has no trailing data";
    bytes expectedReason = buildRevertReason(invalidSharesSelector(), empty);

    aaveV4Spoke.setSupplyRevertReason(e, expectedReason);

    require hashBytes(aaveV4Spoke.s_supplyRevertReason()) == hashBytes(expectedReason),
        "mock supply has the configured revert data";

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

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == true, "protocol supply failure matches the execution path";
    require amountToSupply >= hub.s_minimumAddAmount(getHubAssetId()), "preview matches the execution path";
    require asset.s_approveZeroReverts(), "clearing allowance should revert";

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
    assert hashBytes(actualReason) == hashBytes(empty);
}




rule ADAPTER_007_deposit_RevertWhen_HubPreviewFails() {
    env e;
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
    require !asset.s_approveZeroReverts(), "clearing allowance should not revert";

    requireInvariant ADAPTER_006_hubConfigurationMatchesAssetReserve();

    /// @dev conditions being verified
    require aaveV4Spoke.s_supplyReverts() == false, "protocol supply failure matches the execution path";
    require hub.s_previewReverts(), "Hub preview should revert";

    bytes empty;
    require empty.length == 0, "preview error has no revert data";

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
    assert hashBytes(actualReason) == hashBytes(empty);
}
