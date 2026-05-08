// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";

/// @title YieldcoinShare
/// @author @contractlevel
/// @notice YieldcoinShare is the compliance-ready share token of the Yieldcoin v2 system.
contract YieldcoinShare is ComplianceTokenERC3643 {
    function initialize(
        address policyEngine
    ) public initializer {
        __ComplianceTokenERC3643_init("Yieldcoin", "YIELD", 18, policyEngine);
    }
}
