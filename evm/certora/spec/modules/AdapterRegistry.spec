/// Verification of AdapterRegistry
/// @author @contractlevel
/// @notice AdapterRegistry stores the adapters for each protocol on a given chain

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // AdapterRegistry methods
    function setAdapter(bytes32 protocolId, address adapter) external;
    function hasRole(bytes32, address) external returns (bool) envfree;
    function getAdapter(bytes32 protocolId) external returns (address) envfree;

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;

    // Roles
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition AdapterSetEvent() returns bytes32 =
// keccak256("AdapterSet(bytes32,address)")
    to_bytes32(0x3b47bb87ba19aff1d2e33a9a2a80833153f71de08be9168be2e127c4f2b52586);


/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount AdapterSet event is emitted
ghost mathint ghost_AdapterSet_EventCount {
    init_state axiom ghost_AdapterSet_EventCount == 0;
}

/// @notice EmittedValue: track protocolId param emitted in AdapterSet event
ghost bytes32 ghost_AdapterSet_EventParam_protocolId {
    init_state axiom ghost_AdapterSet_EventParam_protocolId == to_bytes32(0);
}

/// @notice EmittedValue: track adapter emitted in AdapterSet event
ghost address ghost_AdapterSet_EventParam_adapter {
    init_state axiom ghost_AdapterSet_EventParam_adapter == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == AdapterSetEvent()) {
        ghost_AdapterSet_EventCount = ghost_AdapterSet_EventCount + 1;
        ghost_AdapterSet_EventParam_protocolId = t1;
        ghost_AdapterSet_EventParam_adapter = bytes32ToAddress(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule ADAPTER_001_setAdapter_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require protocolId != to_bytes32(0), "exclude zero protocolId revert";

    /// @dev revert condition being verified
    require !currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller lacks CONFIG_OPERATOR_ROLE";

    /// @dev ghost starting values
    require ghost_AdapterSet_EventCount == 0, "AdapterSet event count starts at zero";

    setAdapter@withrevert(e, protocolId, adapter);
    assert lastReverted;
    assert ghost_AdapterSet_EventCount == 0;
}

rule ADAPTER_001_setAdapter_RevertWhen_ProtocolIdIsZero() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";

    /// @dev revert condition being verified
    require protocolId == to_bytes32(0), "protocolId is zero";

    /// @dev ghost starting values
    require ghost_AdapterSet_EventCount == 0, "AdapterSet event count starts at zero";

    setAdapter@withrevert(e, protocolId, adapter);
    assert lastReverted;
    assert ghost_AdapterSet_EventCount == 0;
}

rule ADAPTER_001_setAdapter_Success() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require protocolId != to_bytes32(0), "protocolId is nonzero";

    /// @dev ghost starting values
    require ghost_AdapterSet_EventCount == 0, "AdapterSet event count starts at zero";
    require ghost_AdapterSet_EventParam_protocolId == to_bytes32(0), "AdapterSet protocolId ghost starts at zero";
    require ghost_AdapterSet_EventParam_adapter == 0, "AdapterSet adapter ghost starts at zero";

    setAdapter@withrevert(e, protocolId, adapter);

    assert !lastReverted;
    assert ghost_AdapterSet_EventCount == 1;
    assert ghost_AdapterSet_EventParam_protocolId == protocolId;
    assert ghost_AdapterSet_EventParam_adapter == adapter;
    assert getAdapter(protocolId) == adapter;
}

rule ADAPTER_001_ADAPTER_003_setAdapter_Success_WhenAdapterIsZeroAddress_RemovesAdapter() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require protocolId != to_bytes32(0), "protocolId is nonzero";

    /// @dev condition being verified
    require getAdapter(protocolId) != 0, "initial adapter is nonzero";

    /// @dev ghost starting values
    require ghost_AdapterSet_EventCount == 0, "AdapterSet event count starts at zero";
    require ghost_AdapterSet_EventParam_protocolId == to_bytes32(0), "AdapterSet protocolId ghost starts at zero";
    require ghost_AdapterSet_EventParam_adapter == 0, "AdapterSet adapter ghost starts at zero";

    setAdapter@withrevert(e, protocolId, 0);
    assert !lastReverted;
    assert ghost_AdapterSet_EventCount == 1;
    assert ghost_AdapterSet_EventParam_protocolId == protocolId;
    assert ghost_AdapterSet_EventParam_adapter == 0;
    assert getAdapter(protocolId) == 0;
}

rule ADAPTER_001_ADAPTER_003_setAdapter_Success_OverwritesPreviousAdapter() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require protocolId != to_bytes32(0), "protocolId is nonzero";

    /// @dev condition being verified
    require getAdapter(protocolId) != adapter, "new adapter differs from current adapter";

    setAdapter@withrevert(e, protocolId, adapter);
    assert !lastReverted;
    assert getAdapter(protocolId) == adapter;
}

rule ADAPTER_001_setAdapter_Success_DoesNotAffectOtherProtocolId() {
    env e;
    bytes32 protocolId;
    bytes32 otherProtocolId;
    address adapter;
    address previousOtherAdapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setAdapter is nonpayable";
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require protocolId != to_bytes32(0), "protocolId is nonzero";
    require otherProtocolId != to_bytes32(0), "other protocolId is nonzero";

    /// @dev condition being verified
    require protocolId != otherProtocolId, "protocolIds are distinct";

    previousOtherAdapter = getAdapter(otherProtocolId);

    setAdapter@withrevert(e, protocolId, adapter);

    assert !lastReverted;
    assert getAdapter(protocolId) == adapter;
    assert getAdapter(otherProtocolId) == previousOtherAdapter;
}
