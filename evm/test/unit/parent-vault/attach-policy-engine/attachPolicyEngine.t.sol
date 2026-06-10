// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {MockPolicyEngine} from "../../../mocks/MockPolicyEngine.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ParentVault_AttachPolicyEngineUnitTest is BaseUnitTest {
    MockPolicyEngine internal s_newMockPolicyEngine;

    function setUp() public {
        s_newMockPolicyEngine = new MockPolicyEngine();
        _changePrank(i_policyEngineManager);
    }

    function test_ParentVault_attachPolicyEngine_RevertWhen_CallerDoesNotHavePOLICY_ENGINE_MANAGER_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.POLICY_ENGINE_MANAGER_ROLE
            )
        );
        s_parentVault.attachPolicyEngine(address(s_newMockPolicyEngine));
    }

    function test_ParentVault_attachPolicyEngine_RevertWhen_PolicyEngineIsZeroAddress() external {
        vm.expectRevert("Policy engine is zero address");
        s_parentVault.attachPolicyEngine(address(0));
    }

    function test_ParentVault_attachPolicyEngine_Success() external {
        vm.recordLogs();
        s_parentVault.attachPolicyEngine(address(s_newMockPolicyEngine));

        Vm.Log memory log = _assertEmittedBy(keccak256("PolicyEngineAttached(address)"), address(s_parentVault));
        assertEq(address(uint160(uint256(log.topics[1]))), address(s_newMockPolicyEngine));
        assertEq(s_parentVault.getPolicyEngine(), address(s_newMockPolicyEngine));
    }
}
