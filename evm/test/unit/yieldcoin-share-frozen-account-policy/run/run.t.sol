// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {
    YieldcoinShareFrozenAccountPolicy
} from "../../../../src/modules/policies/YieldcoinShareFrozenAccountPolicy.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract YieldcoinShareFrozenAccountPolicy_RunUnitTest is BaseUnitTest {
    YieldcoinShareFrozenAccountPolicy internal s_policy;

    function setUp() public {
        s_policy = new YieldcoinShareFrozenAccountPolicy(address(s_yieldcoin));
    }

    function test_YieldcoinShareFrozenAccountPolicy_run_RevertWhen_ParametersAreEmpty() external {
        bytes[] memory parameters = new bytes[](0);

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected account"));
        s_policy.run(address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes(""));
    }

    function test_YieldcoinShareFrozenAccountPolicy_run_RevertWhen_ParametersHaveMoreThanOneAccount() external {
        bytes[] memory parameters = new bytes[](2);
        parameters[0] = abi.encode(i_depositor);
        parameters[1] = abi.encode(i_withdrawer);

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected account"));
        s_policy.run(address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes(""));
    }

    function test_YieldcoinShareFrozenAccountPolicy_run_RevertWhen_AccountIsFrozen() external {
        _changePrank(i_complianceOperator);
        s_yieldcoin.setAddressFrozen(i_depositor, true);

        bytes[] memory parameters = new bytes[](1);
        parameters[0] = abi.encode(i_depositor);

        vm.expectRevert(abi.encodeWithSelector(IPolicyEngine.PolicyRejected.selector, "account is frozen"));
        s_policy.run(address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes(""));
    }

    function test_YieldcoinShareFrozenAccountPolicy_run_Success_WhenAccountIsNotFrozen() external view {
        bytes[] memory parameters = new bytes[](1);
        parameters[0] = abi.encode(i_depositor);

        IPolicyEngine.PolicyResult result =
            s_policy.run(address(0), address(0), bytes4(keccak256("someSelector()")), parameters, bytes(""));

        assertEq(uint8(result), uint8(IPolicyEngine.PolicyResult.Continue));
    }
}
