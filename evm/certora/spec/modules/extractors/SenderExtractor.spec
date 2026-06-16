/// Verification of SenderExtractor
/// @author @contractlevel
/// @notice SenderExtractor extracts the sender from a policy engine payload

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // SenderExtractor methods
    function PARAM_SENDER() external returns (bytes32) envfree;

    // Harness helper methods
    function bytesToAddress(bytes) external returns (address) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule extract_Success_ReturnsSenderParameter() {
    env e;
    IPolicyEngine.Payload payload;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    IPolicyEngine.Parameter[] parameters = extract@withrevert(e, payload);
    assert !lastReverted;
    assert parameters.length == 1;
    assert parameters[0].name == PARAM_SENDER();
    assert bytesToAddress(parameters[0].value) == payload.sender;
}
