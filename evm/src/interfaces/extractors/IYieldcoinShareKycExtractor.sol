// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";

/// @title Yieldcoin v2 YieldcoinShare KYC Extractor Interface
/// @author @contractlevel
/// @notice Interface for the YieldcoinShareKycExtractor
interface IYieldcoinShareKycExtractor is IExtractor {
    /// @notice Parameter key for the encoded address array of accounts requiring KYC
    /// @return paramKycAccounts The KYC accounts parameter key
    //slither-disable-next-line naming-convention
    function PARAM_KYC_ACCOUNTS() external pure returns (bytes32 paramKycAccounts);
}
