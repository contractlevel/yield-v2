// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {TerminalAllowPolicy} from "../../../../src/modules/policies/TerminalAllowPolicy.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract TerminalAllowPolicy_RunUnitTest is BaseUnitTest {
    TerminalAllowPolicy internal s_terminalAllowPolicy;

    function setUp() public {
        s_terminalAllowPolicy = new TerminalAllowPolicy();
    }

    function test_TerminalAllowPolicy_run_RevertWhen_ParametersAreNotEmpty() external {
        bytes[] memory parameters = new bytes[](1);
        parameters[0] = abi.encode(address(0));

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected 0 parameters"));
        s_terminalAllowPolicy.run(address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes(""));
    }

    function test_TerminalAllowPolicy_run_Success() external view {
        bytes[] memory parameters = new bytes[](0);

        IPolicyEngine.PolicyResult result = s_terminalAllowPolicy.run(
            address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes("")
        );

        assertEq(uint8(result), uint8(IPolicyEngine.PolicyResult.Allowed));
    }
}
