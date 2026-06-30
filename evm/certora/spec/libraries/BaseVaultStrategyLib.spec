using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockInvalidProtocolAdapter as invalidAdapter;

/// Verification of BaseVaultStrategyLib
/// @author @contractlevel
/// @notice BaseVaultStrategyLib handles shared active strategy adapter state transitions for BaseVault implementations.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getActiveProtocolAdapter() external returns (address) envfree;

    // Library internal wrappers
    function setActiveAdapter(bytes32) external returns (address);
    function clearActiveAdapter() external;

    // Mock methods
    function adapterRegistry.getAdapter(bytes32) external returns (address) envfree;
    function adapter.getVault() external returns (address) envfree;
    function invalidAdapter.getVault() external returns (address) envfree;

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;

    // Dispatcher summaries
    function _.getAdapter(bytes32) external => DISPATCHER(true);
    function _.getVault() external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition ActiveProtocolAdapterSetEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterSet(bytes32,address)")
    to_bytes32(0xf3628f0443ba881ea4c9543ca1d28250e78f2e019fffe8a8e722378625dcf598);

definition ActiveProtocolAdapterClearedEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterCleared(address)")
    to_bytes32(0x965689b74a63affbd22afb2528d6f7c11a4d1d2850b0f0cc8f647992386bf04f);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice StoreCount: track writes to s_activeProtocolAdapter
ghost mathint ghost_activeProtocolAdapter_StoreCount {
    init_state axiom ghost_activeProtocolAdapter_StoreCount == 0;
}

/// @notice StoredValue: track latest value written to s_activeProtocolAdapter
ghost address ghost_activeProtocolAdapter_StoredValue {
    init_state axiom ghost_activeProtocolAdapter_StoredValue == 0;
}

/// @notice EventCount: track amount ActiveProtocolAdapterSet event is emitted
ghost mathint ghost_ActiveProtocolAdapterSet_EventCount {
    init_state axiom ghost_ActiveProtocolAdapterSet_EventCount == 0;
}

/// @notice EmittedValue: track protocolId param emitted in ActiveProtocolAdapterSet event
ghost bytes32 ghost_ActiveProtocolAdapterSet_Param_protocolId {
    init_state axiom ghost_ActiveProtocolAdapterSet_Param_protocolId == to_bytes32(0);
}

/// @notice EmittedValue: track adapter param emitted in ActiveProtocolAdapterSet event
ghost address ghost_ActiveProtocolAdapterSet_Param_adapter {
    init_state axiom ghost_ActiveProtocolAdapterSet_Param_adapter == 0;
}

/// @notice EventCount: track amount ActiveProtocolAdapterCleared event is emitted
ghost mathint ghost_ActiveProtocolAdapterCleared_EventCount {
    init_state axiom ghost_ActiveProtocolAdapterCleared_EventCount == 0;
}

/// @notice EmittedValue: track adapter param emitted in ActiveProtocolAdapterCleared event
ghost address ghost_ActiveProtocolAdapterCleared_Param_adapter {
    init_state axiom ghost_ActiveProtocolAdapterCleared_Param_adapter == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto active adapter storage writes
hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_activeProtocolAdapter address newValue {
    ghost_activeProtocolAdapter_StoreCount = ghost_activeProtocolAdapter_StoreCount + 1;
    ghost_activeProtocolAdapter_StoredValue = newValue;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == ActiveProtocolAdapterClearedEvent()) {
        ghost_ActiveProtocolAdapterCleared_EventCount = ghost_ActiveProtocolAdapterCleared_EventCount + 1;
        ghost_ActiveProtocolAdapterCleared_Param_adapter = bytes32ToAddress(t1);
    }
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == ActiveProtocolAdapterSetEvent()) {
        ghost_ActiveProtocolAdapterSet_EventCount = ghost_ActiveProtocolAdapterSet_EventCount + 1;
        ghost_ActiveProtocolAdapterSet_Param_protocolId = t1;
        ghost_ActiveProtocolAdapterSet_Param_adapter = bytes32ToAddress(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── SET ACTIVE ADAPTER ─────────────────────

/// @notice Setting the active adapter reverts when the protocol ID is not registered.
/// @dev Verifies that active adapter storage is unchanged and no ActiveProtocolAdapterSet event is emitted.
rule setActiveAdapter_RevertWhen_AdapterNotRegistered() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setActiveAdapter is nonpayable";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "adapter is not registered";

    address activeAdapterBefore = getActiveProtocolAdapter();

    /// @dev ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0, "ActiveProtocolAdapterSet event count starts at zero";
    require ghost_activeProtocolAdapter_StoreCount == 0, "active adapter store count starts at zero";

    setActiveAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert getActiveProtocolAdapter() == activeAdapterBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
}

/// @notice Setting the active adapter reverts when the registered adapter is bound to a different vault.
/// @dev Verifies that active adapter storage is unchanged and no ActiveProtocolAdapterSet event is emitted.
rule setActiveAdapter_RevertWhen_AdapterVaultIsInvalid() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setActiveAdapter is nonpayable";
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter, "adapter is registered";

    /// @dev revert condition being verified
    require invalidAdapter.getVault() != currentContract, "adapter vault is invalid";

    address activeAdapterBefore = getActiveProtocolAdapter();

    /// @dev ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0, "ActiveProtocolAdapterSet event count starts at zero";
    require ghost_activeProtocolAdapter_StoreCount == 0, "active adapter store count starts at zero";

    setActiveAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert getActiveProtocolAdapter() == activeAdapterBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
}

/// @notice Setting the active adapter succeeds when the protocol ID maps to an adapter bound to this harness.
/// @dev Verifies returned adapter, storage write, and ActiveProtocolAdapterSet event parameters.
rule setActiveAdapter_Success() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setActiveAdapter is nonpayable";

    /// @dev success conditions being verified
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "adapter is registered";
    require adapter.getVault() == currentContract, "adapter is bound to this harness";

    /// @dev ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0, "ActiveProtocolAdapterSet event count starts at zero";
    require ghost_activeProtocolAdapter_StoreCount == 0, "active adapter store count starts at zero";

    address returned = setActiveAdapter@withrevert(e, protocolId);

    assert !lastReverted;
    assert returned == adapter;
    assert getActiveProtocolAdapter() == adapter;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
}

/// ─────────────────── CLEAR ACTIVE ADAPTER ────────────────────

/// @notice Clearing the active adapter always succeeds.
/// @dev Verifies that the previous adapter is emitted and active adapter storage is cleared.
rule clearActiveAdapter_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "clearActiveAdapter is nonpayable";

    /// Clearing an already-zero active adapter is valid
    address previousAdapter = getActiveProtocolAdapter();

    /// @dev ghost starting values
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0, "ActiveProtocolAdapterCleared event count starts at zero";
    require ghost_activeProtocolAdapter_StoreCount == 0, "active adapter store count starts at zero";

    clearActiveAdapter@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == previousAdapter;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
}
