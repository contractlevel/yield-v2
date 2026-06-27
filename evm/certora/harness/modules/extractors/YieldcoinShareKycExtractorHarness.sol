// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {HelperHarness} from "../../HelperHarness.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {YieldcoinShareKycExtractor} from "../../../../src/modules/extractors/YieldcoinShareKycExtractor.sol";

contract YieldcoinShareKycExtractorHarness is YieldcoinShareKycExtractor, HelperHarness {
    function decreaseAllowancePayload(address sender, address spender, uint256 amount)
        external
        pure
        returns (IPolicyEngine.Payload memory payload)
    {
        payload = IPolicyEngine.Payload({
            selector: ComplianceTokenERC3643.decreaseAllowance.selector,
            sender: sender,
            data: abi.encode(spender, amount),
            context: bytes("")
        });
    }

    function unsupportedPayload(bytes4 selector, address sender)
        external
        pure
        returns (IPolicyEngine.Payload memory payload)
    {
        payload = IPolicyEngine.Payload({selector: selector, sender: sender, data: bytes(""), context: bytes("")});
    }

    function isSupportedSelector(bytes4 selector) external pure returns (bool) {
        return selector == ComplianceTokenERC3643.transfer.selector
            || selector == ComplianceTokenERC3643.transferFrom.selector
            || selector == ComplianceTokenERC3643.batchTransfer.selector
            || selector == ComplianceTokenERC3643.approve.selector
            || selector == ComplianceTokenERC3643.increaseAllowance.selector
            || selector == ComplianceTokenERC3643.decreaseAllowance.selector;
    }
}
