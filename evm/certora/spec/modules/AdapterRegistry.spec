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
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition AdapterSetEvent() returns bytes32 =
// keccak256("AdapterSet(bytes32,address)")
    to_bytes32(0x3b47bb87ba19aff1d2e33a9a2a80833153f71de08be9168be2e127c4f2b52586);

definition CONFIG_OPERATOR_ROLE() returns bytes32 =
// keccak256("CONFIG_OPERATOR_ROLE")
    to_bytes32(0xdeed664348786a0e2cfd55d97b9b318764138f1f675f4b10304ff0c6ed42d123);

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
rule setAdapter_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0;
    require protocolId != to_bytes32(0), "";

    /// @dev revert condition being verified
    require !currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    setAdapter@withrevert(e, protocolId, adapter);
    assert lastReverted;
}

rule setAdapter_RevertWhen_ProtocolIdIsZero() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0;
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require protocolId == to_bytes32(0);

    setAdapter@withrevert(e, protocolId, adapter);
    assert lastReverted;
}

rule setAdapter_Success() {
    env e;
    bytes32 protocolId;
    address adapter;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0;
    require currentContract.hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0);

    /// @dev ghost starting values
    require ghost_AdapterSet_EventCount == 0;
    require ghost_AdapterSet_EventParam_protocolId == to_bytes32(0);
    require ghost_AdapterSet_EventParam_adapter == 0;

    setAdapter@withrevert(e, protocolId, adapter);

    assert !lastReverted;
    assert ghost_AdapterSet_EventCount == 1;
    assert ghost_AdapterSet_EventParam_protocolId == protocolId;
    assert ghost_AdapterSet_EventParam_adapter == adapter;
    assert getAdapter(protocolId) == adapter;
}