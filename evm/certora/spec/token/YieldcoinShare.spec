/// Verification of YieldcoinShare
/// @author @contractlevel
/// @notice YieldcoinShare is the compliance-ready ERC-3643 share token of Yieldcoin v2.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // YieldcoinShare methods
    function initialize(address, address, address) external;
    function setCCIPAdmin(address) external;
    function getCCIPAdmin() external returns (address) envfree;
    function attachPolicyEngine(address) external;
    function renounceOwnership() external;
    function authorizeUpgrade(address) external;
    function getPolicyEngine() external returns (address) envfree;
    function owner() external returns (address) envfree;

    // Harness helper methods
    function isInitialized() external returns (bool) envfree;
    function isInitializing() external returns (bool) envfree;
    function reentrancyGuardEntered() external returns (bool) envfree;
    function s_mockPolicyEngine() external returns (address) envfree;
    function hasExpectedMetadata() external returns (bool) envfree;
    function hasEmptyMetadata() external returns (bool) envfree;
    function callInheritedInitialize(address) external;
    function bytes32ToAddress(bytes32) external returns (address) envfree;

    // ACE PolicyEngine calls in _attachPolicyEngine — not virtual, can't override in harness
    function _.attach() external => DISPATCHER(true);
    function _.detach() external => DISPATCHER(true);
    function _.run(IPolicyEngine.Payload) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition CCIPAdminTransferredEvent() returns bytes32 =
// keccak256("CCIPAdminTransferred(address,address)")
    to_bytes32(0x9524c9e4b0b61eb018dd58a1cd856e3e74009528328ab4a613b434fa631d7242);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice StoreCount: track stores to ccipAdmin
ghost mathint ghost_ccipAdmin_StoreCount {
    init_state axiom ghost_ccipAdmin_StoreCount == 0;
}

/// @notice StoredValue: track last value stored to ccipAdmin
ghost address ghost_ccipAdmin_StoredValue {
    init_state axiom ghost_ccipAdmin_StoredValue == 0;
}

/// @notice EventCount: track amount CCIPAdminTransferred event is emitted
ghost mathint ghost_CCIPAdminTransferred_EventCount {
    init_state axiom ghost_CCIPAdminTransferred_EventCount == 0;
}

/// @notice EmittedValue: track previousAdmin param emitted in CCIPAdminTransferred event
ghost address ghost_CCIPAdminTransferred_EventParam_previousAdmin {
    init_state axiom ghost_CCIPAdminTransferred_EventParam_previousAdmin == 0;
}

/// @notice EmittedValue: track newAdmin param emitted in CCIPAdminTransferred event
ghost address ghost_CCIPAdminTransferred_EventParam_newAdmin {
    init_state axiom ghost_CCIPAdminTransferred_EventParam_newAdmin == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto ccipAdmin storage writes (ERC-7201 namespace: yieldcoin.storage.YieldcoinShare)
hook Sstore currentContract.ext_yieldcoin_storage_YieldcoinShare.ccipAdmin address newValue (address oldValue) {
    ghost_ccipAdmin_StoreCount = ghost_ccipAdmin_StoreCount + 1;
    ghost_ccipAdmin_StoredValue = newValue;
}

/// @notice CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin) — LOG3
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == CCIPAdminTransferredEvent()) {
        ghost_CCIPAdminTransferred_EventCount = ghost_CCIPAdminTransferred_EventCount + 1;
        ghost_CCIPAdminTransferred_EventParam_previousAdmin = bytes32ToAddress(t1);
        ghost_CCIPAdminTransferred_EventParam_newAdmin = bytes32ToAddress(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule UPGRADE_001_renounceOwnership_AlwaysReverts() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    renounceOwnership@withrevert(e);
    assert lastReverted;
}

rule UPGRADE_001_authorizeUpgrade_RevertWhen_CallerIsNotOwner() {
    env e;
    address newImplementation;

    require e.msg.value == 0, "non-payable";
    require e.msg.sender != owner(), "caller should not be the owner";

    authorizeUpgrade@withrevert(e, newImplementation);
    assert lastReverted;
}

rule UPGRADE_001_authorizeUpgrade_Success_WhenCallerIsOwner() {
    env e;
    address newImplementation;

    require e.msg.value == 0, "non-payable";
    require e.msg.sender == owner(), "caller should be the owner";

    authorizeUpgrade@withrevert(e, newImplementation);
    assert !lastReverted;
}

rule UPGRADE_002_initialize_RevertWhen_AlreadyInitialized() {
    env e;
    address policyEngine;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require policyEngine != 0, "exclude policyEngine zero revert";
    require upgrader != 0, "exclude upgrader zero revert";
    require ccipAdmin != 0, "exclude ccipAdmin zero revert";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitializing(), "contract should not already be initializing";

    /// @dev revert condition being verified: OZ initializer modifier reverts when already initialized.
    require isInitialized(), "contract is already initialized";

    initialize@withrevert(e, policyEngine, ccipAdmin, upgrader);
    assert lastReverted;
}

rule initialize_RevertWhen_AlreadyInitializing() {
    env e;
    address policyEngine;
    address initialCcipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require policyEngine != 0, "exclude policyEngine zero revert";
    require initialCcipAdmin != 0, "exclude ccipAdmin zero revert";
    require upgrader != 0, "exclude upgrader zero revert";
    require !isInitialized(), "contract is not initialized";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require isInitializing(), "contract should already be initializing";

    initialize@withrevert(e, policyEngine, initialCcipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_UpgraderIsZero() {
    env e;
    address policyEngine;
    address initialCcipAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require policyEngine != 0, "exclude policyEngine zero revert";
    require initialCcipAdmin != 0, "exclude ccipAdmin zero revert";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "OZ _initializing is false so isTopLevelCall=true and the initializer modifier passes";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    initialize@withrevert(e, policyEngine, initialCcipAdmin, 0);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_PolicyEngineIsZero() {
    env e;
    address initialCcipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require upgrader != 0, "exclude upgrader zero revert";
    require initialCcipAdmin != 0, "exclude ccipAdmin zero revert";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "OZ _initializing is false so isTopLevelCall=true and the initializer modifier passes";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    initialize@withrevert(e, 0, initialCcipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_TOKEN_001_initialize_RevertWhen_InitialCcipAdminIsZero() {
    env e;
    address policyEngine;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require policyEngine != 0, "exclude policyEngine zero revert";
    require upgrader != 0, "exclude upgrader zero revert";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "OZ _initializing is false so isTopLevelCall=true and the initializer modifier passes";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    initialize@withrevert(e, policyEngine, 0, upgrader);
    assert lastReverted;
}

rule REENT_001_initialize_RevertWhen_ReentrancyGuardIsEntered() {
    env e;
    address policyEngine;
    address initialCcipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require policyEngine != 0, "exclude policyEngine zero revert";
    require initialCcipAdmin != 0, "exclude ccipAdmin zero revert";
    require upgrader != 0, "exclude upgrader zero revert";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "OZ _initializing is false so isTopLevelCall=true and the initializer modifier passes";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    initialize@withrevert(e, policyEngine, initialCcipAdmin, upgrader);
    assert lastReverted;
}

rule TOKEN_001_initialize_Success() {
    env e;
    address policyEngine;
    address initialCcipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender != 0, "exclude inherited Ownable zero initialOwner revert";
    require hasEmptyMetadata(), "metadata storage should start empty";
    require getCCIPAdmin() == 0, "ccipAdmin storage should start empty";
    require policyEngine != 0, "policyEngine should not be zero";
    require initialCcipAdmin != 0, "ccipAdmin should not be zero";
    require upgrader != 0, "upgrader should not be zero";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "OZ _initializing is false so isTopLevelCall=true and the initializer modifier passes";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev ghost starting values
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIPAdminTransferred event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "ccipAdmin store count starts at zero";

    initialize@withrevert(e, policyEngine, initialCcipAdmin, upgrader);
    assert !lastReverted;
    assert isInitialized();
    assert !isInitializing();
    assert !reentrancyGuardEntered();
    assert hasExpectedMetadata();
    assert getPolicyEngine() == policyEngine;
    assert getCCIPAdmin() == initialCcipAdmin;
    assert owner() == upgrader;
    assert ghost_CCIPAdminTransferred_EventCount == 1;
    assert ghost_CCIPAdminTransferred_EventParam_previousAdmin == 0;
    assert ghost_CCIPAdminTransferred_EventParam_newAdmin == initialCcipAdmin;
    assert ghost_ccipAdmin_StoreCount == 1;
    assert ghost_ccipAdmin_StoredValue == initialCcipAdmin;
}

rule UPGRADE_002_inheritedInitialize_AlwaysReverts() {
    env e;
    address policyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require policyEngine != 0, "policyEngine should not be zero";
    require !isInitialized(), "contract is not yet initialized";
    require !isInitializing(), "contract should not be initializing";

    callInheritedInitialize@withrevert(e, policyEngine);
    assert lastReverted;
}

rule setCCIPAdmin_RevertWhen_PolicyEngineUndefined() {
    env e;
    address newAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require newAdmin != 0, "exclude zero newAdmin revert";

    /// @dev revert condition being verified
    require s_mockPolicyEngine() == 0, "policy engine is undefined";

    /// @dev ghost starting values
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIPAdminTransferred event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "ccipAdmin store count starts at zero";

    setCCIPAdmin@withrevert(e, newAdmin);
    assert lastReverted;
    assert ghost_CCIPAdminTransferred_EventCount == 0;
    assert ghost_ccipAdmin_StoreCount == 0;
}

rule CFG_001_TOKEN_001_setCCIPAdmin_RevertWhen_NewAdminIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require s_mockPolicyEngine() != 0, "policy engine is defined";

    /// @dev ghost starting values
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIPAdminTransferred event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "ccipAdmin store count starts at zero";

    /// @dev revert condition being verified
    setCCIPAdmin@withrevert(e, 0);
    assert lastReverted;
    assert ghost_CCIPAdminTransferred_EventCount == 0;
    assert ghost_ccipAdmin_StoreCount == 0;
}

rule TOKEN_001_setCCIPAdmin_Success() {
    env e;
    address newAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require s_mockPolicyEngine() != 0, "policy engine is defined";
    require newAdmin != 0, "newAdmin is nonzero";

    /// @dev capture previous state for event param verification
    address previousAdmin = getCCIPAdmin();

    /// @dev ghost starting values
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIPAdminTransferred event count starts at zero";
    require ghost_CCIPAdminTransferred_EventParam_previousAdmin == 0, "previousAdmin ghost starts at zero";
    require ghost_CCIPAdminTransferred_EventParam_newAdmin == 0, "newAdmin ghost starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "ccipAdmin store count starts at zero";
    require ghost_ccipAdmin_StoredValue == 0, "ccipAdmin stored value starts at zero";

    setCCIPAdmin@withrevert(e, newAdmin);

    assert !lastReverted;
    assert ghost_CCIPAdminTransferred_EventCount == 1;
    assert ghost_CCIPAdminTransferred_EventParam_previousAdmin == previousAdmin;
    assert ghost_CCIPAdminTransferred_EventParam_newAdmin == newAdmin;
    assert ghost_ccipAdmin_StoreCount == 1;
    assert ghost_ccipAdmin_StoredValue == newAdmin;
    assert getCCIPAdmin() == newAdmin;
}

rule CFG_001_TOKEN_001_attachPolicyEngine_RevertWhen_NewPolicyEngineIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require s_mockPolicyEngine() != 0, "current policy engine is defined so runPolicy passes";

    /// @dev revert condition being verified
    attachPolicyEngine@withrevert(e, 0);
    assert lastReverted;
}

rule TOKEN_001_attachPolicyEngine_RevertWhen_PolicyEngineUndefined() {
    env e;
    address policyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require policyEngine != 0, "new policy engine should not be zero";

    /// @dev revert condition being verified
    require s_mockPolicyEngine() == 0, "current policy engine is undefined";

    attachPolicyEngine@withrevert(e, policyEngine);
    assert lastReverted;
}

rule TOKEN_001_attachPolicyEngine_Success() {
    env e;
    address policyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require s_mockPolicyEngine() != 0, "current policy engine is defined so runPolicy passes";
    require policyEngine != 0, "new policy engine should not be zero";

    attachPolicyEngine@withrevert(e, policyEngine);
    assert !lastReverted;
    assert getPolicyEngine() == policyEngine;
}
