/// Verification of WorkflowRouter
/// @author @contractlevel
/// @notice WorkflowRouter routes CRE reports to the vault

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // WorkflowRouter methods
    function hasRole(bytes32, address) external returns (bool) envfree;
    function getAllowlistedWorkflowSelector(bytes32, bytes4) external returns (bool) envfree;
    function getWorkflowMetadata(bytes32) external returns (WorkflowRouter.WorkflowMetadata) envfree;

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToBytes4(bytes32) external returns (bytes4) envfree;
    function bytes32ToBytes10(bytes32) external returns (bytes10) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;

    // Roles
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
    function PAUSER_ROLE() external returns (bytes32) envfree;
    function UNPAUSER_ROLE() external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition WorkflowMetadataSetEvent() returns bytes32 =
// keccak256("WorkflowMetadataSet(bytes32,bytes10,address)")
    to_bytes32(0x796520145e48b02fa6d6c26c3902ad5fdca6c8575c0655b51dbee22fd4f2341b);

definition WorkflowSelectorSetEvent() returns bytes32 =
// keccak256("WorkflowSelectorSet(bytes32,bytes4,bool)")
    to_bytes32(0x8377fb99088630670fd820e6de1630e7c262566b468a553f53dcff95e3454150);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount WorkflowMetadataSet event is emitted
ghost mathint ghost_WorkflowMetadataSet_EventCount {
    init_state axiom ghost_WorkflowMetadataSet_EventCount == 0;
}

/// @notice EmittedValue: track workflowId param emitted in WorkflowMetadataSet event
ghost bytes32 ghost_WorkflowMetadataSet_EventParam_workflowId {
    init_state axiom ghost_WorkflowMetadataSet_EventParam_workflowId == to_bytes32(0);
}

/// @notice EmittedValue: track name param emitted in WorkflowMetadataSet event
ghost bytes10 ghost_WorkflowMetadataSet_EventParam_name {
    init_state axiom ghost_WorkflowMetadataSet_EventParam_name == to_bytes10(0);
}

/// @notice EmittedValue: track owner param emitted in WorkflowMetadataSet event
ghost address ghost_WorkflowMetadataSet_EventParam_owner {
    init_state axiom ghost_WorkflowMetadataSet_EventParam_owner == 0;
}

/// @notice EventCount: track amount WorkflowSelectorSet event is emitted
ghost mathint ghost_WorkflowSelectorSet_EventCount {
    init_state axiom ghost_WorkflowSelectorSet_EventCount == 0;
}

/// @notice EmittedValue: track workflowId param emitted in WorkflowSelectorSet event
ghost bytes32 ghost_WorkflowSelectorSet_EventParam_workflowId {
    init_state axiom ghost_WorkflowSelectorSet_EventParam_workflowId == to_bytes32(0);
}

/// @notice EmittedValue: track selector param emitted in WorkflowSelectorSet event
ghost bytes4 ghost_WorkflowSelectorSet_EventParam_selector {
    init_state axiom ghost_WorkflowSelectorSet_EventParam_selector == to_bytes4(0);
}

/// @notice EmittedValue: track isAllowlisted param emitted in WorkflowSelectorSet event
ghost bool ghost_WorkflowSelectorSet_EventParam_isAllowlisted {
    init_state axiom ghost_WorkflowSelectorSet_EventParam_isAllowlisted == false;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == WorkflowMetadataSetEvent()) {
        ghost_WorkflowMetadataSet_EventCount = ghost_WorkflowMetadataSet_EventCount + 1;
        ghost_WorkflowMetadataSet_EventParam_workflowId = t1;
        ghost_WorkflowMetadataSet_EventParam_name = bytes32ToBytes10(t2);
        ghost_WorkflowMetadataSet_EventParam_owner = bytes32ToAddress(t3);
    }

    if (t0 == WorkflowSelectorSetEvent()) {
        ghost_WorkflowSelectorSet_EventCount = ghost_WorkflowSelectorSet_EventCount + 1;
        ghost_WorkflowSelectorSet_EventParam_workflowId = t1;
        ghost_WorkflowSelectorSet_EventParam_selector = bytes32ToBytes4(t2);
        ghost_WorkflowSelectorSet_EventParam_isAllowlisted = bytes32ToBool(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule setWorkflowSelectors_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowed;
    bytes4 s1;
    bytes4 s2;
    bytes4 s3;
    selectors = [s1, s2, s3];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require workflowId != to_bytes32(0), "workflowId should not be zero";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowed);
    assert lastReverted;
}

rule setWorkflowSelectors_RevertWhen_ZeroWorkflowId() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowlisted;
    bytes4 s1;
    bytes4 s2;
    bytes4 s3;
    selectors = [s1, s2, s3];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";

    /// @dev revert condition being verified
    require workflowId == to_bytes32(0), "zero workflowId";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert lastReverted;
}

rule setWorkflowSelectors_Success() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowlisted;
    bytes4 s1;
    selectors = [s1];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "zero workflowId";

    /// @dev ghost starting values
    require ghost_WorkflowSelectorSet_EventCount == 0, "event count starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_workflowId == to_bytes32(0), "ghost param starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_selector == to_bytes4(0), "ghost param starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_isAllowlisted == false, "ghost param starts at false";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert !lastReverted;
    assert ghost_WorkflowSelectorSet_EventCount == 1;
    assert ghost_WorkflowSelectorSet_EventParam_workflowId == workflowId;
    assert ghost_WorkflowSelectorSet_EventParam_selector == s1;
    assert ghost_WorkflowSelectorSet_EventParam_isAllowlisted == isAllowlisted;
    assert getAllowlistedWorkflowSelector(workflowId, s1) == isAllowlisted;
}

rule pause_RevertWhen_CallerDoesNotHavePAUSER_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";

    /// @dev revert condition being verified
    require !hasRole(PAUSER_ROLE(), e.msg.sender), "only PAUSER_ROLE can call";

    pause@withrevert(e);
    assert lastReverted;
}

rule pause_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(PAUSER_ROLE(), e.msg.sender), "only PAUSER_ROLE can call";

    pause@withrevert(e);
    assert !lastReverted;
    assert currentContract._paused;
}

rule unpause_RevertWhen_CallerDoesNotHaveUNPAUSER_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require currentContract._paused, "should be paused";

    /// @dev revert condition being verified
    require !hasRole(UNPAUSER_ROLE(), e.msg.sender), "only UNPAUSER_ROLE can call";

    unpause@withrevert(e);
    assert lastReverted;
}

rule unpause_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require currentContract._paused, "should not be paused";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender), "only UNPAUSER_ROLE can call";

    unpause@withrevert(e);
    assert !lastReverted;
    assert !currentContract._paused;
}

rule setWorkflowMetadata_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require workflowId != to_bytes32(0), "no zero value";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "no mismatched zero metadata";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
}

rule setWorkflowMetadata_RevertWhen_ZeroWorkflowId() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "no mismatched zero metadata";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";

    /// @dev revert condition being verified
    require workflowId == to_bytes32(0), "no zero value";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
}

rule setWorkflowMetadata_RevertWhen_MismatchedZeroMetadata() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "no zero value";

    /// @dev revert condition being verified
    require name != to_bytes10(0) && owner == 0 || name != to_bytes10(0) && owner == 0, "mismatched zero metadata";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
}

rule setWorkflowMetadata_Success() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "no zero value";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "mismatched zero metadata";

    /// @dev ghost starting values
    require ghost_WorkflowMetadataSet_EventCount == 0, "WorkflowMetadataSet event count starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_workflowId == to_bytes32(0), "WorkflowMetadataSet workflowId ghost starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_name == to_bytes10(0), "WorkflowMetadataSet name ghost starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_owner == 0, "WorkflowMetadataSet owner ghost starts at zero";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert !lastReverted;
    assert ghost_WorkflowMetadataSet_EventCount == 1;
    assert ghost_WorkflowMetadataSet_EventParam_workflowId == workflowId;
    assert ghost_WorkflowMetadataSet_EventParam_name == name;
    assert ghost_WorkflowMetadataSet_EventParam_owner == owner;
    WorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    assert metadata.owner == owner;
    assert metadata.name == name;
}
