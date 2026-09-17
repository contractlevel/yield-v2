/// Verification of Allowlist
/// @author @contractlevel
/// @notice Allowlist gates capital suppliers when enforcement is enabled.
/// @dev Batch rules cover up to three entries, including empty arrays, duplicates, and the zero address.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Allowlist methods
    function setAllowlistEnabled(bool) external;
    function setAllowlistedUsers(address[], bool) external;
    function getAllowlistEnabled() external returns (bool) envfree;
    function getAllowlistedUser(address) external returns (bool) envfree;
    function hasRole(bytes32, address) external returns (bool) envfree;

    // Harness helper methods
    function validate(address) external;
    function validate(address, address) external;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;

    // Roles
    function ALLOWLIST_OPERATOR_ROLE() external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition AllowlistEnabledSetEvent() returns bytes32 =
// keccak256("AllowlistEnabledSet(bool)")
    to_bytes32(0xa1bf86c493917580dec207969ef59976f0c378f10ece581237f19acfbd858f1c);

definition AllowlistedUserSetEvent() returns bytes32 =
// keccak256("AllowlistedUserSet(address,bool)")
    to_bytes32(0x11ec34122dd50542f94b4f6c9dad47d8fd94b6bdba2b3cdb1e2205c2e0d0b1e3);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_AllowlistEnabledSet_EventCount {
    init_state axiom ghost_AllowlistEnabledSet_EventCount == 0;
}

ghost bool ghost_AllowlistEnabledSet_EventParam_enabled;

ghost mathint ghost_AllowlistedUserSet_EventCount {
    init_state axiom ghost_AllowlistedUserSet_EventCount == 0;
}

ghost mapping(mathint => address) ghost_AllowlistedUserSet_EventParam_user;
ghost mapping(mathint => bool) ghost_AllowlistedUserSet_EventParam_allowed;

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == AllowlistEnabledSetEvent()) {
        ghost_AllowlistEnabledSet_EventCount = ghost_AllowlistEnabledSet_EventCount + 1;
        ghost_AllowlistEnabledSet_EventParam_enabled = bytes32ToBool(t1);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == AllowlistedUserSetEvent()) {
        ghost_AllowlistedUserSet_EventParam_user[ghost_AllowlistedUserSet_EventCount] = bytes32ToAddress(t1);
        ghost_AllowlistedUserSet_EventParam_allowed[ghost_AllowlistedUserSet_EventCount] = bytes32ToBool(t2);
        ghost_AllowlistedUserSet_EventCount = ghost_AllowlistedUserSet_EventCount + 1;
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule ALLOWLIST_001_setAllowlistEnabled_RevertWhen_CallerDoesNotHaveALLOWLIST_OPERATOR_ROLE() {
    env e;
    bool enabled;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require !hasRole(ALLOWLIST_OPERATOR_ROLE(), e.msg.sender), "caller lacks ALLOWLIST_OPERATOR_ROLE";

    /// @dev ghost starting values
    require ghost_AllowlistEnabledSet_EventCount == 0;
    require ghost_AllowlistedUserSet_EventCount == 0;

    setAllowlistEnabled@withrevert(e, enabled);

    assert lastReverted;
    assert ghost_AllowlistEnabledSet_EventCount == 0;
    assert ghost_AllowlistedUserSet_EventCount == 0;
}

rule ALLOWLIST_001_setAllowlistEnabled_RevertWhen_NonzeroMsgValue() {
    env e;
    bool enabled;

    /// @dev revert conditions NOT being verified
    require hasRole(ALLOWLIST_OPERATOR_ROLE(), e.msg.sender), "caller has ALLOWLIST_OPERATOR_ROLE";

    /// @dev revert condition being verified
    require e.msg.value != 0, "msg.value should be nonzero";

    /// @dev ghost starting values
    require ghost_AllowlistEnabledSet_EventCount == 0;
    require ghost_AllowlistedUserSet_EventCount == 0;

    setAllowlistEnabled@withrevert(e, enabled);

    assert lastReverted;
    assert ghost_AllowlistEnabledSet_EventCount == 0;
    assert ghost_AllowlistedUserSet_EventCount == 0;
}

rule ALLOWLIST_001_setAllowlistedUsers_RevertWhen_CallerDoesNotHaveALLOWLIST_OPERATOR_ROLE() {
    env e;
    address[] users;
    bool allowed;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require users.length <= 3, "batch fits the loop bound";

    /// @dev revert condition being verified
    require !hasRole(ALLOWLIST_OPERATOR_ROLE(), e.msg.sender), "caller lacks ALLOWLIST_OPERATOR_ROLE";

    /// @dev ghost starting values
    require ghost_AllowlistEnabledSet_EventCount == 0;
    require ghost_AllowlistedUserSet_EventCount == 0;

    setAllowlistedUsers@withrevert(e, users, allowed);

    assert lastReverted;
    assert ghost_AllowlistEnabledSet_EventCount == 0;
    assert ghost_AllowlistedUserSet_EventCount == 0;
}


rule ALLOWLIST_003_setAllowlistEnabled_Success() {
    env e;
    bool enabled;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(ALLOWLIST_OPERATOR_ROLE(), e.msg.sender), "caller has ALLOWLIST_OPERATOR_ROLE";

    bool priorMembership = getAllowlistedUser(user);

    /// @dev ghost starting values
    require ghost_AllowlistEnabledSet_EventCount == 0;
    require ghost_AllowlistedUserSet_EventCount == 0;

    setAllowlistEnabled@withrevert(e, enabled);

    assert !lastReverted;
    assert getAllowlistEnabled() == enabled;
    assert getAllowlistedUser(user) == priorMembership;
    assert ghost_AllowlistEnabledSet_EventCount == 1;
    assert ghost_AllowlistEnabledSet_EventParam_enabled == enabled;
    assert ghost_AllowlistedUserSet_EventCount == 0;
}

rule ALLOWLIST_004_setAllowlistedUsers_Success() {
    env e;
    address[] users;
    bool allowed;
    address otherUser;
    uint256 userIndex;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(ALLOWLIST_OPERATOR_ROLE(), e.msg.sender), "caller has ALLOWLIST_OPERATOR_ROLE";
    require users.length <= 3, "batch fits the loop bound";
    require forall uint256 i. i < users.length => users[i] <= max_uint160,
        "users should be canonical";

    /// @dev condition being verified
    require forall uint256 i. i < users.length => users[i] != otherUser,
        "other user is outside the batch";

    bool priorEnabled = getAllowlistEnabled();
    bool priorOtherMembership = getAllowlistedUser(otherUser);

    /// @dev ghost starting values
    require ghost_AllowlistEnabledSet_EventCount == 0;
    require ghost_AllowlistedUserSet_EventCount == 0;

    setAllowlistedUsers@withrevert(e, users, allowed);

    assert !lastReverted;
    assert getAllowlistEnabled() == priorEnabled;
    assert getAllowlistedUser(otherUser) == priorOtherMembership;
    if (userIndex < users.length) {
        assert getAllowlistedUser(users[userIndex]) == allowed;
    }
    assert ghost_AllowlistEnabledSet_EventCount == 0;
    assert ghost_AllowlistedUserSet_EventCount == users.length;
    assert forall uint256 i. i < users.length => ghost_AllowlistedUserSet_EventParam_user[i] == users[i];
    assert forall uint256 i. i < users.length => ghost_AllowlistedUserSet_EventParam_allowed[i] == allowed;
}

rule ALLOWLIST_002_validate_RevertWhen_UserNotAllowlisted() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";

    /// @dev revert condition being verified
    require !getAllowlistedUser(user), "user should not be allowlisted";

    validate@withrevert(e, user);

    assert lastReverted;
}

rule ALLOWLIST_003_validate_Success_WhenAllowlistDisabled() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !getAllowlistEnabled(), "allowlist should be disabled";

    validate@withrevert(e, user);

    assert !lastReverted;
}

rule ALLOWLIST_002_validate_Success_WhenUserAllowlisted() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";
    require getAllowlistedUser(user), "user should be allowlisted";

    validate@withrevert(e, user);

    assert !lastReverted;
}

rule ALLOWLIST_002_validate_RevertWhen_CallerNotAllowlisted() {
    env e;
    address caller;
    address beneficiary;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";
    require getAllowlistedUser(beneficiary), "beneficiary should be allowlisted";
    require caller != beneficiary, "caller should differ from beneficiary";

    /// @dev revert condition being verified
    require !getAllowlistedUser(caller), "caller should not be allowlisted";

    validate@withrevert(e, caller, beneficiary);

    assert lastReverted;
}

rule ALLOWLIST_002_validate_RevertWhen_BeneficiaryNotAllowlisted() {
    env e;
    address caller;
    address beneficiary;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";
    require getAllowlistedUser(caller), "caller should be allowlisted";
    require caller != beneficiary, "caller should differ from beneficiary";

    /// @dev revert condition being verified
    require !getAllowlistedUser(beneficiary), "beneficiary should not be allowlisted";

    validate@withrevert(e, caller, beneficiary);

    assert lastReverted;
}

rule ALLOWLIST_003_validate_Success_WhenAllowlistDisabled_ForCallerAndBeneficiary() {
    env e;
    address caller;
    address beneficiary;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !getAllowlistEnabled(), "allowlist should be disabled";

    validate@withrevert(e, caller, beneficiary);

    assert !lastReverted;
}

rule ALLOWLIST_002_validate_Success_WhenCallerAndBeneficiaryAllowlisted() {
    env e;
    address caller;
    address beneficiary;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";
    require getAllowlistedUser(caller), "caller should be allowlisted";
    require getAllowlistedUser(beneficiary), "beneficiary should be allowlisted";
    require caller != beneficiary, "caller should differ from beneficiary";

    validate@withrevert(e, caller, beneficiary);

    assert !lastReverted;
}

rule ALLOWLIST_002_validate_Success_WhenCallerIsBeneficiary() {
    env e;
    address caller;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";
    require getAllowlistedUser(caller), "caller should be allowlisted";

    validate@withrevert(e, caller, caller);

    assert !lastReverted;
}

rule ALLOWLIST_002_validate_RevertWhen_UnallowlistedCallerIsBeneficiary() {
    env e;
    address caller;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getAllowlistEnabled(), "allowlist should be enabled";

    /// @dev revert condition being verified
    require !getAllowlistedUser(caller), "caller should not be allowlisted";

    validate@withrevert(e, caller, caller);

    assert lastReverted;
}
