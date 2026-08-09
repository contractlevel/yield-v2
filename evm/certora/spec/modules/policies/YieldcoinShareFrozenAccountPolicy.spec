using MockYieldcoinShare as share;

/// Verification of YieldcoinShareFrozenAccountPolicy
/// @author @contractlevel
/// @notice Rejects accounts frozen on the configured YieldcoinShare token

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // YieldcoinShareFrozenAccountPolicy methods
    function getShare() external returns (address) envfree;

    // Linked share methods
    function share.isFrozen(address) external returns (bool) envfree;

    // Harness helper methods
    function emptyParameters() external returns (bytes[]) envfree;
    function oneAccountParameters(address) external returns (bytes[]) envfree;
    function truncatedAccountParameters() external returns (bytes[]) envfree;
    function dirtyAddressParameters() external returns (bytes[]) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule CFG_001_getShare_ReturnsConfiguredShare() {
    assert getShare() == share;
    assert getShare() != 0;
}

rule TOKEN_005_run_RevertWhen_ParametersAreEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = emptyParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require parameters.length == 0, "parameters are empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_005_run_RevertWhen_AccountEncodingIsTruncated() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = truncatedAccountParameters();
    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected one parameter";

    /// @dev revert condition being verified: abi.decode requires one complete ABI word
    require parameters[0].length == 31, "encoded account is truncated";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_005_run_RevertWhen_AccountEncodingHasDirtyPadding() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = dirtyAddressParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected one parameter";
    require parameters[0].length == 32, "encoded account contains one ABI word";

    /// @dev revert condition being verified: the upper 96 bits are nonzero for an address
    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_005_run_RevertWhen_AccountIsFrozen() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address account;
    bytes[] parameters = oneAccountParameters(account);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected one parameter";

    /// @dev revert condition being verified
    require share.isFrozen(account), "account is frozen";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_005_run_Success_WhenAccountIsNotFrozen() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address account;
    bytes[] parameters = oneAccountParameters(account);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected one parameter";
    require !share.isFrozen(account), "account is not frozen";

    IPolicyEngine.PolicyResult result = run@withrevert(e, caller, subject, selector, parameters, context);
    assert !lastReverted;
    assert result == IPolicyEngine.PolicyResult.Continue;
}
