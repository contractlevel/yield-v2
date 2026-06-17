/// Verification of CredentialRegistryAccountListValidatorPolicy
/// @author @contractlevel
/// @notice CredentialRegistryAccountListValidatorPolicy validates every account in a KYC account list

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // CredentialRegistryAccountListValidatorPolicy methods
    function validate(address, bytes) external returns (bool) envfree;

    // Harness helper methods
    function setAccountValid(address, bool) external;
    function emptyParameters() external returns (bytes[]) envfree;
    function oneAccountParameters(address) external returns (bytes[]) envfree;
    function twoAccountParameters(address, address) external returns (bytes[]) envfree;
    function emptyAccountListParameters() external returns (bytes[]) envfree;
    function multiplePolicyParameters(address, address) external returns (bytes[]) envfree;
    function bytesToAddressArray(bytes) external returns (address[]) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule run_RevertWhen_ParametersAreEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = emptyParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require parameters.length == 0, "parameters should be empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule run_RevertWhen_AccountListIsEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = emptyAccountListParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";

    /// @dev revert condition being verified
    address[] accounts = bytesToAddressArray(parameters[0]);
    require accounts.length == 0, "account list should be empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

// @review vacuous
rule run_RevertWhen_MultipleParameters() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address a1;
    address a2;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    bytes[] parameters = multiplePolicyParameters(a1, a2);
    require parameters.length == 2, "multiple policy parameters";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

// @review vacuous
rule run_RevertWhen_AccountInvalid() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address a1;
    address a2;
    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require !validate(a1, context) || !validate(a2, context), "an account not should be valid";
    bytes[] parameters = twoAccountParameters(a1, a2);

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

// @review vacuous
rule run_Success() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address a1;
    address a2;
    bytes[] parameters = twoAccountParameters(a1, a2);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require validate(a1, context) && validate(a2, context), "account should be valid";

    IPolicyEngine.PolicyResult result = run@withrevert(e, caller, subject, selector, parameters, context);
    assert !lastReverted;
    assert result == IPolicyEngine.PolicyResult.Continue;
}
