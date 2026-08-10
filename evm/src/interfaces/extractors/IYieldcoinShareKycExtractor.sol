// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title Yieldcoin v2 YieldcoinShare KYC Extractor Interface
/// @author @contractlevel
/// @notice Interface for the YieldcoinShareKycExtractor
interface IYieldcoinShareKycExtractor is IExtractor {
    /// @notice Parameter key for the encoded address array of accounts requiring KYC
    /// @return paramKycAccounts The KYC accounts parameter key
    //slither-disable-next-line naming-convention
    function PARAM_KYC_ACCOUNTS() external pure returns (bytes32 paramKycAccounts);

    /// @notice Extracts the accounts that must satisfy KYC for a supported YieldcoinShare function
    /// @param payload The policy engine payload
    /// @return parameters A single parameter named PARAM_KYC_ACCOUNTS containing `abi.encode(address[])`
    /// @dev Extracts sender and recipient for transfer; sender, owner, and recipient for transferFrom; sender and
    ///      spender for approve and increaseAllowance; and only sender for decreaseAllowance
    /// @dev Reverts if payload.selector is unsupported or payload.data is malformed for the selected function
    function extract(IPolicyEngine.Payload calldata payload)
        external
        pure
        override
        returns (IPolicyEngine.Parameter[] memory parameters);
}
