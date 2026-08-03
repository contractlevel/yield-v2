/// Verification of WorkflowRouter
/// @author @contractlevel
/// @notice WorkflowRouter routes CRE reports to the vault
/// @notice Low level i_vault.call auto havocs causing onReport success and failed call rules to fail.
///         There is no path to resolving this without changing production code. Rules for these paths have been deliberately excluded.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // WorkflowRouter methods
    function hasRole(bytes32, address) external returns (bool) envfree;
    function getAllowlistedWorkflowSelector(bytes32, bytes4) external returns (bool) envfree;
    function getWorkflowMetadata(bytes32) external returns (IWorkflowRouter.WorkflowMetadata) envfree;
    function getWorkflowGeneration(bytes32) external returns (uint256) envfree;
    function getVault() external returns (address) envfree;
    function supportsInterface(bytes4) external returns (bool) envfree;

    // Harness helper methods
    function buildMetadata(bytes32, bytes10, address) external returns (bytes) envfree;
    function buildShortMetadata(bytes32, bytes10, address) external returns (bytes) envfree;
    function buildLongMetadata(bytes32, bytes10, address) external returns (bytes) envfree;
    function buildReport(bytes4) external returns (bytes) envfree;
    function buildShortReport(bytes3) external returns (bytes) envfree;
    function certoraVaultCallSucceedsSelector() external returns (bytes4) envfree;
    function getWorkflowSelectorAtGeneration(bytes32, uint256, bytes4) external returns (bool) envfree;
    function getWorkflowSelectorAtNextGeneration(bytes32, bytes4) external returns (bool) envfree;
    function receiverInterfaceId() external returns (bytes4) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToBytes4(bytes32) external returns (bytes4) envfree;
    function bytes32ToBytes10(bytes32) external returns (bytes10) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;

    // Roles
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
    function KEYSTONE_FORWARDER_ROLE() external returns (bytes32) envfree;
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

definition PausedEvent() returns bytes32 =
// keccak256("Paused(address)")
    to_bytes32(0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258);

definition UnpausedEvent() returns bytes32 =
// keccak256("Unpaused(address)")
    to_bytes32(0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa);

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

/// @notice StoreCount: track stores to s_workflowMetadata owner field
ghost mathint ghost_WorkflowMetadata_Owner_StoreCount {
    init_state axiom ghost_WorkflowMetadata_Owner_StoreCount == 0;
}

/// @notice StoreCount: track stores to s_workflowMetadata name field
ghost mathint ghost_WorkflowMetadata_Name_StoreCount {
    init_state axiom ghost_WorkflowMetadata_Name_StoreCount == 0;
}

/// @notice StoredValue: track last workflowId stored in s_workflowMetadata
ghost bytes32 ghost_WorkflowMetadata_Stored_WorkflowId {
    init_state axiom ghost_WorkflowMetadata_Stored_WorkflowId == to_bytes32(0);
}

/// @notice StoredValue: track last owner stored in s_workflowMetadata
ghost address ghost_WorkflowMetadata_Stored_Owner {
    init_state axiom ghost_WorkflowMetadata_Stored_Owner == 0;
}

/// @notice StoredValue: track last name stored in s_workflowMetadata
ghost bytes10 ghost_WorkflowMetadata_Stored_Name {
    init_state axiom ghost_WorkflowMetadata_Stored_Name == to_bytes10(0);
}

/// @notice StoreCount: track stores to s_workflowSelectors
ghost mathint ghost_WorkflowSelector_Store_Count {
    init_state axiom ghost_WorkflowSelector_Store_Count == 0;
}

/// @notice StoredValue: track last workflowId stored in s_workflowSelectors
ghost bytes32 ghost_WorkflowSelector_Stored_WorkflowId {
    init_state axiom ghost_WorkflowSelector_Stored_WorkflowId == to_bytes32(0);
}

/// @notice StoredValue: track last selector stored in s_workflowSelectors
ghost bytes4 ghost_WorkflowSelector_Stored_Selector {
    init_state axiom ghost_WorkflowSelector_Stored_Selector == to_bytes4(0);
}

/// @notice StoredValue: track generation stored in s_workflowSelectors
ghost uint256 ghost_WorkflowSelector_Stored_Generation {
    init_state axiom ghost_WorkflowSelector_Stored_Generation == 0;
}

/// @notice StoredValue: track last isAllowlisted stored in s_workflowSelectors
ghost bool ghost_WorkflowSelector_Stored_IsAllowlisted {
    init_state axiom ghost_WorkflowSelector_Stored_IsAllowlisted == false;
}

/// @notice StoreCount: track stores to s_workflowGenerations
ghost mathint ghost_WorkflowGeneration_StoreCount {
    init_state axiom ghost_WorkflowGeneration_StoreCount == 0;
}

/// @notice StoredValue: track the last workflow generation stored
ghost uint256 ghost_WorkflowGeneration_Stored_Value {
    init_state axiom ghost_WorkflowGeneration_Stored_Value == 0;
}

ghost mathint ghost_Paused_EventCount {
    init_state axiom ghost_Paused_EventCount == 0;
}

ghost mathint ghost_Unpaused_EventCount {
    init_state axiom ghost_Unpaused_EventCount == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
// hook onto emitted events and increment relevant ghosts
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

hook LOG1(uint offset, uint length, bytes32 t0) {
    if (t0 == PausedEvent()) {
        ghost_Paused_EventCount = ghost_Paused_EventCount + 1;
    }
    if (t0 == UnpausedEvent()) {
        ghost_Unpaused_EventCount = ghost_Unpaused_EventCount + 1;
    }
}

/// @notice hook onto s_workflowMetadata owner storage writes
hook Sstore s_workflowMetadata[KEY bytes32 workflowId].owner address newValue (address oldValue) {
    ghost_WorkflowMetadata_Owner_StoreCount = ghost_WorkflowMetadata_Owner_StoreCount + 1;
    ghost_WorkflowMetadata_Stored_WorkflowId = workflowId;
    ghost_WorkflowMetadata_Stored_Owner = newValue;
}

/// @notice hook onto s_workflowMetadata name storage writes
hook Sstore s_workflowMetadata[KEY bytes32 workflowId].name bytes10 newValue (bytes10 oldValue) {
    ghost_WorkflowMetadata_Name_StoreCount = ghost_WorkflowMetadata_Name_StoreCount + 1;
    ghost_WorkflowMetadata_Stored_WorkflowId = workflowId;
    ghost_WorkflowMetadata_Stored_Name = newValue;
}

/// @notice hook onto s_workflowSelectors storage writes
hook Sstore s_workflowSelectors[KEY bytes32 workflowId][KEY uint256 generation][KEY bytes4 selector] bool newValue (bool oldValue) {
    ghost_WorkflowSelector_Store_Count = ghost_WorkflowSelector_Store_Count + 1;
    ghost_WorkflowSelector_Stored_WorkflowId = workflowId;
    ghost_WorkflowSelector_Stored_Selector = selector;
    ghost_WorkflowSelector_Stored_Generation = generation;
    ghost_WorkflowSelector_Stored_IsAllowlisted = newValue;
}

/// @notice hook onto s_workflowGenerations storage writes
hook Sstore s_workflowGenerations[KEY bytes32 workflowId] uint256 newValue (uint256 oldValue) {
    ghost_WorkflowGeneration_StoreCount = ghost_WorkflowGeneration_StoreCount + 1;
    ghost_WorkflowGeneration_Stored_Value = newValue;
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
invariant noZeroVault()
    currentContract.i_vault != 0;

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule getVault_ReturnsConfiguredVault() {
    assert getVault() == currentContract.i_vault;
}

rule supportsInterface_Success_WhenInterfaceIsIReceiver() {
    assert supportsInterface(receiverInterfaceId());
}

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
    require selectors.length > 0, "selectors should not be empty";
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    require metadata.owner != 0, "workflow should be registered";

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
    require selectors.length > 0, "selectors should not be empty";
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    require metadata.owner != 0, "workflow should be registered";

    /// @dev revert condition being verified
    require workflowId == to_bytes32(0), "zero workflowId";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert lastReverted;
}

rule setWorkflowSelectors_RevertWhen_SelectorsAreEmpty() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowlisted;
    selectors = [];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    require metadata.owner != 0, "workflow should be registered";

    /// @dev revert condition being verified
    require selectors.length == 0, "selectors should be empty";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert lastReverted;
}

rule setWorkflowSelectors_RevertWhen_WorkflowIsNotRegistered() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowlisted;
    bytes4 selector;
    selectors = [selector];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require selectors.length > 0, "selectors should not be empty";

    /// @dev revert condition being verified
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    require metadata.owner == 0, "workflow should not be registered";

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert lastReverted;
}

rule setWorkflowSelectors_Success() {
    env e;
    bytes32 workflowId;
    bytes4[] selectors;
    bool isAllowlisted;
    bytes4 s1;
    bytes4 otherSelector;
    selectors = [s1];

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "zero workflowId";
    require selectors.length > 0, "selectors should not be empty";
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    require metadata.owner != 0, "workflow should be registered";

    /// @dev condition being verified
    require otherSelector != s1, "selectors should be distinct";

    /// @dev ghost starting values
    require ghost_WorkflowSelectorSet_EventCount == 0, "event count starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_workflowId == to_bytes32(0), "ghost param starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_selector == to_bytes4(0), "ghost param starts at 0";
    require ghost_WorkflowSelectorSet_EventParam_isAllowlisted == false, "ghost param starts at false";
    require ghost_WorkflowSelector_Store_Count == 0, "selector store count starts at 0";
    require ghost_WorkflowSelector_Stored_WorkflowId == to_bytes32(0), "selector stored workflowId starts at 0";
    require ghost_WorkflowSelector_Stored_Selector == to_bytes4(0), "selector stored selector starts at 0";
    require ghost_WorkflowSelector_Stored_Generation == 0, "selector stored generation starts at 0";
    require ghost_WorkflowSelector_Stored_IsAllowlisted == false, "selector stored isAllowlisted starts at false";

    uint256 generationBefore = getWorkflowGeneration(workflowId);
    bool otherSelectorBefore = getAllowlistedWorkflowSelector(workflowId, otherSelector);

    setWorkflowSelectors@withrevert(e, workflowId, selectors, isAllowlisted);
    assert !lastReverted;
    assert ghost_WorkflowSelectorSet_EventCount == 1;
    assert ghost_WorkflowSelectorSet_EventParam_workflowId == workflowId;
    assert ghost_WorkflowSelectorSet_EventParam_selector == s1;
    assert ghost_WorkflowSelectorSet_EventParam_isAllowlisted == isAllowlisted;
    assert ghost_WorkflowSelector_Store_Count == 1;
    assert ghost_WorkflowSelector_Stored_WorkflowId == workflowId;
    assert ghost_WorkflowSelector_Stored_Selector == s1;
    assert ghost_WorkflowSelector_Stored_Generation == generationBefore;
    assert ghost_WorkflowSelector_Stored_IsAllowlisted == isAllowlisted;
    assert getAllowlistedWorkflowSelector(workflowId, s1) == isAllowlisted;
    assert getAllowlistedWorkflowSelector(workflowId, otherSelector) == otherSelectorBefore;
    assert getWorkflowGeneration(workflowId) == generationBefore;
}

rule PAUSE_003_pause_RevertWhen_CallerDoesNotHavePAUSER_ROLE() {
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
    require ghost_Paused_EventCount == 0, "Paused event count starts at zero";

    pause@withrevert(e);
    assert !lastReverted;
    assert currentContract._paused;
    assert ghost_Paused_EventCount == 1;
}

rule pause_RevertWhen_AlreadyPaused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(PAUSER_ROLE(), e.msg.sender), "only PAUSER_ROLE can call";

    /// @dev revert condition being verified
    require currentContract._paused, "should be paused";

    pause@withrevert(e);
    assert lastReverted;
}

rule PAUSE_003_unpause_RevertWhen_CallerDoesNotHaveUNPAUSER_ROLE() {
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
    require currentContract._paused, "should be paused";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender), "only UNPAUSER_ROLE can call";
    require ghost_Unpaused_EventCount == 0, "Unpaused event count starts at zero";

    unpause@withrevert(e);
    assert !lastReverted;
    assert !currentContract._paused;
    assert ghost_Unpaused_EventCount == 1;
}

rule unpause_RevertWhen_NotPaused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender), "only UNPAUSER_ROLE can call";

    /// @dev revert condition being verified
    require !currentContract._paused, "should not be paused";

    unpause@withrevert(e);
    assert lastReverted;
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
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);
    require current.owner != owner || current.name != name, "metadata should change";
    require getWorkflowGeneration(workflowId) != max_uint256, "generation should not overflow";

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
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);
    require current.owner != owner || current.name != name, "metadata should change";
    require getWorkflowGeneration(workflowId) != max_uint256, "generation should not overflow";

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
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);
    require current.owner != owner || current.name != name, "metadata should change";
    require getWorkflowGeneration(workflowId) != max_uint256, "generation should not overflow";

    /// @dev revert condition being verified
    require name != to_bytes10(0) && owner == 0 || name == to_bytes10(0) && owner != 0, "mismatched zero metadata";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
}

rule setWorkflowMetadata_RevertWhen_MetadataIsUnchanged() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "no mismatched zero metadata";
    require getWorkflowGeneration(workflowId) != max_uint256, "generation should not overflow";

    /// @dev revert condition being verified
    require current.owner == owner && current.name == name, "metadata should be unchanged";

    uint256 generationBefore = getWorkflowGeneration(workflowId);
    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
    assert getWorkflowGeneration(workflowId) == generationBefore;
}

rule setWorkflowMetadata_RevertWhen_GenerationOverflows() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "no mismatched zero metadata";
    require current.owner != owner || current.name != name, "metadata should change";

    /// @dev revert condition being verified
    require getWorkflowGeneration(workflowId) == max_uint256, "generation should overflow";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert lastReverted;
}

rule setWorkflowMetadata_Success() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;
    bytes32 otherWorkflowId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "no zero value";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "mismatched zero metadata";
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);
    require current.owner != owner || current.name != name, "metadata should change";
    uint256 generationBefore = getWorkflowGeneration(workflowId);
    require generationBefore != max_uint256, "generation should not overflow";

    /// @dev condition being verified
    require otherWorkflowId != workflowId, "workflowIds should be distinct";

    IWorkflowRouter.WorkflowMetadata otherMetadataBefore = getWorkflowMetadata(otherWorkflowId);
    uint256 otherGenerationBefore = getWorkflowGeneration(otherWorkflowId);

    /// @dev ghost starting values
    require ghost_WorkflowMetadataSet_EventCount == 0, "WorkflowMetadataSet event count starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_workflowId == to_bytes32(0), "WorkflowMetadataSet workflowId ghost starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_name == to_bytes10(0), "WorkflowMetadataSet name ghost starts at zero";
    require ghost_WorkflowMetadataSet_EventParam_owner == 0, "WorkflowMetadataSet owner ghost starts at zero";
    require ghost_WorkflowMetadata_Owner_StoreCount == 0, "metadata owner store count starts at zero";
    require ghost_WorkflowMetadata_Name_StoreCount == 0, "metadata name store count starts at zero";
    require ghost_WorkflowMetadata_Stored_WorkflowId == to_bytes32(0), "metadata stored workflowId starts at zero";
    require ghost_WorkflowMetadata_Stored_Name == to_bytes10(0), "metadata stored name starts at zero";
    require ghost_WorkflowMetadata_Stored_Owner == 0, "metadata stored owner starts at zero";
    require ghost_WorkflowGeneration_StoreCount == 0, "generation store count starts at zero";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert !lastReverted;
    assert ghost_WorkflowMetadataSet_EventCount == 1;
    assert ghost_WorkflowMetadataSet_EventParam_workflowId == workflowId;
    assert ghost_WorkflowMetadataSet_EventParam_name == name;
    assert ghost_WorkflowMetadataSet_EventParam_owner == owner;
    assert ghost_WorkflowMetadata_Owner_StoreCount == 1;
    assert ghost_WorkflowMetadata_Name_StoreCount == 1;
    assert ghost_WorkflowMetadata_Stored_WorkflowId == workflowId;
    assert ghost_WorkflowMetadata_Stored_Name == name;
    assert ghost_WorkflowMetadata_Stored_Owner == owner;
    assert ghost_WorkflowGeneration_StoreCount == 1;
    assert ghost_WorkflowGeneration_Stored_Value == generationBefore + 1;
    assert getWorkflowGeneration(workflowId) == generationBefore + 1;
    IWorkflowRouter.WorkflowMetadata metadata = getWorkflowMetadata(workflowId);
    assert metadata.owner == owner;
    assert metadata.name == name;
    IWorkflowRouter.WorkflowMetadata otherMetadataAfter = getWorkflowMetadata(otherWorkflowId);
    assert otherMetadataAfter.owner == otherMetadataBefore.owner;
    assert otherMetadataAfter.name == otherMetadataBefore.name;
    assert getWorkflowGeneration(otherWorkflowId) == otherGenerationBefore;
}

rule setWorkflowMetadata_Success_InvalidatesPreviousGenerationSelectors() {
    env e;
    bytes32 workflowId;
    bytes10 name;
    address owner;
    bytes4 selector;
    IWorkflowRouter.WorkflowMetadata current = getWorkflowMetadata(workflowId);
    uint256 generationBefore = getWorkflowGeneration(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "only CONFIG_OPERATOR_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require name != to_bytes10(0) && owner != 0 || name == to_bytes10(0) && owner == 0, "no mismatched zero metadata";
    require current.owner != owner || current.name != name, "metadata should change";
    require generationBefore != max_uint256, "generation should not overflow";

    /// @dev conditions being verified
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted in current generation";
    require !getWorkflowSelectorAtNextGeneration(workflowId, selector),
        "selector should not be allowlisted in next generation";

    setWorkflowMetadata@withrevert(e, workflowId, name, owner);
    assert !lastReverted;
    assert getWorkflowGeneration(workflowId) == generationBefore + 1;
    assert !getAllowlistedWorkflowSelector(workflowId, selector);
    assert getWorkflowSelectorAtGeneration(workflowId, generationBefore, selector);
}

rule ROUTER_002_onReport_RevertWhen_Paused() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require currentContract._paused, "should be paused";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule ROUTER_001_onReport_RevertWhen_CallerDoesNotHaveKEYSTONE_FORWARDER_ROLE() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require !hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_MetadataIsTooShort() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildShortMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require metadata.length < 64, "metadata should be too short";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_MetadataIsTooLong() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildLongMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require metadata.length > 64, "metadata should be too long";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_WorkflowIdIsZero() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require workflowId == to_bytes32(0), "workflowId should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_WorkflowNameIsZero() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require workflowName == to_bytes10(0), "workflowName should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_WorkflowOwnerIsZero() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require registered.name == workflowName && registered.owner == workflowOwner, "metadata should match";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require workflowOwner == 0, "workflowOwner should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule ROUTER_003_onReport_RevertWhen_WorkflowMetadataDoesNotMatch() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require report.length >= 4, "report should not be too short";
    require getAllowlistedWorkflowSelector(workflowId, selector), "selector should be allowlisted";

    /// @dev revert condition being verified
    require registered.name != workflowName || registered.owner != workflowOwner, "metadata should not match";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule onReport_RevertWhen_ReportIsTooShort() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes3 shortReport;
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildShortReport(shortReport);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName, "metadata name should match";
    require registered.owner == workflowOwner, "metadata owner should match";

    /// @dev revert condition being verified
    require report.length < 4, "report should be too short";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule ROUTER_004_onReport_RevertWhen_SelectorIsNotAllowlisted() {
    env e;
    bytes32 workflowId;
    bytes10 workflowName;
    address workflowOwner;
    bytes4 selector = certoraVaultCallSucceedsSelector();
    bytes metadata = buildMetadata(workflowId, workflowName, workflowOwner);
    bytes report = buildReport(selector);
    IWorkflowRouter.WorkflowMetadata registered = getWorkflowMetadata(workflowId);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !currentContract._paused, "should not be paused";
    require hasRole(KEYSTONE_FORWARDER_ROLE(), e.msg.sender), "only KEYSTONE_FORWARDER_ROLE can call";
    require metadata.length == 64, "metadata length should be valid";
    require workflowId != to_bytes32(0), "workflowId should not be zero";
    require workflowName != to_bytes10(0), "workflowName should not be zero";
    require workflowOwner != 0, "workflowOwner should not be zero";
    require registered.name == workflowName, "metadata name should match";
    require registered.owner == workflowOwner, "metadata owner should match";
    require report.length >= 4, "report should not be too short";

    /// @dev revert condition being verified
    require !getAllowlistedWorkflowSelector(workflowId, selector), "selector should not be allowlisted";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}