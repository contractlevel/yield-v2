// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {IYieldcoinShareKycExtractor} from "../../interfaces/extractors/IYieldcoinShareKycExtractor.sol";

/// @title YieldcoinShareKycExtractor
/// @author @contractlevel
/// @notice Extracts every account that must pass KYC for YieldcoinShare user actions
contract YieldcoinShareKycExtractor is IYieldcoinShareKycExtractor {
    /// @notice The type and version of the extractor
    string public constant override typeAndVersion = "YieldcoinShareKycExtractor 1.0.0";

    /// @notice Parameter key for the encoded address array of accounts requiring KYC
    bytes32 public constant PARAM_KYC_ACCOUNTS = keccak256("kycAccounts");

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
        returns (IPolicyEngine.Parameter[] memory parameters)
    {
        //slither-disable-next-line uninitialized-local
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
        } else if (
            payload.selector == ComplianceTokenERC3643.approve.selector
                || payload.selector == ComplianceTokenERC3643.increaseAllowance.selector
        ) {
            (address spender,) = abi.decode(payload.data, (address, uint256));
            accounts = new address[](2);
            accounts[0] = payload.sender;
            accounts[1] = spender;
        } else if (payload.selector == ComplianceTokenERC3643.decreaseAllowance.selector) {
            // Only the caller must be KYC-approved. Excluding the spender allows owners to
            // revoke allowances for addresses that have since lost KYC status.
            accounts = new address[](1);
            accounts[0] = payload.sender;
        } else {
            revert IPolicyEngine.UnsupportedSelector(payload.selector);
        }

        parameters = new IPolicyEngine.Parameter[](1);
        parameters[0] = IPolicyEngine.Parameter({name: PARAM_KYC_ACCOUNTS, value: abi.encode(accounts)});
    }
}
