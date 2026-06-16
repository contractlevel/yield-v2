/// Verification of YieldcoinShareKycExtractor
/// @author @contractlevel
/// @notice YieldcoinShareKycExtractor extracts accounts requiring KYC from YieldcoinShare payloads

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // YieldcoinShareKycExtractor methods
    function PARAM_KYC_ACCOUNTS() external returns (bytes32) envfree;

    // Harness helper methods
    function decreaseAllowancePayload(address, address, uint256) external returns (IPolicyEngine.Payload) envfree;
    function unsupportedPayload(bytes4, address) external returns (IPolicyEngine.Payload) envfree;
    function isSupportedSelector(bytes4) external returns (bool) envfree;
    function bytesToAddressArray(bytes) external returns (address[]) envfree;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule extract_SuccessfulReturn_IsWellFormed() {
    env e;
    IPolicyEngine.Payload payload;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require isSupportedSelector(payload.selector), "should be supported";

    IPolicyEngine.Parameter[] parameters = extract@withrevert(e, payload);

    assert !lastReverted => parameters.length == 1;
    assert !lastReverted => parameters[0].name == PARAM_KYC_ACCOUNTS();
}

/// @notice The other supported selector success paths decode dynamic payload.data and are vacuous under
/// Certora's current model; decreaseAllowance is verified separately because it does not decode payload.data.
rule extract_Success_WhenSelectorIsDecreaseAllowance() {
    env e;
    address sender;
    address spender;
    uint256 amount;
    IPolicyEngine.Payload payload = decreaseAllowancePayload(sender, spender, amount);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    IPolicyEngine.Parameter[] parameters = extract@withrevert(e, payload);
    assert !lastReverted;
    assert parameters.length == 1;
    assert parameters[0].name == PARAM_KYC_ACCOUNTS();

    address[] accounts = bytesToAddressArray(parameters[0].value);
    assert accounts.length == 1;
    assert accounts[0] == sender;
}

rule extract_RevertWhen_SelectorIsUnsupported() {
    env e;
    bytes4 selector;
    address sender;
    IPolicyEngine.Payload payload = unsupportedPayload(selector, sender);

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require !isSupportedSelector(selector), "selector should be unsupported";

    extract@withrevert(e, payload);
    assert lastReverted;
}
