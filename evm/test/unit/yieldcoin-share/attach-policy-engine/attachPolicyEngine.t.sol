// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {MockPolicyEngine} from "../../../mocks/MockPolicyEngine.sol";

contract YieldcoinShare_AttachPolicyEngineUnitTest is BaseUnitTest {
    MockPolicyEngine internal s_newMockPolicyEngine;

    function setUp() public {
        s_newMockPolicyEngine = new MockPolicyEngine();
    }

    function test_YieldcoinShare_TOKEN_001_attachPolicyEngine_RevertWhen_PolicyEngineIsZeroAddress() external {
        vm.expectRevert("Policy engine is zero address");
        s_yieldcoin.attachPolicyEngine(address(0));
    }

    function test_YieldcoinShare_TOKEN_001_attachPolicyEngine_Success_SetsPolicyEngine() external {
        s_yieldcoin.attachPolicyEngine(address(s_newMockPolicyEngine));

        assertEq(s_yieldcoin.getPolicyEngine(), address(s_newMockPolicyEngine));
    }

    function test_YieldcoinShare_TOKEN_001_attachPolicyEngine_Success_EmitsPolicyEngineAttached() external {
        vm.recordLogs();
        s_yieldcoin.attachPolicyEngine(address(s_newMockPolicyEngine));

        Vm.Log memory log = _assertEmittedBy(keccak256("PolicyEngineAttached(address)"), address(s_yieldcoin));
        assertEq(address(uint160(uint256(log.topics[1]))), address(s_newMockPolicyEngine));
    }
}
