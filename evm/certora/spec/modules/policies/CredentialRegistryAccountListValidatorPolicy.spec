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
    function emptyParameters() external returns (bytes[]) envfree;
    function oneAccountParameters(address) external returns (bytes[]) envfree;
    function emptyAccountListParameters() external returns (bytes[]) envfree;
    function malformedAccountListParameters() external returns (bytes[]) envfree;
    function bytesToAddressArray(bytes) external returns (address[]) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule TOKEN_004_run_RevertWhen_ParametersAreEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = emptyParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require currentContract.s_requirementsConfigured, "requirements should be configured";

    /// @dev revert condition being verified
    require parameters.length == 0, "parameters should be empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_004_run_RevertWhen_AccountListIsEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = emptyAccountListParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";
    require currentContract.s_requirementsConfigured, "requirements should be configured";

    /// @dev revert condition being verified
    address[] accounts = bytesToAddressArray(parameters[0]);
    require accounts.length == 0, "account list should be empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_004_run_RevertWhen_AccountListEncodingIsMalformed() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    bytes[] parameters = malformedAccountListParameters();

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";
    require currentContract.s_requirementsConfigured, "requirements should be configured";

    /// @dev revert condition being verified
    require parameters[0].length == 0, "account list encoding should be malformed";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_004_run_RevertWhen_AccountInvalid() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address a1;
    bytes[] parameters = oneAccountParameters(a1);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";
    address[] accounts = bytesToAddressArray(parameters[0]);
    require accounts.length == 1, "account list should not be empty";
    require currentContract.s_requirementsConfigured, "requirements should be configured";

    /// @dev revert condition being verified
    require !validate(a1, context), "account should not be valid";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_004_run_RevertWhen_NoCredentialRequirementsAreConfigured() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address account;
    bytes[] parameters = oneAccountParameters(account);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";
    address[] accounts = bytesToAddressArray(parameters[0]);
    require accounts.length == 1, "account list should not be empty";
    require validate(account, context), "account should be valid";

    /// @dev revert condition being verified
    require !currentContract.s_requirementsConfigured, "requirements should be NOT configured";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}

rule TOKEN_004_run_Success() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes context;
    address a1;
    bytes[] parameters = oneAccountParameters(a1);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 1, "expected kyc account list";
    address[] accounts = bytesToAddressArray(parameters[0]);
    require accounts.length == 1, "account list should not be empty";
    require currentContract.s_requirementsConfigured, "requirements should be configured";
    require validate(a1, context), "account should be valid";

    IPolicyEngine.PolicyResult result = run@withrevert(e, caller, subject, selector, parameters, context);
    assert !lastReverted;
    assert result == IPolicyEngine.PolicyResult.Continue;
}
