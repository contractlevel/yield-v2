// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {TerminalAllowPolicy} from "../../../../src/modules/policies/TerminalAllowPolicy.sol";

contract TerminalAllowPolicyHarness is TerminalAllowPolicy, HelperHarness {
    function nonEmptyParameters(bytes memory parameter) external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = parameter;
    }

    function allowedResult() external pure returns (IPolicyEngine.PolicyResult) {
        return IPolicyEngine.PolicyResult.Allowed;
    }
}
