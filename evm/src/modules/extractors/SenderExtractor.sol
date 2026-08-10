// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {ISenderExtractor} from "../../interfaces/extractors/ISenderExtractor.sol";

/// @title SenderExtractor
/// @author @contractlevel
/// @notice Extracts the sender from a policy engine payload
contract SenderExtractor is ISenderExtractor {
    /// @notice The type and version of the extractor
    string public constant override typeAndVersion = "SenderExtractor 1.0.0";

    /// @notice The parameter key for the sender
    bytes32 public constant PARAM_SENDER = keccak256("sender");

    /// @notice Extracts the transaction sender from a policy engine payload
    /// @param payload The policy engine payload
    /// @return parameters A single parameter named PARAM_SENDER containing `abi.encode(payload.sender)`
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
