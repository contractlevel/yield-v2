/// Verification of TerminalAllowPolicy
/// @author @contractlevel
/// @notice TerminalAllowPolicy allows execution only when no policy parameters are supplied

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // TerminalAllowPolicy methods
    function typeAndVersion() external returns (string) envfree;

    // Harness helper methods
    function emptyParameters() external returns (bytes[]) envfree;
    function nonEmptyParameters(bytes) external returns (bytes[]) envfree;
    function allowedResult() external returns (IPolicyEngine.PolicyResult) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule run_Success_WhenParametersAreEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes[] parameters;
    bytes context;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require parameters.length == 0, "parameters should be empty";

    IPolicyEngine.PolicyResult result = run@withrevert(e, caller, subject, selector, parameters, context);
    assert !lastReverted;
    assert result == allowedResult();
}

rule run_RevertWhen_ParametersAreNotEmpty() {
    env e;
    address caller;
    address subject;
    bytes4 selector;
    bytes parameter;
    bytes[] parameters = nonEmptyParameters(parameter);
    bytes context;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require parameters.length != 0, "parameters should not be empty";

    run@withrevert(e, caller, subject, selector, parameters, context);
    assert lastReverted;
}
