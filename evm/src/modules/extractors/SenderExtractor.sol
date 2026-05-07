// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title SenderExtractor
/// @author @contractlevel
/// @notice Extracts the sender from a policy engine payload
contract SenderExtractor is IExtractor {
    /// @notice The type and version of the extractor
    string public constant override typeAndVersion = "SenderExtractor 1.0.0";

    /// @notice The parameter key for the sender
    bytes32 public constant PARAM_SENDER = keccak256("sender");

    /// @notice Extracts the sender from a policy engine payload
    /// @param payload The policy engine payload
    /// @return parameters The extracted parameters
    function extract(IPolicyEngine.Payload calldata payload)
        external
        pure
        override
        returns (IPolicyEngine.Parameter[] memory parameters)
    {
        parameters = new IPolicyEngine.Parameter[](1);
        parameters[0] = IPolicyEngine.Parameter({name: PARAM_SENDER, value: abi.encode(payload.sender)});
    }
}
