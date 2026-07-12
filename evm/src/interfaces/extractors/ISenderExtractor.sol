// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";

/// @title Yieldcoin v2 Sender Extractor Interface
/// @author @contractlevel
/// @notice Interface for the SenderExtractor
interface ISenderExtractor is IExtractor {
    /// @notice The parameter key for the sender
    /// @return paramSender The sender parameter key
    function PARAM_SENDER() external pure returns (bytes32 paramSender);
}
