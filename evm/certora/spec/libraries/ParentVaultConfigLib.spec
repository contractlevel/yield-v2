/// Verification of ParentVaultConfigLib
/// @author @contractlevel
/// @notice ParentVaultConfigLib handles ParentVault-specific configuration state transitions.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getTreasury() external returns (address) envfree;
    function getSupportedProtocol(bytes32) external returns (bool) envfree;
    function getActiveStrategyProtocolId() external returns (bytes32) envfree;
    function getPendingStrategyProtocolId() external returns (bytes32) envfree;

    function setTreasury(address) external;
    function setSupportedProtocol(bytes32, bool) external;

    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition TreasurySetEvent() returns bytes32 =
// keccak256("TreasurySet(address)")
    to_bytes32(0x3c864541ef71378c6229510ed90f376565ee42d9c5e0904a984a9e863e6db44f);

definition SupportedProtocolSetEvent() returns bytes32 =
// keccak256("SupportedProtocolSet(bytes32,bool)")
    to_bytes32(0x56cc71f639333b7ecd9179fddeb0ecc00bcb82b3f98664a11601a28652604c48);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_treasury_StoreCount { init_state axiom ghost_treasury_StoreCount == 0; }
ghost address ghost_treasury_StoredValue { init_state axiom ghost_treasury_StoredValue == 0; }

ghost mathint ghost_supportedProtocol_StoreCount { init_state axiom ghost_supportedProtocol_StoreCount == 0; }
ghost bytes32 ghost_supportedProtocol_StoredKey {
    init_state axiom ghost_supportedProtocol_StoredKey == to_bytes32(0);
}
ghost bool ghost_supportedProtocol_StoredValue { init_state axiom ghost_supportedProtocol_StoredValue == false; }

ghost mathint ghost_TreasurySet_EventCount { init_state axiom ghost_TreasurySet_EventCount == 0; }
ghost address ghost_TreasurySet_Param_treasury { init_state axiom ghost_TreasurySet_Param_treasury == 0; }

ghost mathint ghost_SupportedProtocolSet_EventCount {
    init_state axiom ghost_SupportedProtocolSet_EventCount == 0;
}
ghost bytes32 ghost_SupportedProtocolSet_Param_protocolId {
    init_state axiom ghost_SupportedProtocolSet_Param_protocolId == to_bytes32(0);
}
ghost bool ghost_SupportedProtocolSet_Param_isSupported {
    init_state axiom ghost_SupportedProtocolSet_Param_isSupported == false;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_treasury address newValue {
    ghost_treasury_StoreCount = ghost_treasury_StoreCount + 1;
    ghost_treasury_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_supportedProtocol[KEY bytes32 protocolId] bool newValue {
    ghost_supportedProtocol_StoreCount = ghost_supportedProtocol_StoreCount + 1;
    ghost_supportedProtocol_StoredKey = protocolId;
    ghost_supportedProtocol_StoredValue = newValue;
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == TreasurySetEvent()) {
        ghost_TreasurySet_EventCount = ghost_TreasurySet_EventCount + 1;
        ghost_TreasurySet_Param_treasury = bytes32ToAddress(t1);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == SupportedProtocolSetEvent()) {
        ghost_SupportedProtocolSet_EventCount = ghost_SupportedProtocolSet_EventCount + 1;
        ghost_SupportedProtocolSet_Param_protocolId = t1;
        ghost_SupportedProtocolSet_Param_isSupported = bytes32ToBool(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────────── SET TREASURY ───────────────────────

rule setTreasury_RevertWhen_TreasuryIsZeroAddress() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    address treasury = 0;

    /// @dev ghost starting values
    require ghost_TreasurySet_EventCount == 0, "event count starts at zero";
    require ghost_treasury_StoreCount == 0, "store count starts at zero";

    setTreasury@withrevert(e, treasury);

    assert lastReverted;
    assert ghost_TreasurySet_EventCount == 0;
    assert ghost_treasury_StoreCount == 0;
}

rule setTreasury_Success() {
    env e;
    address treasury;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require treasury != 0, "treasury should not be zero";

    /// @dev ghost starting values
    require ghost_TreasurySet_EventCount == 0, "event count starts at zero";
    require ghost_treasury_StoreCount == 0, "store count starts at zero";

    setTreasury@withrevert(e, treasury);

    assert !lastReverted;
    assert getTreasury() == treasury;
    assert ghost_TreasurySet_EventCount == 1;
    assert ghost_TreasurySet_Param_treasury == treasury;
    assert ghost_treasury_StoreCount == 1;
    assert ghost_treasury_StoredValue == treasury;
}

/// ─────────────────── SET SUPPORTED PROTOCOL ─────────────────

rule setSupportedProtocol_RevertWhen_ProtocolIdIsZero() {
    env e;
    bool isSupported;
    bytes32 protocolId = to_bytes32(0);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require isSupported || protocolId != getActiveStrategyProtocolId(), "protocol is not the active strategy";
    require isSupported || protocolId != getPendingStrategyProtocolId(), "protocol is not the pending strategy";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert ghost_SupportedProtocolSet_EventCount == 0;
    assert ghost_supportedProtocol_StoreCount == 0;
}

rule setSupportedProtocol_RevertWhen_RemovingActiveProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported = false;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getPendingStrategyProtocolId(), "protocol is not the pending strategy";

    /// @dev revert condition being verified
    require protocolId == getActiveStrategyProtocolId(), "protocol is the active strategy";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert ghost_SupportedProtocolSet_EventCount == 0;
    assert ghost_supportedProtocol_StoreCount == 0;
}

rule setSupportedProtocol_RevertWhen_RemovingPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported = false;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getActiveStrategyProtocolId(), "protocol is not the active strategy";

    /// @dev revert condition being verified
    require protocolId == getPendingStrategyProtocolId(), "protocol is the pending strategy";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert ghost_SupportedProtocolSet_EventCount == 0;
    assert ghost_supportedProtocol_StoreCount == 0;
}

rule setSupportedProtocol_RevertWhen_RemovingActiveAndPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported = false;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev revert conditions being verified
    require protocolId == getActiveStrategyProtocolId(), "protocol is the active strategy";
    require protocolId == getPendingStrategyProtocolId(), "protocol is the pending strategy";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert ghost_SupportedProtocolSet_EventCount == 0;
    assert ghost_supportedProtocol_StoreCount == 0;
}

rule setSupportedProtocol_Success_WhenEnablingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported = true;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert !lastReverted;
    assert getSupportedProtocol(protocolId);
    assert ghost_SupportedProtocolSet_EventCount == 1;
    assert ghost_SupportedProtocolSet_Param_protocolId == protocolId;
    assert ghost_SupportedProtocolSet_Param_isSupported;
    assert ghost_supportedProtocol_StoreCount == 1;
    assert ghost_supportedProtocol_StoredKey == protocolId;
    assert ghost_supportedProtocol_StoredValue;
}

rule setSupportedProtocol_Success_WhenDisablingInactiveNonPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported = false;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getActiveStrategyProtocolId(), "protocol is not the active strategy";
    require protocolId != getPendingStrategyProtocolId(), "protocol is not the pending strategy";

    /// @dev ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0, "event count starts at zero";
    require ghost_supportedProtocol_StoreCount == 0, "store count starts at zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert !lastReverted;
    assert !getSupportedProtocol(protocolId);
    assert ghost_SupportedProtocolSet_EventCount == 1;
    assert ghost_SupportedProtocolSet_Param_protocolId == protocolId;
    assert !ghost_SupportedProtocolSet_Param_isSupported;
    assert ghost_supportedProtocol_StoreCount == 1;
    assert ghost_supportedProtocol_StoredKey == protocolId;
    assert !ghost_supportedProtocol_StoredValue;
}
