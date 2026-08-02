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
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition expectedParamSender() returns bytes32 =
    to_bytes32(0x168e92ce035ba45e59a0314b0ed9a9e619b284aed8f6e5ab0a596efd5c9f5cf9);

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule PARAM_SENDER_ReturnsExpectedValue() {
    assert PARAM_SENDER() == expectedParamSender();
}

rule extract_Success_ReturnsSenderParameter() {
    env e;
    IPolicyEngine.Payload payload;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    IPolicyEngine.Parameter[] parameters = extract@withrevert(e, payload);
    assert !lastReverted;
    assert parameters.length == 1;
    assert parameters[0].name == expectedParamSender();
    assert bytesToAddress(parameters[0].value) == payload.sender;
}
