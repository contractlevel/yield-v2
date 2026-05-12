// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {IExtractor} from "@chainlink/policy-management/interfaces/IExtractor.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

/// @title YieldcoinShareKycExtractor
/// @author @contractlevel
/// @notice Extracts every account that must pass KYC for YieldcoinShare user actions.
contract YieldcoinShareKycExtractor is IExtractor {
    /// @notice The type and version of the extractor
    string public constant override typeAndVersion = "YieldcoinShareKycExtractor 1.0.0";

    /// @notice Parameter key for the encoded address array of accounts requiring KYC.
    bytes32 public constant PARAM_KYC_ACCOUNTS = keccak256("kycAccounts");

    /// @notice Extracts KYC account addresses from supported YieldcoinShare selectors.
    /// @param payload The policy engine payload
    /// @return parameters The extracted account list encoded under PARAM_KYC_ACCOUNTS
    function extract(IPolicyEngine.Payload calldata payload)
        external
        pure
        override
        returns (IPolicyEngine.Parameter[] memory parameters)
    {
        address[] memory accounts;

        if (payload.selector == ComplianceTokenERC3643.transfer.selector) {
            (address to,) = abi.decode(payload.data, (address, uint256));
            accounts = new address[](2);
            accounts[0] = payload.sender;
            accounts[1] = to;
        } else if (payload.selector == ComplianceTokenERC3643.transferFrom.selector) {
            (address from, address to,) = abi.decode(payload.data, (address, address, uint256));
            accounts = new address[](3);
            accounts[0] = payload.sender;
            accounts[1] = from;
            accounts[2] = to;
        } else if (payload.selector == ComplianceTokenERC3643.batchTransfer.selector) {
            (address[] memory toList,) = abi.decode(payload.data, (address[], uint256[]));
            accounts = new address[](toList.length + 1);
            accounts[0] = payload.sender;
            for (uint256 i; i < toList.length; ++i) {
                accounts[i + 1] = toList[i];
            }
        } else if (
            payload.selector == ComplianceTokenERC3643.approve.selector
                || payload.selector == ComplianceTokenERC3643.increaseAllowance.selector
                || payload.selector == ComplianceTokenERC3643.decreaseAllowance.selector
        ) {
            (address spender,) = abi.decode(payload.data, (address, uint256));
            accounts = new address[](2);
            accounts[0] = payload.sender;
            accounts[1] = spender;
        } else {
            revert IPolicyEngine.UnsupportedSelector(payload.selector);
        }

        parameters = new IPolicyEngine.Parameter[](1);
        parameters[0] = IPolicyEngine.Parameter({name: PARAM_KYC_ACCOUNTS, value: abi.encode(accounts)});
    }
}
