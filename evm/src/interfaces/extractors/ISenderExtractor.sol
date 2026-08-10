// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title Yieldcoin v2 Sender Extractor Interface
/// @author @contractlevel
/// @notice Interface for the SenderExtractor
interface ISenderExtractor is IExtractor {
    /// @notice The parameter key for the sender
    /// @return paramSender The sender parameter key
    //slither-disable-next-line naming-convention
    function PARAM_SENDER() external pure returns (bytes32 paramSender);

    /// @notice Extracts the transaction sender from a policy engine payload
    /// @param payload The policy engine payload
    /// @return parameters A single parameter named PARAM_SENDER containing `abi.encode(payload.sender)`
    function extract(IPolicyEngine.Payload calldata payload)
        external
        pure
        override
        returns (IPolicyEngine.Parameter[] memory parameters);
}
